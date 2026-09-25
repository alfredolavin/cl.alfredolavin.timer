import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQControls

KCM.SimpleKCM {
    id: page

    property alias cfg_cornerRadius: cornerRadius.value
    property alias cfg_borderColor: borderColor.color
    property alias cfg_borderWidth: borderWidth.value
    property alias cfg_backgroundTransparency: transparency.value
    property alias cfg_padding: padding.value
    property alias cfg_spacing: spacing.value
    property alias cfg_iconSize: iconSize.value
    property alias cfg_useThemeIconColor: autoIconColor.checked
    property alias cfg_iconColor: iconColor.color
    property alias cfg_nameFontSize: nameFontSize.value
    property alias cfg_nameBold: nameBold.checked
    property alias cfg_barWidth: barWidth.value
    property alias cfg_barHeightPercent: barHeight.value
    property alias cfg_barRadius: barRadius.value
    property alias cfg_timeFontSize: timeFontSize.value
    property alias cfg_textShadow: textShadow.checked
    property alias cfg_buttonIconSize: buttonIconSize.value
    property alias cfg_buttonBorderWidth: buttonBorderWidth.value
    property alias cfg_buttonRadius: buttonRadius.value
    property alias cfg_finishedTextColor: finishedTextColor.color

    Kirigami.FormLayout {
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Frame") }

        QQC2.SpinBox { id: cornerRadius; Kirigami.FormData.label: i18n("Corner radius:"); from: 0; to: 30 }
        KQControls.ColorButton { id: borderColor; Kirigami.FormData.label: i18n("Border color:"); showAlphaChannel: false }
        QQC2.SpinBox { id: borderWidth; Kirigami.FormData.label: i18n("Border width:"); from: 0; to: 10 }
        RowLayout {
            Kirigami.FormData.label: i18n("Background transparency:")
            QQC2.Slider { id: transparency; from: 0; to: 100; stepSize: 1; Layout.preferredWidth: Kirigami.Units.gridUnit * 10 }
            QQC2.Label { text: transparency.value + " %" }
        }
        QQC2.SpinBox { id: padding; Kirigami.FormData.label: i18n("Inner padding:"); from: 0; to: 20 }
        QQC2.SpinBox { id: spacing; Kirigami.FormData.label: i18n("Spacing:"); from: 0; to: 20 }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Icon") }

        QQC2.SpinBox { id: iconSize; Kirigami.FormData.label: i18n("Icon size:"); from: 8; to: 128 }
        QQC2.CheckBox { id: autoIconColor; Kirigami.FormData.label: i18n("Icon color:"); text: i18n("Automatic (best contrast)") }
        KQControls.ColorButton { id: iconColor; enabled: !autoIconColor.checked }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Name and progress bar") }

        QQC2.SpinBox { id: nameFontSize; Kirigami.FormData.label: i18n("Name font size (px):"); from: 5; to: 40 }
        QQC2.CheckBox { id: nameBold; text: i18n("Bold name") }
        QQC2.SpinBox { id: barWidth; Kirigami.FormData.label: i18n("Bar width (px):"); from: 30; to: 600 }
        RowLayout {
            Kirigami.FormData.label: i18n("Bar height:")
            QQC2.Slider { id: barHeight; from: 30; to: 100; stepSize: 1; Layout.preferredWidth: Kirigami.Units.gridUnit * 10 }
            QQC2.Label { text: i18n("%1 % of the height", barHeight.value) }
        }
        QQC2.SpinBox { id: barRadius; Kirigami.FormData.label: i18n("Bar corner radius:"); from: 0; to: 30 }
        QQC2.SpinBox {
            id: timeFontSize
            Kirigami.FormData.label: i18n("Time font size (px):")
            from: 0; to: 40
            textFromValue: v => v === 0 ? i18n("Auto") : v
            valueFromText: t => t === i18n("Auto") ? 0 : parseInt(t)
        }
        QQC2.CheckBox { id: textShadow; text: i18n("Contrasting shadow behind the time") }
        KQControls.ColorButton {
            id: finishedTextColor
            Kirigami.FormData.label: i18n("Time's up text color:")
            showAlphaChannel: false
            QQC2.ToolTip.text: i18n("Color of the bold text shown over the bar when a timer ends (set the text per timer)")
            QQC2.ToolTip.visible: hovered
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Buttons") }

        QQC2.SpinBox { id: buttonIconSize; Kirigami.FormData.label: i18n("Button icon size:"); from: 8; to: 128 }
        QQC2.SpinBox { id: buttonBorderWidth; Kirigami.FormData.label: i18n("Button border width:"); from: 0; to: 6 }
        QQC2.SpinBox { id: buttonRadius; Kirigami.FormData.label: i18n("Button corner radius:"); from: 0; to: 30 }
    }
}
