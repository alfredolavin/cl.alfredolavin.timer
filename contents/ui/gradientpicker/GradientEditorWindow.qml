import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami

import "code/gradients.js" as Gradients

// Window to edit one saved gradient. Works on a copy; OK saves it into the store, Escape / Cancel discards.
Window {
    id: win

    // name of the gradient being edited ("" = a new one made from `template`)
    property string gradientName: ""
    property var template: null
    property string title2: i18n("Edit gradient")

    signal saved(string name)

    title: title2
    flags: Qt.Dialog
    modality: Qt.WindowModal
    color: Kirigami.Theme.backgroundColor
    visible: false
    width: Math.min(Kirigami.Units.gridUnit * 34, Screen.desktopAvailableWidth * 0.9)
    height: Math.min(Kirigami.Units.gridUnit * 42, Screen.desktopAvailableHeight * 0.9)
    minimumWidth: Kirigami.Units.gridUnit * 28
    minimumHeight: Kirigami.Units.gridUnit * 20

    // new gradients are in oklch, like the rest of the plasmoids' colors
    function newDef() {
        return { name: i18n("New gradient"), space: "oklch", hue: "shorter",
                 stops: [{ pos: 0, color: "oklch(80% 0.15 230)", mid: 0.5 }, { pos: 1, color: "oklch(45% 0.2 300)", mid: 0.5 }] };
    }

    function open(name) {
        gradientName = name || "";
        const d = name ? GradientStore.def(name) : (template ? JSON.parse(JSON.stringify(template)) : newDef());
        editor.def = d;
        title2 = name ? i18n("Edit gradient “%1”", name) : i18n("New gradient");
        visible = true;
        raise();
        requestActivate();
    }

    Shortcut { sequence: "Escape"; onActivated: win.close() }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            clip: true
            GradientEditor {
                id: editor
                width: parent.width
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            QQC2.Button {
                text: i18n("Cancel")
                icon.name: "dialog-cancel"
                onClicked: win.close()
            }
            QQC2.Button {
                text: i18n("OK")
                icon.name: "dialog-ok"
                onClicked: {
                    const d = JSON.parse(JSON.stringify(editor.def));
                    const name = win.gradientName ? GradientStore.update(win.gradientName, d) : GradientStore.insert(d, "");
                    win.saved(name);
                    win.close();
                }
            }
        }
    }
}
