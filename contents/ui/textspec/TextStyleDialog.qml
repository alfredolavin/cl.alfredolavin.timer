import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami

import "TextSpecCore.js" as TextSpecCore
import "../colorspec"
import "../gradientpicker"

// A comprehensive dialog / window encapsulating all text styling options:
// font family, font weight, pixel size, italic, glow, shadow, outline,
// background color or gradient, and inter-letter distance with live preview.
// Reuses the shared ColorSpecButton and GradientChooserButton controls.
Window {
    id: win

    property string initialValue: ""
    property var currentSpec: TextSpecCore.defaultSpec()
    property string sampleText: "Sample 123 ●"
    property string dialogTitle: i18n("Text Style Configuration")

    signal accepted(string value)
    signal rejected()

    title: dialogTitle
    width: 620
    height: 680
    minimumWidth: 520
    minimumHeight: 560
    flags: Qt.Dialog | Qt.WindowCloseButtonHint

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

            QQC2.Label { text: i18n("Preview text:") }
            QQC2.TextField {
                id: sampleInput
                Layout.fillWidth: true
                text: win.sampleText
            }
            QQC2.Button {
                text: i18n("Presets")
                icon.name: "favorite"
                onClicked: presetMenu.open()

                QQC2.Menu {
                    id: presetMenu
                    Repeater {
                        model: TextSpecCore.presets
                        QQC2.MenuItem {
                            required property var modelData
                            text: modelData.name
                            onTriggered: {
                                win.currentSpec = TextSpecCore.normalize(modelData.spec);
                            }
                        }
                    }
                }
            }
        }

        // Tabs for settings
        QQC2.TabBar {
            id: tabBar
            Layout.fillWidth: true
            QQC2.TabButton { text: i18n("Font") }
            QQC2.TabButton { text: i18n("Colors & BG") }
            QQC2.TabButton { text: i18n("Outline & Glow") }
            QQC2.TabButton { text: i18n("Shadow") }
        }

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: -1
            clip: true

            StackLayout {
                id: stackLayout
                currentIndex: tabBar.currentIndex
                width: parent.width

                // 1. FONT TAB
                Kirigami.FormLayout {
                    Layout.fillWidth: true

                    QQC2.ComboBox {
                        id: fontCombo
                        Kirigami.FormData.label: i18n("Font family:")
                        Layout.fillWidth: true
                        model: ["(System Default)"].concat(Qt.fontFamilies())
                        currentIndex: {
                            var fam = win.currentSpec.fontFamily;
                            if (!fam) return 0;
                            var idx = model.indexOf(fam);
                            return idx >= 0 ? idx : 0;
                        }
                        onActivated: index => {
                            win.setSpecProperty("fontFamily", index === 0 ? "" : model[index]);
                        }
                    }

                    QQC2.ComboBox {
                        Kirigami.FormData.label: i18n("Font weight:")
                        Layout.fillWidth: true
                        model: TextSpecCore.weights.map(w => w.name)
                        currentIndex: {
                            var w = win.currentSpec.weight;
                            for (var i = 0; i < TextSpecCore.weights.length; ++i) {
                                if (TextSpecCore.weights[i].value === w) return i;
                            }
                            return 3; // Normal 400
                        }
                        onActivated: index => {
                            win.setSpecProperty("weight", TextSpecCore.weights[index].value);
                        }
                    }

                    QQC2.SpinBox {
                        Kirigami.FormData.label: i18n("Font size:")
                        from: 6
                        to: 120
                        value: win.currentSpec.pixelSize
                        onValueModified: win.setSpecProperty("pixelSize", value)
                    }

                    QQC2.CheckBox {
                        Kirigami.FormData.label: i18n("Style:")
                        text: i18n("Italic")
                        checked: win.currentSpec.italic
                        onToggled: win.setSpecProperty("italic", checked)
                    }

                    QQC2.SpinBox {
                        Kirigami.FormData.label: i18n("Inter-letter spacing:")
                        from: -20
                        to: 60
                        value: Math.round(win.currentSpec.letterSpacing)
                        onValueModified: win.setSpecProperty("letterSpacing", value)
                        textFromValue: v => v + " px"
                        valueFromText: t => parseInt(t) || 0
                    }
                }

                // 2. COLORS & BACKGROUND TAB
                Kirigami.FormLayout {
                    Layout.fillWidth: true

                    ColorSpecButton {
                        Kirigami.FormData.label: i18n("Text color:")
                        value: win.currentSpec.textColor
                        dialogTitle: i18n("Choose Text Color")
                        onEdited: val => win.setSpecProperty("textColor", val)
                    }

                    QQC2.ComboBox {
                        Kirigami.FormData.label: i18n("Background mode:")
                        Layout.fillWidth: true
                        model: [i18n("None (Transparent)"), i18n("Solid Color"), i18n("Gradient")]
                        currentIndex: win.currentSpec.bgMode === "color" ? 1 : (win.currentSpec.bgMode === "gradient" ? 2 : 0)
                        onActivated: index => {
                            var modes = ["none", "color", "gradient"];
                            win.setSpecProperty("bgMode", modes[index]);
                        }
                    }

                    ColorSpecButton {
                        visible: win.currentSpec.bgMode === "color"
                        Kirigami.FormData.label: i18n("Background color:")
                        value: win.currentSpec.bgColor
                        dialogTitle: i18n("Choose Background Color")
                        onEdited: val => win.setSpecProperty("bgColor", val)
                    }

                    GradientChooserButton {
                        visible: win.currentSpec.bgMode === "gradient"
                        Kirigami.FormData.label: i18n("Background gradient:")
                        selected: win.currentSpec.bgGradient
                        onPicked: name => win.setSpecProperty("bgGradient", name)
                    }

                    QQC2.SpinBox {
                        visible: win.currentSpec.bgMode !== "none"
                        Kirigami.FormData.label: i18n("Background radius:")
                        from: 0
                        to: 50
                        value: win.currentSpec.bgRadius
                        onValueModified: win.setSpecProperty("bgRadius", value)
                    }

                    QQC2.SpinBox {
                        visible: win.currentSpec.bgMode !== "none"
                        Kirigami.FormData.label: i18n("Background padding:")
                        from: 0
                        to: 40
                        value: win.currentSpec.bgPadding
                        onValueModified: win.setSpecProperty("bgPadding", value)
                    }
                }

                // 3. OUTLINE & GLOW TAB
                Kirigami.FormLayout {
                    Layout.fillWidth: true

                    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Outline") }

                    QQC2.CheckBox {
                        id: outlineCheck
                        text: i18n("Enable text outline")
                        checked: win.currentSpec.outlineEnabled
                        onToggled: win.setSpecProperty("outlineEnabled", checked)
                    }

                    QQC2.SpinBox {
                        Kirigami.FormData.label: i18n("Outline width:")
                        enabled: outlineCheck.checked
                        from: 1
                        to: 10
                        value: win.currentSpec.outlineWidth
                        onValueModified: win.setSpecProperty("outlineWidth", value)
                    }

                    ColorSpecButton {
                        enabled: outlineCheck.checked
                        Kirigami.FormData.label: i18n("Outline color:")
                        value: win.currentSpec.outlineColor
                        dialogTitle: i18n("Choose Outline Color")
                        onEdited: val => win.setSpecProperty("outlineColor", val)
                    }

                    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Glow") }

                    QQC2.CheckBox {
                        id: glowCheck
                        text: i18n("Enable halo glow")
                        checked: win.currentSpec.glowEnabled
                        onToggled: win.setSpecProperty("glowEnabled", checked)
                    }

                    ColorSpecButton {
                        enabled: glowCheck.checked
                        Kirigami.FormData.label: i18n("Glow color:")
                        value: win.currentSpec.glowColor
                        dialogTitle: i18n("Choose Glow Color")
                        onEdited: val => win.setSpecProperty("glowColor", val)
                    }

                    QQC2.SpinBox {
                        Kirigami.FormData.label: i18n("Glow radius:")
                        enabled: glowCheck.checked
                        from: 1
                        to: 40
                        value: win.currentSpec.glowRadius
                        onValueModified: win.setSpecProperty("glowRadius", value)
                    }
                }

                // 4. SHADOW TAB
                Kirigami.FormLayout {
                    Layout.fillWidth: true

                    QQC2.CheckBox {
                        id: shadowCheck
                        text: i18n("Enable drop shadow")
                        checked: win.currentSpec.shadowEnabled
                        onToggled: win.setSpecProperty("shadowEnabled", checked)
                    }

                    ColorSpecButton {
                        enabled: shadowCheck.checked
                        Kirigami.FormData.label: i18n("Shadow color:")
                        value: win.currentSpec.shadowColor
                        dialogTitle: i18n("Choose Shadow Color")
                        onEdited: val => win.setSpecProperty("shadowColor", val)
                    }

                    QQC2.SpinBox {
                        Kirigami.FormData.label: i18n("Shadow blur:")
                        enabled: shadowCheck.checked
                        from: 0
                        to: 60
                        value: win.currentSpec.shadowBlur
                        onValueModified: win.setSpecProperty("shadowBlur", value)
                    }

                    QQC2.SpinBox {
                        Kirigami.FormData.label: i18n("Horizontal offset (X):")
                        enabled: shadowCheck.checked
                        from: -30
                        to: 30
                        value: Math.round(win.currentSpec.shadowX)
                        onValueModified: win.setSpecProperty("shadowX", value)
                    }

                    QQC2.SpinBox {
                        Kirigami.FormData.label: i18n("Vertical offset (Y):")
                        enabled: shadowCheck.checked
                        from: -30
                        to: 30
                        value: Math.round(win.currentSpec.shadowY)
                        onValueModified: win.setSpecProperty("shadowY", value)
                    }
                }
            }
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
