import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

import "code/util.js" as Util
import "code/gradients.js" as Gradients

PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration

    // Timer definitions and gradients from the configuration
    readonly property var timers: Util.loadTimers(cfg.timers)
    readonly property var gradients: Gradients.parse(cfg.gradientsCss || Gradients.defaultCss)

    // Running timers: {uid, id, name, icon, duration, sound, repeat, gradient, end, remaining, paused, finished}
    property var running: Util.loadRunning(cfg.runningState)
    // uids sorted by remaining time; only reassigned when the order really changes
    property var order: []
    property double now: Date.now()
    property bool blink: false

    readonly property string currentUid: order.length ? order[0] : ""
    readonly property var others: order.slice(1)
    readonly property var available: timers.filter(t => !running.some(r => r.id === t.id))
    readonly property bool anyFinished: running.some(r => r.finished)
    readonly property bool alarmPlaying: alarm.playing

    preferredRepresentation: compactRepresentation
    // Keeps the panel from auto-hiding while a timer is finished. NeedsAttention is not enough:
    // the system tray often holds the panel at that level already, so nothing would change.
    Plasmoid.status: anyFinished ? PlasmaCore.Types.RequiresAttentionStatus : PlasmaCore.Types.ActiveStatus

    // The panel window hosting the widget (a PanelView), null on the desktop
    property QtObject panelView: null
    readonly property bool inPanel: !!panelView && panelView.visibilityMode !== undefined
    compactRepresentation: CompactRepresentation { app: root }
    fullRepresentation: FullRepresentation { app: root }
    switchWidth: Kirigami.Units.gridUnit * 10
    switchHeight: Kirigami.Units.gridUnit * 6

    toolTipMainText: entry(currentUid)?.name ?? i18n("Nerd Timer")
    toolTipSubText: currentUid ? Util.formatTime(remainingOf(entry(currentUid)))
                                 + (others.length ? "  ·  " + i18np("%1 more running", "%1 more running", others.length) : "")
                               : i18n("No timers running")

    function entry(uid) {
        for (let i = 0; i < running.length; ++i)
            if (running[i].uid === uid)
                return running[i];
        return null;
    }

    function remainingOf(r) {
        if (!r || r.finished)
            return 0;
        return r.paused ? r.remaining : Math.max(0, r.end - now);
    }

    function progressOf(r) {
        if (!r)
            return 0;
        return r.duration > 0 ? 1 - remainingOf(r) / (r.duration * 1000) : 1;
    }

    function gradientFor(name) {
        return Gradients.find(gradients, name);
    }

    function reorder() {
        const sorted = running.slice().sort((a, b) => remainingOf(a) - remainingOf(b) || a.uid.localeCompare(b.uid)).map(r => r.uid);
        if (sorted.join() !== order.join())
            order = sorted;
    }

    // Apply fn to a deep-enough copy of the running list, then store it
    function mutate(fn) {
        const copy = running.map(r => Object.assign({}, r));
        fn(copy);
        running = copy;
        Plasmoid.configuration.runningState = JSON.stringify(copy);
        reorder();
    }

    function start(timerId) {
        const t = timers.find(x => x.id === timerId);
        if (!t)
            return;
        now = Date.now();
        mutate(list => list.push(Object.assign({}, t, {
            uid: Util.newId(),
            end: now + t.duration * 1000,
            remaining: t.duration * 1000,
            paused: false,
            finished: false
        })));
    }

    function togglePause(uid) {
        now = Date.now();
        mutate(list => {
            const r = list.find(x => x.uid === uid);
            if (!r)
                return;
            if (r.finished) {            // finished: play button restarts it
                r.finished = false;
                r.paused = false;
                r.end = now + r.duration * 1000;
            } else if (r.paused) {
                r.paused = false;
                r.end = now + r.remaining;
            } else {
                r.paused = true;
                r.remaining = Math.max(0, r.end - now);
            }
        });
        if (!anyFinished)
            alarm.stop();
    }

    function remove(uid) {
        mutate(list => {
            const i = list.findIndex(x => x.uid === uid);
            if (i >= 0)
                list.splice(i, 1);
        });
        if (!anyFinished)
            alarm.stop();
    }

    function finishedUids() {
        return running.filter(r => r.finished).map(r => r.uid);
    }

    // Stop the alarm sound
    function silence() {
        if (alarm.playing)
            alarm.stop();
    }

    // Silence, and remove the given (finished at click time) timers from the running list
    function dismiss(uids) {
        silence();
        if (!running.some(r => uids.indexOf(r.uid) >= 0))
            return;
        mutate(list => {
            for (let i = list.length - 1; i >= 0; --i)
                if (uids.indexOf(list[i].uid) >= 0)
                    list.splice(i, 1);
        });
    }

    // While a timer is finished an auto-hiding (1) or dodging (2) panel is switched to
    // "windows go below" (3): always shown, above windows. The original mode is kept in the
    // configuration, so it is restored even if plasmashell restarts in between.
    function updatePanelReveal() {
        if (!inPanel || !panelView)
            return;
        const saved = cfg.savedPanelVisibility;
        if (anyFinished) {
            const mode = panelView.visibilityMode;
            if (saved < 0 && (mode === 1 || mode === 2)) {
                Plasmoid.configuration.savedPanelVisibility = mode;
                panelView.visibilityMode = 3;
            }
        } else if (saved >= 0) {
            panelView.visibilityMode = saved;
            Plasmoid.configuration.savedPanelVisibility = -1;
        }
    }

    onAnyFinishedChanged: updatePanelReveal()
    onPanelViewChanged: updatePanelReveal()

    Item {
        onWindowChanged: window => root.panelView = window
    }

    function checkFinished() {
        const done = running.filter(r => !r.paused && !r.finished && r.end <= now);
        if (!done.length)
            return;
        mutate(list => list.forEach(r => {
            if (done.some(d => d.uid === r.uid))
                r.finished = true;
        }));
        const last = done[done.length - 1];
        alarm.play(last.sound, last.repeat);
    }

    // The popup lists running timers and the ones that can be started, side by side
    function togglePopup() {
        expanded = !expanded;
    }

    AlarmPlayer {
        id: alarm
    }

    Timer {
        interval: 250
        repeat: true
        running: root.running.some(r => !r.paused && !r.finished)
        triggeredOnStart: true
        onTriggered: {
            root.now = Date.now();
            root.checkFinished();
            root.reorder();
        }
    }

    Timer {
        interval: 500
        repeat: true
        running: root.anyFinished
        onTriggered: root.blink = !root.blink
        onRunningChanged: if (!running) root.blink = false
    }

    Component.onCompleted: {
        now = Date.now();
        // Timers that expired while plasmashell was not running finish silently
        if (running.some(r => !r.paused && !r.finished && r.end <= now))
            mutate(list => list.forEach(r => {
                if (!r.paused && !r.finished && r.end <= now)
                    r.finished = true;
            }));
        reorder();
    }
}
