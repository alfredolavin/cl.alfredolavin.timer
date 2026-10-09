import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "controls"
import "gradientpicker"
import "code/colorspec.js" as ColorSpec

// The widget in the panel: layout, frame, icon, bar and buttons. Every control holds the icon of its setting.
KCM.SimpleKCM {
    id: page

    property string cfg_runningState
    readonly property var gradients: GradientStore.gradients

    // Frame background and outline; while empty they are derived from the older settings below
    property string cfg_frameBackgroundColor
    property string cfg_frameOutlineColor
    // older frame settings, only read for that (see legacyFrame in code/colorspec.js)
    property string cfg_borderColor
    property int cfg_backgroundTransparency
    property bool cfg_linkColors
    property int cfg_linkedBgOpacity
    property int cfg_linkedBgLuminosity
    property int cfg_linkedBgChroma
    property int cfg_linkedOutlineOpacity
    property int cfg_linkedOutlineLuminosity
    property int cfg_linkedOutlineChroma
    readonly property var legacy: ({
        borderColor: cfg_borderColor, backgroundTransparency: cfg_backgroundTransparency, linkColors: cfg_linkColors,
        linkedBgOpacity: cfg_linkedBgOpacity, linkedBgLuminosity: cfg_linkedBgLuminosity, linkedBgChroma: cfg_linkedBgChroma,
        linkedOutlineOpacity: cfg_linkedOutlineOpacity, linkedOutlineLuminosity: cfg_linkedOutlineLuminosity,
        linkedOutlineChroma: cfg_linkedOutlineChroma
    })

    property string cfg_panelLayout
    property alias cfg_revealOnHover: revealOnHover.checked
    property alias cfg_cornerRadius: cornerRadius.value
    property alias cfg_borderWidth: borderWidth.value
    property alias cfg_padding: padding.value
    property alias cfg_spacing: spacing.value
    property alias cfg_iconSize: iconSize.value
    property alias cfg_useThemeIconColor: autoIconColor.checked
    property alias cfg_iconColor: iconColor.value
    property alias cfg_barWidth: barWidth.value
    property alias cfg_barFillWidth: barFillWidth.checked
    property alias cfg_barHeightPercent: barHeight.value
    property alias cfg_barRadius: barRadius.value
    property alias cfg_textShadow: textShadow.checked
    property alias cfg_buttonIconSize: buttonIconSize.value
    property alias cfg_buttonBorderWidth: buttonBorderWidth.value
    property alias cfg_buttonRadius: buttonRadius.value
    property alias cfg_finishedTextColor: finishedTextColor.value

    Kirigami.FormLayout {
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Panel") }

        IconComboBox {
            readonly property var layouts: ["frame", "bar"]
            Kirigami.FormData.label: i18n("Layout:")
            iconName: "object-columns"
            model: [i18n("Frame holding the icon, bar and buttons"), i18n("The bar is the widget, holding the icon and buttons")]
            currentIndex: Math.max(0, layouts.indexOf(page.cfg_panelLayout))
            onActivated: index => page.cfg_panelLayout = layouts[index]
        }
        IconCheckBox {
            id: revealOnHover
            Kirigami.FormData.label: i18n("Mouse over:")
            iconName: "input-mouse"
            text: i18n("Show only the bar and icon until the mouse is over it")
            QQC2.ToolTip.text: i18n("The bar fills the whole widget with the icon inside it; the buttons (and the frame) appear on mouse over, while the popup is open or when a timer ends")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Frame") }

        IconSpinBox {
            id: cornerRadius
            Kirigami.FormData.label: i18n("Corner radius:")
            iconName: "transform-affect-rounded-corners"
            from: 0
            to: 30
            suffix: i18nc("unit, after a number", " px")
        }
        ColorSpecButton {
            id: frameBackground
            Kirigami.FormData.label: i18n("Background:")
            iconName: "color-fill"
            dialogTitle: i18n("Widget background color")
            gradients: page.gradients
            runningState: page.cfg_runningState
            value: ColorSpec.frameSpec("background", page.cfg_frameBackgroundColor, page.legacy)
            onEdited: v => page.cfg_frameBackgroundColor = v
        }
        ColorSpecButton {
            id: frameOutline
            Kirigami.FormData.label: i18n("Outline:")
            iconName: "format-stroke-color"
            dialogTitle: i18n("Widget outline color (frame and buttons)")
            gradients: page.gradients
            runningState: page.cfg_runningState
            value: ColorSpec.frameSpec("outline", page.cfg_frameOutlineColor, page.legacy)
            onEdited: v => page.cfg_frameOutlineColor = v
            QQC2.ToolTip.text: i18n("Also the border of the buttons. Click to change")
        }
        IconSpinBox {
            id: borderWidth
            Kirigami.FormData.label: i18n("Outline width:")
            iconName: "edit-line-width"
            from: 0
            to: 10
            suffix: i18nc("unit, after a number", " px")
        }
        IconSpinBox {
            id: padding
            Kirigami.FormData.label: i18n("Inner padding:")
            iconName: "trim-margins"
            from: 0
            to: 20
            suffix: i18nc("unit, after a number", " px")
            QQC2.ToolTip.text: i18n("Space between the frame and what it holds")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
        IconSpinBox {
            id: spacing
            Kirigami.FormData.label: i18n("Spacing:")
            iconName: "distribute-horizontal-gaps"
            from: 0
            to: 20
            suffix: i18nc("unit, after a number", " px")
            QQC2.ToolTip.text: i18n("Space between the icon, the bar and the buttons")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Icon") }

        IconSpinBox {
            id: iconSize
            Kirigami.FormData.label: i18n("Icon size:")
            iconName: "zoom-in"
            from: 8
            to: 128
            suffix: i18nc("unit, after a number", " px")
        }
        IconCheckBox {
            id: autoIconColor
            Kirigami.FormData.label: i18n("Icon color:")
            iconName: "contrast"
            text: i18n("Pick black or white, whichever contrasts best")
        }
        ColorSpecButton {
            id: iconColor
            Kirigami.FormData.label: i18n("Fixed icon color:")
            iconName: "color-picker"
            enabled: !autoIconColor.checked
            dialogTitle: i18n("Icon color")
            gradients: page.gradients
            runningState: page.cfg_runningState
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Progress bar") }

        RowLayout {
            Kirigami.FormData.label: i18n("Bar width:")
            IconSpinBox {
                id: barWidth
                iconName: "object-width"
                enabled: !barFillWidth.checked
                from: 30
                to: 600
                suffix: i18nc("unit, after a number", " px")
            }
            IconCheckBox {
                id: barFillWidth
                iconName: "panel-fit-width"
                text: i18n("Fill all available width")
                QQC2.ToolTip.text: i18n("In a horizontal panel the widget takes the panel's free space, like a spacer")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }
        IconValueSlider {
            id: barHeight
            Kirigami.FormData.label: i18n("Bar height:")
            iconName: "object-height"
            from: 30
            to: 100
            stepSize: 1
            format: v => i18n("%1 % of the height", v)
            Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        }
        IconSpinBox {
            id: barRadius
            Kirigami.FormData.label: i18n("Bar corner radius:")
            iconName: "draw-rectangle-rounded"
            from: 0
            to: 30
            suffix: i18nc("unit, after a number", " px")
        }
        IconCheckBox {
            id: textShadow
            Kirigami.FormData.label: i18n("Time:")
            iconName: "layer-lower"
            text: i18n("Contrasting shadow behind the time")
        }
        ColorSpecButton {
            id: finishedTextColor
            Kirigami.FormData.label: i18n("Time's up text color:")
            iconName: "format-text-color"
            dialogTitle: i18n("Color of the text shown over the bar when a timer ends")
            gradients: page.gradients
            runningState: page.cfg_runningState
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Buttons") }

        IconSpinBox {
            id: buttonIconSize
            Kirigami.FormData.label: i18n("Button icon size:")
            iconName: "zoom-original"
            from: 8
            to: 128
            suffix: i18nc("unit, after a number", " px")
        }
        IconSpinBox {
            id: buttonBorderWidth
            Kirigami.FormData.label: i18n("Button border width:")
            iconName: "object-stroke-style"
            from: 0
            to: 6
            suffix: i18nc("unit, after a number", " px")
        }
        IconSpinBox {
            id: buttonRadius
            Kirigami.FormData.label: i18n("Button corner radius:")
            iconName: "stroke-join-round"
            from: 0
            to: 30
            suffix: i18nc("unit, after a number", " px")
        }
    }

    footer: ConfigFooter {}
}
