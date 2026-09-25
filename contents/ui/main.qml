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
    readonly property string iconFont: cfg.iconFont || Util.pickNerdFont(Qt.fontFamilies())

    // Running timers: {uid, id, name, icon, duration, sound, repeat, gradient, end, remaining, paused, finished}
    property var running: Util.loadRunning(cfg.runningState)
    // uids sorted by remaining time; only reassigned when the order really changes
    property var order: []
    property double now: Date.now()
    property bool blink: false
    // "running" = other running timers, "add" = timers that can be started
    property string popupMode: "running"

    readonly property string currentUid: order.length ? order[0] : ""
    readonly property var others: order.slice(1)
    readonly property var available: timers.filter(t => !running.some(r => r.id === t.id))
    readonly property bool anyFinished: running.some(r => r.finished)
    readonly property bool alarmPlaying: alarm.playing

    preferredRepresentation: compactRepresentation
    compactRepresentation: CompactRepresentation { app: root }
    fullRepresentation: FullRepresentation { app: root }
    switchWidth: Kirigami.Units.gridUnit * 10
    switchHeight: Kirigami.Units.gridUnit * 6

    toolTipMainText: currentUid ? entry(currentUid).name : i18n("Nerd Timer")
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
        if (others.length === 0 && popupMode === "running")
            expanded = false;
    }

    // Stop the alarm sound; finished timers keep blinking until dismissed or restarted
    function silence() {
        if (alarm.playing)
            alarm.stop();
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

    function openPopup(mode) {
        if (expanded && popupMode === mode) {
            expanded = false;
            return;
        }
        popupMode = mode;
        expanded = true;
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
