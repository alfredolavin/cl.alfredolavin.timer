import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: container

    property var targetControl: null
    default property alias content: innerLayout.data
    property alias iconSource: iconItem.source
    property alias nerdIcon: iconItem.nerdIcon
    property alias iconColor: iconItem.color

    implicitWidth: Math.max(Kirigami.Units.gridUnit * 7, innerLayout.implicitWidth + 10)
    implicitHeight: Math.max(Kirigami.Units.gridUnit * 1.6, innerLayout.implicitHeight)

    radius: 5
    color: Kirigami.Theme.backgroundColor
    border.color: (targetControl && (targetControl.activeFocus || targetControl.visualFocus || targetControl.hovered))
                  ? Kirigami.Theme.highlightColor
                  : Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.textColor, Kirigami.Theme.backgroundColor, 0.75)
    border.width: 1
    opacity: (targetControl && !targetControl.enabled) ? 0.6 : 1.0

    Component.onCompleted: {
        for (var i = 0; i < innerLayout.children.length; ++i) {
            var c = innerLayout.children[i];
            if (c !== iconItem && (c.hovered !== undefined || c.activeFocus !== undefined)) {
                targetControl = c;
                break;
            }
        }
    }

    RowLayout {
        id: innerLayout
        anchors.fill: parent
        anchors.leftMargin: 6
        spacing: 4

        PropertyIcon {
            id: iconItem
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
