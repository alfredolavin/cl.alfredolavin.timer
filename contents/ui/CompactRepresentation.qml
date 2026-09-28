import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: compact

    property var app

    // filling: take the panel's free space (like a spacer) instead of a fixed width
    readonly property bool fill: Plasmoid.configuration.barFillWidth && Plasmoid.formFactor !== PlasmaCore.Types.Vertical
    Layout.minimumWidth: frame.implicitWidth
    Layout.preferredWidth: frame.implicitWidth
    Layout.maximumWidth: fill ? Number.POSITIVE_INFINITY : frame.implicitWidth
    Layout.fillWidth: fill
    Layout.minimumHeight: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? frame.implicitHeight : -1

    TimerFrame {
        id: frame
        app: compact.app
        uid: compact.app.currentUid
        panelMode: true
        // hovered, or its popup is open
        revealed: hover.hovered || compact.app.expanded
        anchors.verticalCenter: parent.verticalCenter
        width: compact.fill ? parent.width : implicitWidth
        height: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? implicitHeight : parent.height
        onEmptyClicked: compact.app.togglePopup()

        IconButton {
            size: frame.buttonSize
            borderColor: frame.outlineColor
            iconName: compact.app.expanded ? "go-down" : "go-up"
            tooltip: compact.app.others.length
                ? i18np("%1 more running timer", "%1 more running timers", compact.app.others.length)
                : i18n("No other running timers")
            onClicked: compact.app.togglePopup()

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

    }

    HoverHandler {
        id: hover
    }

    AlarmSilencer {
        app: compact.app
    }
}
