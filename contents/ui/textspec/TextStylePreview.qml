import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Preview area for TextStyleDialog showing the styled text with background switcher
Rectangle {
    id: root

    property var spec: null
    property string sampleText: "Sample Text 123 ●"

    // Background themes: 0 = Dark, 1 = Light, 2 = Checker, 3 = Accent
    property int bgThemeIndex: 0

    radius: 6
    clip: true
    color: {
        switch (bgThemeIndex) {
            case 0: return "#1c1e24";
            case 1: return "#f2f4f8";
            case 3: return Kirigami.Theme.highlightColor;
            default: return "#282a36";
        }
    }
    border.color: Kirigami.ColorUtils.tintWithAlpha(color, Kirigami.Theme.textColor, 0.2)
    border.width: 1

    implicitHeight: 90
    implicitWidth: 300

    // Checkerboard pattern when index === 2
    Grid {
        id: checker
        visible: root.bgThemeIndex === 2
        anchors.fill: parent
        columns: Math.ceil(width / 16)
        rows: Math.ceil(height / 16)
        Repeater {
            model: checker.columns * checker.rows
            Rectangle {
                width: 16; height: 16
                color: (Math.floor(index / checker.columns) + (index % checker.columns)) % 2 === 0 ? "#2b2e3b" : "#1e2029"
            }
        }
    }

    // Styled text in center
    StyledText {
        anchors.centerIn: parent
        text: root.sampleText
        spec: root.spec
    }

    // BG switcher button in bottom-right corner
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 4
        spacing: 2

        Repeater {
            model: [
                { name: i18n("Dark background"), c: "#1c1e24" },
                { name: i18n("Light background"), c: "#ffffff" },
                { name: i18n("Checkered background"), c: "#555555" },
                { name: i18n("Accent color background"), c: "#1a73e8" }
            ]
            Rectangle {
                required property var modelData
                required property int index
                width: 16; height: 16
                radius: 3
                color: modelData.c
                border.color: root.bgThemeIndex === index ? "#ffea00" : "#888888"
                border.width: root.bgThemeIndex === index ? 2 : 1
                QQC2.ToolTip.text: modelData.name
                QQC2.ToolTip.visible: bgMouse.containsMouse
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                MouseArea {
                    id: bgMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.bgThemeIndex = parent.index
                }
            }
        }
    }
}
