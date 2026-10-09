import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

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

    // ── Auto-Apply Engine ───────────────────────────────────────────────────
    // Automatically applies all cfg_* property changes immediately to the widget
    // and saves them to disk so the user never has to click "Apply".
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

    function findConfigPage() {
        let p = footerRoot.parent;
        let target = null;
        while (p) {
            for (let k in p) {
                if (k.startsWith("cfg_") && !k.endsWith("Changed")) {
                    target = p;
                    break;
                }
            }
            if (target) break;
            if (!p.parent) break;
            p = p.parent;
        }
        return target || footerRoot.parent;
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
                    if ("wasConfigurationChangedSignalSent" in p) {
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
        let page = findConfigPage();
        if (!page) return;
        watchedPage = page;

        let cfg = getConfiguration();
        let keysMap = {};

        for (let k in page) {
            if (k.startsWith("cfg_") && !k.endsWith("Changed")) {
                keysMap[k.substring(4)] = true;
            }
        }

        if (cfg && typeof cfg.keys === "function") {
            try {
                let allKeys = cfg.keys();
                for (let i = 0; i < allKeys.length; i++) {
                    let k = allKeys[i];
                    if (("cfg_" + k) in page) {
                        keysMap[k] = true;
                    }
                }
            } catch (e) {}
        }

        let keys = Object.keys(keysMap);
        for (let i = 0; i < keys.length; i++) {
            let key = keys[i];
            let sigName = "cfg_" + key + "Changed";
            let propName = "cfg_" + key;
            if (typeof page[sigName] === "function" && typeof page[sigName].connect === "function") {
                (function(k, pName) {
                    page[sigName].connect(function() {
                        if (!autoApplyReady) return;
                        applyChange(k, page[pName]);
                    });
                })(key, propName);
            }
        }

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
