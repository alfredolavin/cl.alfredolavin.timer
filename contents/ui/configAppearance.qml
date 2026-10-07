import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "gradientpicker"
import "code/gradients.js" as Gradients
import "code/colorspec.js" as ColorSpec

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

        QQC2.ComboBox {
            readonly property var layouts: ["frame", "bar"]
            Kirigami.FormData.label: i18n("Layout:")
            PropertyIcon { source: "view-grid" }
            model: [i18n("Frame holding the icon, bar and buttons"), i18n("The bar is the widget, holding the icon and buttons")]
            currentIndex: Math.max(0, layouts.indexOf(page.cfg_panelLayout))
            onActivated: index => page.cfg_panelLayout = layouts[index]
        }
        QQC2.CheckBox {
            id: revealOnHover
            text: i18n("Show only the bar and icon until the mouse is over it")
            QQC2.ToolTip.text: i18n("The bar fills the whole widget with the icon inside it; the buttons (and the frame) appear on mouse over, while the popup is open or when a timer ends")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Frame") }

        QQC2.SpinBox { id: cornerRadius; Kirigami.FormData.label: i18n("Corner radius:"); from: 0; to: 30 }
        PropertyIcon { source: "draw-circle" }
        ColorSpecButton {
            id: frameBackground
            Kirigami.FormData.label: i18n("Background:")
            PropertyIcon { source: "preferences-desktop-color" }
            dialogTitle: i18n("Widget background color")
            gradients: page.gradients
            runningState: page.cfg_runningState
            value: ColorSpec.frameSpec("background", page.cfg_frameBackgroundColor, page.legacy)
            onEdited: page.cfg_frameBackgroundColor = value
        }
        ColorSpecButton {
            id: frameOutline
            Kirigami.FormData.label: i18n("Outline:")
            PropertyIcon { source: "format-stroke-color" }
            dialogTitle: i18n("Widget outline color (frame and buttons)")
            gradients: page.gradients
            runningState: page.cfg_runningState
            value: ColorSpec.frameSpec("outline", page.cfg_frameOutlineColor, page.legacy)
            onEdited: page.cfg_frameOutlineColor = value
            QQC2.ToolTip.text: i18n("Also the border of the buttons. Click to change")
        }
        QQC2.SpinBox { id: borderWidth; Kirigami.FormData.label: i18n("Outline width:"); from: 0; to: 10 }
        PropertyIcon { source: "transform-scale-horizontal" }
        QQC2.SpinBox { id: padding; Kirigami.FormData.label: i18n("Inner padding:"); from: 0; to: 20 }
        PropertyIcon { source: "border-outer" }
        QQC2.SpinBox { id: spacing; Kirigami.FormData.label: i18n("Spacing:"); from: 0; to: 20 }
        PropertyIcon { source: "distribute-horizontal-margin" }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Icon") }

        QQC2.SpinBox { id: iconSize; Kirigami.FormData.label: i18n("Icon size:"); from: 8; to: 128 }
        PropertyIcon { source: "format-text-bold" }
        QQC2.CheckBox { id: autoIconColor; Kirigami.FormData.label: i18n("Icon color:"); text: i18n("Automatic (best contrast)") }
        PropertyIcon { source: "preferences-desktop-color" }
        ColorSpecButton {
            id: iconColor
            enabled: !autoIconColor.checked
            dialogTitle: i18n("Icon color")
            gradients: page.gradients
            runningState: page.cfg_runningState
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Progress bar") }

        RowLayout {
            Kirigami.FormData.label: i18n("Bar width:")
            PropertyIcon { source: "transform-scale-horizontal" }
            QQC2.SpinBox {
                id: barWidth
                enabled: !barFillWidth.checked
                from: 30
                to: 600
                textFromValue: v => i18n("%1 px", v)
                valueFromText: t => parseInt(t) || 100
            }
            QQC2.CheckBox {
                id: barFillWidth
                text: i18n("Fill all available width")
                QQC2.ToolTip.text: i18n("In a horizontal panel the widget takes the panel's free space, like a spacer")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Bar height:")
            PropertyIcon { source: "transform-scale" }
            QQC2.Slider { id: barHeight; from: 30; to: 100; stepSize: 1; Kirigami.StyleHints.tickMarkStepSize: -1; Layout.preferredWidth: Kirigami.Units.gridUnit * 10 }
            QQC2.Label { text: i18n("%1 % of the height", barHeight.value) }
        }
        QQC2.SpinBox { id: barRadius; Kirigami.FormData.label: i18n("Bar corner radius:"); from: 0; to: 30 }
        PropertyIcon { source: "draw-circle" }
        QQC2.CheckBox { id: textShadow; text: i18n("Contrasting shadow behind the time") }
        ColorSpecButton {
            id: finishedTextColor
            Kirigami.FormData.label: i18n("Time's up text color:")
            PropertyIcon { source: "preferences-desktop-color" }
            dialogTitle: i18n("Color of the text shown over the bar when a timer ends")
            gradients: page.gradients
            runningState: page.cfg_runningState
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Buttons") }

        QQC2.SpinBox { id: buttonIconSize; Kirigami.FormData.label: i18n("Button icon size:"); from: 8; to: 128 }
        PropertyIcon { source: "format-text-bold" }
        QQC2.SpinBox { id: buttonBorderWidth; Kirigami.FormData.label: i18n("Button border width:"); from: 0; to: 6 }
        PropertyIcon { source: "transform-scale-horizontal" }
        QQC2.SpinBox { id: buttonRadius; Kirigami.FormData.label: i18n("Button corner radius:"); from: 0; to: 30 }
        PropertyIcon { source: "draw-circle" }
    }

    footer: ConfigFooter {}
}
