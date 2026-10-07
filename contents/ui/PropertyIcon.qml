import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: propIcon
    implicitWidth: 20
    implicitHeight: 20
    Layout.preferredWidth: 20
    Layout.preferredHeight: 20
    Layout.alignment: Qt.AlignVCenter

    property string source: ""
    property string nerdIcon: ""
    property color color: Kirigami.Theme.highlightColor

    // If inside a control (parent has leftPadding defined),
    // automatically position vertically centered at x: 4
    x: (parent && parent.leftPadding !== undefined) ? 4 : 0
    anchors.verticalCenter: (parent && parent.leftPadding !== undefined) ? parent.verticalCenter : undefined

    Kirigami.Icon {
        id: iconItem
        anchors.fill: parent
        visible: propIcon.nerdIcon === "" && propIcon.source !== ""
        source: propIcon.source
        isMask: false
    }

    Text {
        id: nerdText
        anchors.centerIn: parent
        visible: propIcon.nerdIcon !== ""
        text: propIcon.nerdIcon
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 16
        color: propIcon.color
    }
}
