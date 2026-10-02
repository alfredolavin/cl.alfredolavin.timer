import QtQuick
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

// Bordered, icon-only button
Rectangle {
    id: btn

    property string iconName
    property int size: 32
    property string tooltip
    // toggle buttons: drawn with a highlight tint while on
    property bool checked: false
    property color borderColor: Kirigami.Theme.textColor
    readonly property color hl: Kirigami.Theme.highlightColor
    signal clicked

    implicitWidth: size + 2 * (border.width + 1)
    implicitHeight: implicitWidth
    radius: Plasmoid.configuration.buttonRadius
    border.width: Plasmoid.configuration.buttonBorderWidth
    border.color: mouse.containsMouse ? hl : borderColor
    color: mouse.pressed ? Qt.rgba(hl.r, hl.g, hl.b, 0.5)
         : mouse.containsMouse ? Qt.rgba(hl.r, hl.g, hl.b, 0.25)
         : checked ? Qt.rgba(hl.r, hl.g, hl.b, 0.35) : "transparent"
    opacity: enabled ? 1 : 0.4

    Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }

    Kirigami.Icon {
        anchors.centerIn: parent
        width: btn.size
        height: btn.size
        source: btn.iconName
        active: mouse.containsMouse
    }

    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        mainText: btn.tooltip
        active: btn.tooltip.length > 0

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btn.clicked()
        }
    }
}
