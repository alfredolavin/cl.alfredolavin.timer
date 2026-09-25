import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

import "code/util.js" as Util

PlasmaExtras.Representation {
    id: full

    property var app
    readonly property bool addMode: app.popupMode === "add"
    readonly property var cfg: Plasmoid.configuration

    Layout.minimumWidth: Kirigami.Units.gridUnit * 16
    Layout.preferredWidth: Math.max(Kirigami.Units.gridUnit * 18, sizer.implicitWidth + Kirigami.Units.largeSpacing * 2)
    Layout.minimumHeight: Kirigami.Units.gridUnit * 8
    Layout.preferredHeight: Kirigami.Units.gridUnit * 20

    // Used only to measure how wide a timer frame is
    TimerFrame {
        id: sizer
        app: full.app
        uid: ""
        visible: false
    }

    header: PlasmaExtras.PlasmoidHeading {
        RowLayout {
            anchors.fill: parent
            Kirigami.Heading {
                Layout.fillWidth: true
                level: 3
                text: full.addMode ? i18n("Start a timer") : i18n("Running timers")
            }
            PlasmaComponents.ToolButton {
                icon.name: full.addMode ? "chronometer" : "list-add"
                display: PlasmaComponents.AbstractButton.IconOnly
                text: full.addMode ? i18n("Show running timers") : i18n("Start a timer")
                PlasmaComponents.ToolTip.text: text
                PlasmaComponents.ToolTip.visible: hovered
                onClicked: full.app.popupMode = full.addMode ? "running" : "add"
            }
            PlasmaComponents.ToolButton {
                icon.name: "configure"
                display: PlasmaComponents.AbstractButton.IconOnly
                text: i18n("Configure timers…")
                PlasmaComponents.ToolTip.text: text
                PlasmaComponents.ToolTip.visible: hovered
                onClicked: Plasmoid.internalAction("configure").trigger()
            }
        }

        AlarmSilencer {
            app: full.app
        }
    }

    AlarmSilencer {
        app: full.app
    }

    PlasmaComponents.ScrollView {
        anchors.fill: parent

        ListView {
            id: list
            clip: true
            spacing: Kirigami.Units.smallSpacing
            // In a panel the nearest timer is already shown; on the desktop list them all
            model: full.addMode ? full.app.available
                 : Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical ? full.app.others : full.app.order

            delegate: Loader {
                required property var modelData
                width: ListView.view.width
                sourceComponent: full.addMode ? availableDelegate : runningDelegate
            }

            PlasmaExtras.PlaceholderMessage {
                anchors.centerIn: parent
                width: parent.width - Kirigami.Units.gridUnit * 2
                visible: list.count === 0
                iconName: full.addMode ? "checkmark" : "chronometer"
                text: full.addMode ? i18n("Every timer is already running") : i18n("No other timers running")
                helpfulAction: Kirigami.Action {
                    icon.name: full.addMode ? "configure" : "list-add"
                    text: full.addMode ? i18n("Add more timers…") : i18n("Start a timer")
                    onTriggered: full.addMode ? Plasmoid.internalAction("configure").trigger() : full.app.popupMode = "add"
                }
            }
        }
    }

    Component {
        id: runningDelegate
        Item {
            implicitHeight: frame.height
            TimerFrame {
                id: frame
                app: full.app
                uid: parent.parent.modelData
                stretch: true
                width: parent.width
                height: Math.round(implicitHeight * 0.75)
            }
        }
    }

    Component {
        id: availableDelegate
        PlasmaComponents.ItemDelegate {
            readonly property var timer: parent.modelData
            onClicked: {
                full.app.start(timer.id);
                full.app.expanded = false;
            }
            contentItem: RowLayout {
                spacing: Kirigami.Units.largeSpacing
                Text {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    text: Util.glyph(timer.icon)
                    font.family: full.app.iconFont
                    font.pixelSize: Kirigami.Units.iconSizes.medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Kirigami.Theme.textColor
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: timer.name
                        elide: Text.ElideRight
                    }
                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: Util.formatDuration(timer.duration)
                        opacity: 0.7
                        font: Kirigami.Theme.smallFont
                    }
                }
                GradientBar {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 0.6
                    stops: full.app.gradientFor(timer.gradient).stops
                    progress: 1
                    radius: full.cfg.barRadius
                }
                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    source: "media-playback-start"
                }
            }
        }
    }
}
