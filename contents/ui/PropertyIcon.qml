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

    // Target left padding for parent controls containing an embedded icon
    property int reservedPadding: 28

    readonly property bool isInsideControl: parent && parent.leftPadding !== undefined

    // If inside a control (parent has leftPadding defined),
    // automatically position vertically centered at x: 4
    x: isInsideControl ? 4 : 0
    anchors.verticalCenter: isInsideControl ? parent.verticalCenter : undefined

    function applyPadding() {
        if (isInsideControl) {
            if (parent.indicator && parent.indicator.x < 15) {
                return;
            }
            if (parent.leftPadding < reservedPadding) {
                parent.leftPadding = reservedPadding;
            }
        }
    }

    Component.onCompleted: applyPadding()
    onParentChanged: applyPadding()

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
