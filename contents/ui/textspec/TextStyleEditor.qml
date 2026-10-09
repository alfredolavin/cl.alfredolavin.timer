import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "TextSpecCore.js" as TextSpecCore
import "../common"
import "../gradientpicker"
import "../controls"
import "../controls/IconMetrics.js" as IconMetrics

// The settings of a text style (TextSpecCore.js) in tabs: Font, Fill (text and background), Effects (outline, glow),
// Shadows and Align. Shared by RichTextEdit and TextStyleDialog. It shows `spec` and reports each change as
// changed(prop, value); the host stores it (live or on OK). Every setting has its own icon inside its control
// (shared controls/, unique within its tab); dependent settings are disabled, the color / gradient alternatives of a
// fill are swapped.
ColumnLayout {
    id: editor

    property var spec: TextSpecCore.defaultSpec()
    // show the Align tab (multi-line texts)
    property bool showAlign: true

    signal changed(string prop, var value)

    spacing: Kirigami.Units.smallSpacing

    // the text fill / background mode, picking a first gradient when there is none yet
    function setMode(modeProp, gradientProp, mode) {
        if (mode === "gradient" && !spec[gradientProp]) {
            const names = GradientStore.names();
            if (names && names.length)
                changed(gradientProp, names[0]);
        }
        changed(modeProp, mode);
    }

    component Tip: QQC2.ToolTip {
        delay: Kirigami.Units.toolTipDelay
    }

    // A form page in a tab: scrolls when the window is small
    component Page: QQC2.ScrollView {
        id: page
        default property alias content: form.data
        contentWidth: availableWidth
        clip: true
        Kirigami.FormLayout {
            id: form
            width: page.availableWidth
        }
    }

    // one of a row of mutually exclusive alignment buttons (each shows its own icon)
    component AlignButton: QQC2.ToolButton {
        property int align
        required property var current
        checkable: true
        checked: current === align
        display: QQC2.AbstractButton.TextBesideIcon
        QQC2.ToolTip.text: text
        QQC2.ToolTip.visible: hovered
        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    QQC2.TabBar {
        id: tabs
        Layout.fillWidth: true
        QQC2.TabButton { text: i18n("Font"); icon.name: "preferences-desktop-font" }
        QQC2.TabButton { text: i18n("Fill"); icon.name: "format-fill-color" }
        QQC2.TabButton { text: i18n("Effects"); icon.name: "preferences-desktop-effects" }
        QQC2.TabButton { text: i18n("Shadows"); icon.name: "object-order-lower" }
        QQC2.TabButton { text: i18n("Align"); icon.name: "format-justify-left"; visible: editor.showAlign; width: visible ? implicitWidth : 0 }
    }

    StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: tabs.currentIndex

        // ---- font ----
        Page {
            IconComboBox {
                Kirigami.FormData.label: i18n("Font family:")
                iconName: "dialog-text-and-font"
                Layout.fillWidth: true
                maximumTextWidth: Kirigami.Units.gridUnit * 14
                model: [i18n("System default")].concat(Qt.fontFamilies())
                currentIndex: {
                    const fam = editor.spec.fontFamily;
                    const idx = fam ? Qt.fontFamilies().indexOf(fam) : -1;
                    return idx >= 0 ? idx + 1 : 0;
                }
                onActivated: idx => editor.changed("fontFamily", idx === 0 ? "" : Qt.fontFamilies()[idx - 1])
            }
            IconSpinBox {
                Kirigami.FormData.label: i18n("Font size:")
                iconName: "format-font-size-more"
                from: 6
                to: 140
                value: editor.spec.pixelSize || 12
                suffix: i18nc("unit, after a number", " px")
                onValueModified: editor.changed("pixelSize", value)
            }
            IconComboBox {
                Kirigami.FormData.label: i18n("Font weight:")
                iconName: "format-text-bold"
                model: TextSpecCore.weights.map(w => i18n(w.name))
                currentIndex: Math.max(0, TextSpecCore.weights.findIndex(w => w.value === editor.spec.weight))
                onActivated: idx => editor.changed("weight", TextSpecCore.weights[idx].value)
            }
            IconCheckBox {
                Kirigami.FormData.label: i18n("Style:")
                iconName: "format-text-italic"
                text: i18n("Slant the letters (italic)")
                checked: !!editor.spec.italic
                onToggled: editor.changed("italic", checked)
            }
            IconSpinBox {
                Kirigami.FormData.label: i18n("Letter spacing:")
                iconName: "text_letter_spacing"
                from: -20
                to: 60
                value: Math.round(editor.spec.letterSpacing || 0)
                suffix: i18nc("unit, after a number", " px")
                onValueModified: editor.changed("letterSpacing", value)
                Tip { text: i18n("Extra space between letters; negative values bring them closer"); visible: parent.hovered }
            }
        }

        // ---- fill: text and background ----
        Page {
            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Text")
            }
            IconComboBox {
                Kirigami.FormData.label: i18n("Fill with:")
                iconName: "dialog-fill-and-stroke"
                model: [i18n("A solid color"), i18n("A gradient")]
                currentIndex: editor.spec.textMode === "gradient" ? 1 : 0
                onActivated: idx => editor.setMode("textMode", "textGradient", idx === 1 ? "gradient" : "color")
            }
            SourceColorButton {
                Kirigami.FormData.label: i18n("Text color:")
                visible: editor.spec.textMode !== "gradient"
                iconName: "format-text-color"
                value: editor.spec.textColor || "#ffffffff"
                dialogTitle: i18n("Text Color")
                onEdited: val => editor.changed("textColor", val)
            }
            GradientChooserButton {
                Kirigami.FormData.label: i18n("Text gradient:")
                visible: editor.spec.textMode === "gradient"
                leftPadding: IconMetrics.reserve
                selected: editor.spec.textGradient || ""
                onPicked: name => editor.changed("textGradient", name)
                PropertyIcon { name: "paint-gradient-linear" }
            }

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Background")
            }
            IconComboBox {
                id: bgMode
                Kirigami.FormData.label: i18n("Background:")
                iconName: "show-background"
                model: [i18n("None (transparent)"), i18n("A solid color"), i18n("A gradient")]
                currentIndex: Math.max(0, ["none", "color", "gradient"].indexOf(editor.spec.bgMode))
                onActivated: idx => editor.setMode("bgMode", "bgGradient", ["none", "color", "gradient"][idx])
            }
            // the gradient replaces the color; with no background both stay, disabled
            SourceColorButton {
                Kirigami.FormData.label: i18n("Background color:")
                visible: editor.spec.bgMode !== "gradient"
                enabled: editor.spec.bgMode === "color"
                iconName: "paint-solid"
                value: editor.spec.bgColor || "#40000000"
                dialogTitle: i18n("Background Color")
                onEdited: val => editor.changed("bgColor", val)
            }
            GradientChooserButton {
                Kirigami.FormData.label: i18n("Background gradient:")
                visible: editor.spec.bgMode === "gradient"
                leftPadding: IconMetrics.reserve
                selected: editor.spec.bgGradient || ""
                onPicked: name => editor.changed("bgGradient", name)
                PropertyIcon { name: "color-gradient" }
            }
            IconSpinBox {
                Kirigami.FormData.label: i18n("Corner radius:")
                iconName: "transform-affect-rounded-corners"
                enabled: editor.spec.bgMode !== "none"
                from: 0
                to: 50
                value: editor.spec.bgRadius || 0
                suffix: i18nc("unit, after a number", " px")
                onValueModified: editor.changed("bgRadius", value)
            }
            IconSpinBox {
                Kirigami.FormData.label: i18n("Padding:")
                iconName: "format-border-set-external"
                enabled: editor.spec.bgMode !== "none"
                from: 0
                to: 40
                value: editor.spec.bgPadding || 0
                suffix: i18nc("unit, after a number", " px")
                onValueModified: editor.changed("bgPadding", value)
                Tip { text: i18n("Space between the text and the edge of its background"); visible: parent.hovered }
            }
        }

        // ---- effects: outline, shadows, glow ----
        Page {
            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Outline")
            }
            IconCheckBox {
                id: outlineCheck
                iconName: "object-stroke"
                text: i18n("Draw an outline around the letters")
                checked: !!editor.spec.outlineEnabled
                onToggled: editor.changed("outlineEnabled", checked)
            }
            SourceColorButton {
                Kirigami.FormData.label: i18n("Outline color:")
                enabled: outlineCheck.checked
                iconName: "format-stroke-color"
                value: editor.spec.outlineColor || "#ff000000"
                dialogTitle: i18n("Outline Color")
                onEdited: val => editor.changed("outlineColor", val)
            }
            IconSpinBox {
                Kirigami.FormData.label: i18n("Outline width:")
                iconName: "object-stroke-style"
                enabled: outlineCheck.checked
                from: 1
                to: 20
                value: editor.spec.outlineWidth || 1
                suffix: i18nc("unit, after a number", " px")
                onValueModified: editor.changed("outlineWidth", value)
            }

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Glow")
            }
            IconCheckBox {
                id: glowCheck
                iconName: "powermask"
                text: i18n("Draw a glowing halo around the letters")
                checked: !!editor.spec.glowEnabled
                onToggled: editor.changed("glowEnabled", checked)
            }
            SourceColorButton {
                Kirigami.FormData.label: i18n("Glow color:")
                enabled: glowCheck.checked
                iconName: "draw-highlight"
                value: editor.spec.glowColor || "#ffffaa00"
                dialogTitle: i18n("Glow Color")
                onEdited: val => editor.changed("glowColor", val)
            }
            IconSpinBox {
                Kirigami.FormData.label: i18n("Glow strength:")
                iconName: "contrast"
                enabled: glowCheck.checked
                from: 1
                to: 10
                value: Math.round((editor.spec.glowStrength || 1.0) * 2)
                // half steps: 0.5× … 5×
                textFromValue: (v, locale) => i18nc("glow strength, a factor", "%1×", Number(v / 2).toLocaleString(locale, "f", 1))
                valueFromText: (t, locale) => Math.round(Number.fromLocaleString(locale, t.replace(/[^0-9.,-]/g, "")) * 2) || 2
                onValueModified: editor.changed("glowStrength", value / 2)
            }
            IconSpinBox {
                Kirigami.FormData.label: i18n("Glow radius:")
                iconName: "paint-gradient-radial"
                enabled: glowCheck.checked
                from: 1
                to: 40
                value: editor.spec.glowRadius || 6
                suffix: i18nc("unit, after a number", " px")
                onValueModified: editor.changed("glowRadius", value)
                Tip { text: i18n("How far the glow reaches beyond the letters"); visible: parent.hovered }
            }
        }

        // ---- shadows: a list, as wide as the tab ----
        QQC2.ScrollView {
            id: shadowPage
            contentWidth: availableWidth
            clip: true
            TextShadowListEditor {
                width: shadowPage.availableWidth
                shadows: editor.spec.shadows || []
                // the list replaces the old single shadow (shadowEnabled …), which would come back when it is emptied
                onEdited: arr => {
                    if (editor.spec.shadowEnabled)
                        editor.changed("shadowEnabled", false);
                    editor.changed("shadows", arr);
                }
            }
        }

        // ---- align ----
        Page {
            RowLayout {
                Kirigami.FormData.label: i18n("Horizontal:")
                // justified text fills the whole line, so the alignment does not apply
                enabled: !editor.spec.justified
                spacing: Kirigami.Units.smallSpacing
                Repeater {
                    model: [[Text.AlignLeft, "format-justify-left", i18n("Left")],
                            [Text.AlignHCenter, "format-justify-center", i18n("Center")],
                            [Text.AlignRight, "format-justify-right", i18n("Right")]]
                    AlignButton {
                        required property var modelData
                        current: editor.spec.horizontalAlignment || Text.AlignLeft
                        align: modelData[0]
                        icon.name: modelData[1]
                        text: modelData[2]
                        onClicked: editor.changed("horizontalAlignment", align)
                    }
                }
            }
            RowLayout {
                Kirigami.FormData.label: i18n("Vertical:")
                spacing: Kirigami.Units.smallSpacing
                Repeater {
                    model: [[Text.AlignTop, "align-vertical-top", i18n("Top")],
                            [Text.AlignVCenter, "align-vertical-center", i18n("Middle")],
                            [Text.AlignBottom, "align-vertical-bottom", i18n("Bottom")]]
                    AlignButton {
                        required property var modelData
                        current: editor.spec.verticalAlignment || Text.AlignVCenter
                        align: modelData[0]
                        icon.name: modelData[1]
                        text: modelData[2]
                        onClicked: editor.changed("verticalAlignment", align)
                    }
                }
            }
            IconCheckBox {
                Kirigami.FormData.label: i18n("Lines:")
                iconName: "format-justify-fill"
                text: i18n("Stretch every line to the full width (justify)")
                checked: !!editor.spec.justified
                onToggled: editor.changed("justified", checked)
            }
        }
    }
}
