import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "TextSpecCore.js" as TextSpecCore
import "../gradientpicker/code/gradients.js" as Gradients

// A button presenting itself with a live preview of the text style and summary;
// clicking it opens TextStyleDialog encapsulating all options. Hosts put the icon of the setting inside it:
// leftPadding: IconMetrics.reserve and a PropertyIcon child (shared controls/).
QQC2.Button {
    id: btn

    // Stored JSON spec string
    property string value: ""
    property string sampleText: "Abc 123"
    property string dialogTitle: i18n("Configure Text Style")

    signal edited(string value)

    readonly property var currentSpec: TextSpecCore.parse(value)
    // the preview's background contrasts with the text color (a plain color; dark behind gradients)
    readonly property color textColor: currentSpec.textMode === "gradient" ? "white" : swatchText.colorOf(currentSpec.textColor, "#ffffffff")
    readonly property color previewBackground: Gradients.prefersDark({ r: textColor.r, g: textColor.g, b: textColor.b }) ? "#1e2029" : "#eef0f4"

    implicitWidth: Math.max(implicitContentWidth + leftPadding + rightPadding, Kirigami.Units.gridUnit * 12)
    implicitHeight: Math.max(implicitContentHeight + topPadding + bottomPadding, Kirigami.Units.gridUnit * 2.2)

    contentItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        // Live preview swatch
        Rectangle {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 32
            radius: 4
            color: btn.previewBackground
            border.color: Kirigami.ColorUtils.tintWithAlpha(color, Kirigami.Theme.textColor, 0.2)
            border.width: 1
            clip: true

            StyledText {
                id: swatchText
                anchors.centerIn: parent
                text: btn.sampleText
                spec: btn.currentSpec
            }
        }

        // Summary text
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            QQC2.Label {
                Layout.fillWidth: true
                text: i18nc("font, size in px, weight", "%1 %2 px %3", btn.currentSpec.fontFamily || i18n("Default"), btn.currentSpec.pixelSize,
                           btn.currentSpec.weight >= 700 ? i18n("Bold") : (btn.currentSpec.weight <= 300 ? i18n("Light") : i18n("Normal")))
                elide: Text.ElideRight
                font.bold: true
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: {
                    var fx = [];
                    if (btn.currentSpec.outlineEnabled) fx.push(i18n("outline"));
                    if (btn.currentSpec.glowEnabled) fx.push(i18n("glow"));
                    if (btn.currentSpec.shadows.some(s => s.enabled)) fx.push(i18n("shadow"));
                    if (btn.currentSpec.bgMode !== "none") fx.push(i18n("bg"));
                    if (btn.currentSpec.letterSpacing !== 0) fx.push(i18n("spaced"));
                    return fx.length > 0 ? fx.join(", ") : i18n("standard text");
                }
                opacity: 0.7
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                elide: Text.ElideRight
            }
        }

        Kirigami.Icon {
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            source: "document-edit"
            opacity: 0.6
        }
    }

    onClicked: {
        dialog.load(btn.value);
        dialog.show();
        dialog.requestActivate();
    }

    TextStyleDialog {
        id: dialog
        transientParent: btn.Window.window
        dialogTitle: btn.dialogTitle
        sampleText: btn.sampleText

        onAccepted: newValue => {
            btn.value = newValue;
            btn.edited(newValue);
        }
    }
}
