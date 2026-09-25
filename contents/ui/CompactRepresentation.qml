import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: compact

    property var app

    Layout.minimumWidth: frame.implicitWidth
    Layout.preferredWidth: frame.implicitWidth
    Layout.maximumWidth: frame.implicitWidth
    Layout.minimumHeight: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? frame.implicitHeight : -1

    TimerFrame {
        id: frame
        app: compact.app
        uid: compact.app.currentUid
        anchors.verticalCenter: parent.verticalCenter
        width: implicitWidth
        height: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? implicitHeight : parent.height
        onEmptyClicked: compact.app.openPopup("add")

        IconButton {
            size: frame.buttonSize
            borderColor: Plasmoid.configuration.borderColor
            iconName: compact.app.expanded && compact.app.popupMode === "running" ? "go-down" : "go-up"
            tooltip: compact.app.others.length
                ? i18np("%1 more running timer", "%1 more running timers", compact.app.others.length)
                : i18n("No other running timers")
            onClicked: compact.app.openPopup("running")

            // small counter badge
            Rectangle {
                visible: compact.app.others.length > 0
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 1
                width: Math.max(height, badge.implicitWidth + 4)
                height: Math.max(9, parent.height * 0.34)
                radius: height / 2
                color: Kirigami.Theme.highlightColor
                Text {
                    id: badge
                    anchors.centerIn: parent
                    text: compact.app.others.length
                    color: Kirigami.Theme.highlightedTextColor
                    font.pixelSize: parent.height * 0.8
                    font.bold: true
                }
            }
        }

        IconButton {
            size: frame.buttonSize
            borderColor: Plasmoid.configuration.borderColor
            iconName: "list-add"
            // with a timer running, new timers are started from the ↑ popup
            visible: !compact.app.currentUid
            tooltip: i18n("Start a timer")
            onClicked: compact.app.openPopup("add")
        }
    }
}
