import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// The footer of every settings page (`footer: ConfigFooter {}` of a KCM.SimpleKCM): the author's address, and an
// auto-apply engine that makes every change take effect at once, so the user never has to press Apply.
//
// How it applies: once the page is built (Qt.callLater, after Plasma's AppletConfiguration has connected its own
// cfg_<key>Changed handlers) it finds the page (the nearest parent with cfg_ properties) and connects to the change
// signal of each cfg_<key> that is a key of plasmoid.configuration (so Plasma's cfg_<key>Default properties are
// left alone). A change is copied to the configuration at once (the widget updates live) and written to disk after
// 150 ms of quiet (and when the page closes). Then Plasma's settingValueChanged() runs again, which now finds no
// difference and disables Apply. Pages with their own saveConfig() keep Apply enabled for what only that applies.
// Outside Plasma (no configuration, e.g. tools/qml_shot.py) it does nothing. All lookups are guarded, so it is quiet.
Item {
    id: footerRoot
    implicitHeight: footerLabel.implicitHeight + Kirigami.Units.smallSpacing * 2
    Layout.fillWidth: true

    QQC2.Label {
        id: footerLabel
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Kirigami.Units.largeSpacing
        anchors.bottomMargin: Kirigami.Units.smallSpacing
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        text: '<a href="mailto:alfredolavin@gmail.com" style="color: ' + Kirigami.Theme.linkColor + '; text-decoration: none;">alfredolavin@gmail.com</a>'
        textFormat: Text.RichText
        onLinkActivated: link => Qt.openUrlExternally(link)
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }

    // ── Auto-apply engine (see the top of the file) ─────────────────────────
    property bool autoApplyReady: false
    property var watchedPage: null

    Timer {
        id: debounceSaveTimer
        interval: 150
        repeat: false
        onTriggered: footerRoot.flushWriteConfig()
    }

    function getConfiguration() {
        try {
            if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration) {
                return plasmoid.configuration;
            }
        } catch (e) {}
        try {
            if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration) {
                return Plasmoid.configuration;
            }
        } catch (e) {}
        let p = footerRoot.parent;
        while (p) {
            try {
                if (p.plasmoid && p.plasmoid.configuration) return p.plasmoid.configuration;
                if (p.Plasmoid && p.Plasmoid.configuration) return p.Plasmoid.configuration;
            } catch (e) {}
            p = p.parent;
        }
        return null;
    }

    // the page: the nearest parent with a cfg_ property of one of the configuration's keys
    function findConfigPage(keys) {
        for (let p = footerRoot.parent; p; p = p.parent)
            if (keys.some(k => ("cfg_" + k) in p))
                return p;
        return null;
    }

    function resetUnsavedState() {
        if (watchedPage) {
            try {
                if ("needsSave" in watchedPage) watchedPage.needsSave = false;
                if ("unsavedChanges" in watchedPage) watchedPage.unsavedChanges = false;
            } catch (e) {}
        }
        let p = footerRoot.parent;
        while (p) {
            try {
                if (typeof p.settingValueChanged === "function") {
                    // a page's own saveConfig() may still have something to apply
                    const ownSave = watchedPage && typeof watchedPage.saveConfig === "function";
                    if (!ownSave && "wasConfigurationChangedSignalSent" in p) {
                        p.wasConfigurationChangedSignalSent = false;
                    }
                    p.settingValueChanged();
                    break;
                }
                if (p.applyButton) {
                    p.applyButton.enabled = false;
                }
            } catch (e) {}
            p = p.parent;
        }
    }

    function flushWriteConfig() {
        debounceSaveTimer.stop();
        let cfg = getConfiguration();
        if (cfg && typeof cfg.writeConfig === "function") {
            try {
                cfg.writeConfig();
            } catch (e) {}
        }
        resetUnsavedState();
    }

    function applyChange(key, val) {
        if (val === undefined) return;
        let cfg = getConfiguration();
        if (cfg) {
            try {
                if (cfg[key] !== val && String(cfg[key]) !== String(val)) {
                    cfg[key] = val;
                    debounceSaveTimer.restart();
                }
            } catch (e) {
                try {
                    cfg[key] = val;
                    debounceSaveTimer.restart();
                } catch (e2) {}
            }
        }
        resetUnsavedState();
    }

    function initAutoApply() {
        const cfg = getConfiguration();
        if (!cfg)
            return;
        let keys = [];
        if (cfg && typeof cfg.keys === "function") {
            try {
                keys = cfg.keys();
            } catch (e) {}
        }
        const page = findConfigPage(keys);
        if (!page)
            return;
        watchedPage = page;

        keys.forEach(key => {
            const signal = page["cfg_" + key + "Changed"];
            if (signal && typeof signal.connect === "function")
                signal.connect(() => {
                    if (autoApplyReady)
                        applyChange(key, page["cfg_" + key]);
                });
        });
        autoApplyReady = true;
    }

    Component.onCompleted: {
        Qt.callLater(initAutoApply);
    }

    Component.onDestruction: {
        if (debounceSaveTimer.running) {
            flushWriteConfig();
        }
    }
}
