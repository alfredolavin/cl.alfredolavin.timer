import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "code/gradients.js" as Gradients

KCM.SimpleKCM {
    id: page

    property string cfg_gradientsCss
    readonly property var parsed: Gradients.parse(editor.text)

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("Paste CSS gradients here. Every linear-gradient() (or radial/conic) becomes a choice in the Timers page. The name comes from a preceding /* comment */, a .class-name { or a “Name:” label.")
        }

        QQC2.TextArea {
            id: editor
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 14
            font.family: "monospace"
            wrapMode: TextEdit.NoWrap
            text: page.cfg_gradientsCss || Gradients.defaultCss
            onTextChanged: page.cfg_gradientsCss = text
        }

        RowLayout {
            QQC2.Button {
                icon.name: "edit-reset"
                text: i18n("Restore built-in gradients")
                onClicked: editor.text = Gradients.defaultCss
            }
            QQC2.Button {
                icon.name: "list-add"
                text: i18n("Append built-in gradients")
                onClicked: editor.text = editor.text.replace(/\s*$/, "") + "\n" + Gradients.defaultCss
            }
            Item { Layout.fillWidth: true }
            QQC2.Label { text: i18np("%1 gradient found", "%1 gradients found", page.parsed.length) }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Kirigami.Units.largeSpacing
            Repeater {
                model: page.parsed
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    QQC2.Label {
                        text: modelData.name
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        elide: Text.ElideRight
                    }
                    GradientBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit
                        stops: modelData.stops
                        progress: 1
                        radius: 4
                    }
                }
            }
        }
    }
}
