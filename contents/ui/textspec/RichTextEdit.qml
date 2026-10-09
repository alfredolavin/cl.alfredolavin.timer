import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Window
import org.kde.kirigami as Kirigami

import "TextSpecCore.js" as TextSpecCore
import "../colorspec"
import "../gradientpicker"
import "../controls"
import "../controls/IconMetrics.js" as IconMetrics

// Shared RichTextEdit control:
// Displays simply as sample text "Leo" on gray checkerboard with soft emboss shadow,
// moves 1px left and 1px top on hover when not pressed. With `iconName` the icon of the setting sits inside at the
// left edge (like the Icon* controls of controls/) and the sample follows it.
// On click, opens a window of its own (sized to its content, not clipped by a small settings dialog):
// - Left: Box with bigger sample text and 4 selectable background swatches (custom, black, white, checkers)
// - Right: TextStyleEditor, the tabs "Font", "Fill", "Effects" and "Align".
// Every change is applied at once (edited(value)); "Reset to default" restores the default style.
Item {
    id: root

    property string value: ""
    property string sampleText: "Leo"
    property string dialogTitle: i18n("Configure Text Style")
    property var gradients: []
    // the icon of the setting, inside at the left edge ("" = none)
    property string iconName: ""

    signal edited(string value)

    property var currentSpec: TextSpecCore.parse(value)

    onValueChanged: {
        currentSpec = TextSpecCore.parse(value);
    }

    function setSpecProp(prop, val) {
        const copy = JSON.parse(JSON.stringify(currentSpec));
        copy[prop] = val;
        currentSpec = copy;
        const jsonStr = JSON.stringify(copy);
        value = jsonStr;
        edited(jsonStr);
    }

    readonly property int iconRoom: iconName !== "" ? IconMetrics.reserve : 0

    implicitWidth: iconRoom + Math.max(84, sampleFrame.implicitWidth + 16)
    implicitHeight: Math.max(34, sampleFrame.implicitHeight + 10)

    PropertyIcon {
        visible: root.iconName !== ""
        name: root.iconName
    }

    // Soft emboss shadow behind the control
    Rectangle {
        id: outerEmbossShadow
        anchors.fill: sampleFrame
        anchors.margins: -1
        radius: 6
        color: "transparent"
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#40000000"
            shadowBlur: 0.4
            shadowHorizontalOffset: 1
            shadowVerticalOffset: 2
        }
    }

    // Main clickable preview frame: centred in the room after the icon
    Item {
        id: sampleFrame
        x: root.iconRoom + Math.round((root.width - root.iconRoom - width) / 2)
        anchors.verticalCenter: parent.verticalCenter

        // Moves 1 pixel left and 1 pixel top on mouse hover when no button is pressed
        readonly property bool lifted: mouseArea.containsMouse && !mouseArea.pressed
        transform: Translate {
            x: sampleFrame.lifted ? -1 : 0
            y: sampleFrame.lifted ? -1 : 0
            Behavior on x { NumberAnimation { duration: 60 } }
            Behavior on y { NumberAnimation { duration: 60 } }
        }

        implicitWidth: Math.max(72, innerText.implicitWidth + 24)
        implicitHeight: Math.max(28, innerText.implicitHeight + 10)
        width: implicitWidth
        height: implicitHeight

        // Gray chequers board background
        Checkerboard {
            anchors.fill: parent
            radius: 5
            cell: 5
            light: "#d5d5d5"
            dark: "#a6a6a6"
        }

        // Soft emboss border: top/left highlight, bottom/right soft shadow
        Rectangle {
            anchors.fill: parent
            radius: 5
            color: "transparent"
            border.width: 1
            border.color: mouseArea.containsMouse ? "#80ffffff" : "#40ffffff"

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: "#50000000"
            }
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: 1
                color: "#50000000"
            }
        }

        // Sample text "Leo" with all configurations applied
        StyledText {
            id: innerText
            anchors.centerIn: parent
            text: root.sampleText || "Leo"
            spec: root.currentSpec
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: dialog.open()
            QQC2.ToolTip.text: i18n("Click to change the text style")
            QQC2.ToolTip.visible: containsMouse
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }

    // The editor in a window of its own
    Window {
        id: dialog
        title: root.dialogTitle
        transientParent: root.Window.window
        modality: Qt.WindowModal
        flags: Qt.Dialog
        color: Kirigami.Theme.backgroundColor
        width: Math.min(Kirigami.Units.gridUnit * 46, Screen.desktopAvailableWidth * 0.9)
        height: Math.min(Kirigami.Units.gridUnit * 32, Screen.desktopAvailableHeight * 0.9)
        minimumWidth: Math.min(Kirigami.Units.gridUnit * 36, Screen.desktopAvailableWidth)
        minimumHeight: Math.min(Kirigami.Units.gridUnit * 20, Screen.desktopAvailableHeight)

        function open() {
            show();
            raise();
            requestActivate();
        }

        Shortcut { sequence: "Escape"; onActivated: dialog.close() }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Kirigami.Units.largeSpacing

            Item {
                id: leftBoxContainer
                Layout.preferredWidth: 260
                Layout.minimumWidth: 230
                Layout.fillHeight: true

                property string previewBgMode: "custom" // "custom", "black", "white", "chekers"

                // Box frame
                Rectangle {
                    id: previewBox
                    anchors.fill: parent
                    radius: 6
                    clip: true
                    border.color: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.2)
                    border.width: 1

                    // Background layers based on previewBgMode
                    // 1. Checkers background
                    Checkerboard {
                        anchors.fill: parent
                        radius: 6
                        cell: 6
                        light: "#d5d5d5"
                        dark: "#9c9c9c"
                        visible: leftBoxContainer.previewBgMode === "chekers"
                    }

                    // 2. Black background
                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: "#000000"
                        visible: leftBoxContainer.previewBgMode === "black"
                    }

                    // 3. White background
                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: "#ffffff"
                        visible: leftBoxContainer.previewBgMode === "white"
                    }

                    // 4. Custom background (reflecting spec's bgMode or neutral backdrop)
                    Item {
                        anchors.fill: parent
                        visible: leftBoxContainer.previewBgMode === "custom"

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: root.currentSpec.bgMode === "color" ? bigSampleText.colorOf(root.currentSpec.bgColor, "#40000000") : "#1e2026"
                            visible: root.currentSpec.bgMode !== "gradient"
                        }

                        Canvas {
                            id: customGradCanvas
                            anchors.fill: parent
                            visible: root.currentSpec.bgMode === "gradient"
                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.reset();
                                ctx.beginPath();
                                ctx.roundedRect(0, 0, width, height, 6, 6);
                                ctx.clip();
                                const gradDef = GradientStore.find(root.currentSpec.bgGradient);
                                const stops = gradDef ? gradDef.stops : [];
                                if (stops && stops.length) {
                                    const g = ctx.createLinearGradient(0, 0, width, 0);
                                    stops.forEach(s => g.addColorStop(Math.max(0, Math.min(1, s.pos)), s.css));
                                    ctx.fillStyle = g;
                                } else {
                                    ctx.fillStyle = bigSampleText.cssOf(root.currentSpec.bgColor, "#1a73e8");
                                }
                                ctx.fillRect(0, 0, width, height);
                            }
                            Connections {
                                target: root
                                function onValueChanged() { customGradCanvas.requestPaint(); }
                            }
                        }
                    }

                    // Bigger sample text with all styles applied
                    StyledText {
                        id: bigSampleText
                        anchors.centerIn: parent
                        text: root.sampleText || "Leo"
                        spec: {
                            const s = JSON.parse(JSON.stringify(root.currentSpec));
                            s.pixelSize = Math.max(26, Math.round((root.currentSpec.pixelSize || 12) * 1.6));
                            return s;
                        }
                    }

                    // Bottom right corner: Small squares to select preview background
                    Row {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 8
                        spacing: 6

                        // Small Square: Custom
                        Rectangle {
                            width: 22
                            height: 22
                            radius: 3
                            border.width: leftBoxContainer.previewBgMode === "custom" ? 2 : 1
                            border.color: leftBoxContainer.previewBgMode === "custom" ? Kirigami.Theme.highlightColor : "#60ffffff"
                            color: "#2d3139"

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 14
                                height: 14
                                source: "show-background"
                            }

                            QQC2.ToolTip.text: i18n("The text's own background (or a dark one when it has none)")
                            QQC2.ToolTip.visible: customMa.containsMouse
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                            MouseArea {
                                id: customMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: leftBoxContainer.previewBgMode = "custom"
                            }
                        }

                        // Small Square: Black
                        Rectangle {
                            width: 22
                            height: 22
                            radius: 3
                            color: "#000000"
                            border.width: leftBoxContainer.previewBgMode === "black" ? 2 : 1
                            border.color: leftBoxContainer.previewBgMode === "black" ? Kirigami.Theme.highlightColor : "#60ffffff"

                            QQC2.ToolTip.text: i18n("Black background")
                            QQC2.ToolTip.visible: blackMa.containsMouse
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                            MouseArea {
                                id: blackMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: leftBoxContainer.previewBgMode = "black"
                            }
                        }

                        // Small Square: White
                        Rectangle {
                            width: 22
                            height: 22
                            radius: 3
                            color: "#ffffff"
                            border.width: leftBoxContainer.previewBgMode === "white" ? 2 : 1
                            border.color: leftBoxContainer.previewBgMode === "white" ? Kirigami.Theme.highlightColor : "#40000000"

                            QQC2.ToolTip.text: i18n("White background")
                            QQC2.ToolTip.visible: whiteMa.containsMouse
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                            MouseArea {
                                id: whiteMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: leftBoxContainer.previewBgMode = "white"
                            }
                        }

                        // Small Square: Checkers
                        Rectangle {
                            width: 22
                            height: 22
                            radius: 3
                            clip: true
                            border.width: leftBoxContainer.previewBgMode === "chekers" ? 2 : 1
                            border.color: leftBoxContainer.previewBgMode === "chekers" ? Kirigami.Theme.highlightColor : "#60ffffff"

                            Checkerboard {
                                anchors.fill: parent
                                cell: 3
                                radius: 3
                            }

                            QQC2.ToolTip.text: i18n("Checkers background")
                            QQC2.ToolTip.visible: checkMa.containsMouse
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                            MouseArea {
                                id: checkMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: leftBoxContainer.previewBgMode = "chekers"
                            }
                        }
                    }
                }
            }

                TextStyleEditor {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spec: root.currentSpec
                    onChanged: (prop, value) => root.setSpecProp(prop, value)
                }
            }

            Kirigami.Separator { Layout.fillWidth: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.Button {
                    icon.name: "edit-undo"
                    text: i18n("Reset to Default")
                    onClicked: {
                        const def = TextSpecCore.defaultSpec();
                        root.currentSpec = def;
                        root.value = JSON.stringify(def);
                        root.edited(root.value);
                    }
                }

                Item { Layout.fillWidth: true }

                QQC2.Button {
                    icon.name: "dialog-ok"
                    text: i18n("Done")
                    onClicked: dialog.close()
                }
            }
        }
    }
}
