import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami

import "TextSpecCore.js" as TextSpecCore
import "../controls"

// A comprehensive dialog / window encapsulating all text styling options:
// font family, font weight, pixel size, italic, glow, shadow, outline,
// background color or gradient, and inter-letter distance with live preview.
// The settings are TextStyleEditor's tabs (shared with RichTextEdit); changes apply on "Apply & Close".
Window {
    id: win

    property string initialValue: ""
    property var currentSpec: TextSpecCore.defaultSpec()
    property string sampleText: "Sample 123 ●"
    property string dialogTitle: i18n("Text Style Configuration")

    signal accepted(string value)
    signal rejected()

    title: dialogTitle
    width: 640
    height: 700
    minimumWidth: 520
    minimumHeight: 560
    flags: Qt.Dialog | Qt.WindowCloseButtonHint
    modality: Qt.WindowModal

    color: Kirigami.Theme.backgroundColor

    function load(val) {
        initialValue = val;
        currentSpec = TextSpecCore.parse(val);
    }

    function commit() {
        var jsonStr = TextSpecCore.stringify(currentSpec);
        accepted(jsonStr);
        win.close();
    }

    Shortcut { sequence: "Escape"; onActivated: { win.rejected(); win.close(); } }

    function setSpecProperty(prop, value) {
        var copy = JSON.parse(JSON.stringify(currentSpec));
        copy[prop] = value;
        currentSpec = copy;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        // Live Preview Section
        QQC2.Label {
            text: i18n("Live Preview")
            font.bold: true
        }

        TextStylePreview {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            spec: win.currentSpec
            sampleText: sampleInput.text
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            IconTextField {
                id: sampleInput
                iconName: "draw-text"
                Layout.fillWidth: true
                text: win.sampleText
                placeholderText: i18n("Text shown in the preview")
                QQC2.ToolTip.text: i18n("Text shown in the preview (not saved)")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
            QQC2.Button {
                text: i18n("Presets")
                icon.name: "bookmarks"
                onClicked: presetMenu.open()

                QQC2.Menu {
                    id: presetMenu
                    Repeater {
                        model: TextSpecCore.presets
                        QQC2.MenuItem {
                            required property var modelData
                            text: i18n(modelData.name)
                            onTriggered: {
                                win.currentSpec = TextSpecCore.normalize(modelData.spec);
                            }
                        }
                    }
                }
            }
        }

        // The settings, in tabs (the same editor as RichTextEdit's)
        TextStyleEditor {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spec: win.currentSpec
            onChanged: (prop, value) => win.setSpecProperty(prop, value)
        }

        // Action Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text: i18n("Reset to Default")
                icon.name: "edit-undo"
                onClicked: win.currentSpec = TextSpecCore.defaultSpec()
            }

            Item { Layout.fillWidth: true }

            QQC2.Button {
                text: i18n("Cancel")
                icon.name: "dialog-cancel"
                onClicked: { win.rejected(); win.close(); }
            }

            QQC2.Button {
                text: i18n("Apply & Close")
                icon.name: "dialog-ok"
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
                onClicked: win.commit()
            }
        }
    }
}
