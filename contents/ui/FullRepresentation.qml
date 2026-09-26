import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

import "code/util.js" as Util

// Popup: running timers on the left, timers that can be started on the right
PlasmaExtras.Representation {
    id: full

    property var app
    readonly property var cfg: Plasmoid.configuration
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    // both columns get the same width: enough for a running timer frame
    readonly property int columnWidth: Math.max(Kirigami.Units.gridUnit * 15, sizer.implicitWidth)

    Layout.minimumWidth: Kirigami.Units.gridUnit * 24
    Layout.preferredWidth: 2 * columnWidth + Kirigami.Units.largeSpacing * 3
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
        // contentItem (not a child anchored to the heading) so the heading gets its real height
        contentItem: Item {
            implicitWidth: headingRow.implicitWidth
            implicitHeight: headingRow.implicitHeight

            RowLayout {
                id: headingRow
                anchors.fill: parent
                spacing: Kirigami.Units.largeSpacing
                Kirigami.Heading {
                    // lines up with the running column below
                    Layout.preferredWidth: runningScroll.width
                    level: 3
                    elide: Text.ElideRight
                    text: i18n("Running timers")
                }
                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 3
                    elide: Text.ElideRight
                    text: i18n("Start a timer")
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
    }

    // Quick one-off timer ("25", "1h30", "90s") or alarm ("14:30", "7pm"), started with the + button or Enter
    footer: PlasmaExtras.PlasmoidHeading {
        contentItem: Item {
            implicitWidth: quickRow.implicitWidth
            implicitHeight: quickRow.implicitHeight

            RowLayout {
                id: quickRow
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing

                readonly property var parsed: Util.parseQuick(quickField.text)

                function launch() {
                    if (!parsed)
                        return;
                    full.app.expanded = false;
                    full.app.startQuick(parsed);
                    quickField.clear();
                }

                PlasmaComponents.TextField {
                    id: quickField
                    Layout.fillWidth: true
                    placeholderText: i18n("Quick timer or alarm: 25, 1h30, 90s, 14:30, 7pm…")
                    color: text.length && !quickRow.parsed ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                    onAccepted: quickRow.launch()
                }
                PlasmaComponents.Label {
                    visible: !!quickRow.parsed
                    opacity: 0.7
                    text: !quickRow.parsed ? ""
                        : quickRow.parsed.kind === "alarm"
                            ? i18n("Alarm at %1, in %2", Util.formatClock(quickRow.parsed.at),
                                   Util.formatDuration(Math.round((Util.nextOccurrence(quickRow.parsed.at, Date.now()) - Date.now()) / 60000) * 60))
                            : i18n("Timer, %1", Util.formatDuration(quickRow.parsed.duration))
                }
                PlasmaComponents.ToolButton {
                    icon.name: "list-add"
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: i18n("Start now")
                    enabled: !!quickRow.parsed
                    PlasmaComponents.ToolTip.text: text
                    PlasmaComponents.ToolTip.visible: hovered
                    onClicked: quickRow.launch()
                }
            }

            AlarmSilencer {
                app: full.app
            }
        }
    }

    AlarmSilencer {
        app: full.app
    }

    RowLayout {
        anchors.fill: parent
        anchors.topMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.largeSpacing

        // ---- running ----
        // equal preferred widths + fillWidth on both: the RowLayout splits the space evenly
        PlasmaComponents.ScrollView {
            id: runningScroll
            Layout.preferredWidth: full.columnWidth
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: runningList
                clip: true
                spacing: Kirigami.Units.smallSpacing
                // In a panel the nearest timer is already shown; on the desktop list them all
                model: full.inPanel ? full.app.others : full.app.order

                delegate: Item {
                    required property var modelData
                    width: ListView.view.width
                    implicitHeight: frame.height
                    TimerFrame {
                        id: frame
                        app: full.app
                        uid: parent.modelData
                        stretch: true
                        width: parent.width
                        height: Math.round(implicitHeight * 0.75)
                    }
                }

                PlasmaExtras.PlaceholderMessage {
                    anchors.centerIn: parent
                    width: parent.width - Kirigami.Units.gridUnit * 2
                    visible: runningList.count === 0
                    iconName: "chronometer"
                    text: full.inPanel ? i18n("No other timers running") : i18n("No timers running")
                }
            }
        }

        Kirigami.Separator {
            Layout.fillHeight: true
        }

        // ---- available ----
        PlasmaComponents.ScrollView {
            Layout.preferredWidth: full.columnWidth
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: availableList
                clip: true
                model: full.app.available

                delegate: PlasmaComponents.ItemDelegate {
                    id: item
                    required property var modelData
                    width: ListView.view.width
                    onClicked: {
                        full.app.expanded = false;
                        full.app.start(modelData.id);
                    }
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        SvgIcon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                            hex: item.modelData.icon
                            color: Kirigami.Theme.textColor
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: item.modelData.name
                                elide: Text.ElideRight
                            }
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: item.modelData.kind === "alarm" ? i18n("Alarm at %1", Util.formatClock(item.modelData.at))
                                                                      : Util.formatDuration(item.modelData.duration)
                                opacity: 0.7
                                font: Kirigami.Theme.smallFont
                            }
                        }
                        GradientBar {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 0.6
                            stops: full.app.gradientFor(item.modelData.gradient).stops
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

                PlasmaExtras.PlaceholderMessage {
                    anchors.centerIn: parent
                    width: parent.width - Kirigami.Units.gridUnit * 2
                    visible: availableList.count === 0
                    iconName: "checkmark"
                    text: i18n("Every timer is already running")
                    helpfulAction: Kirigami.Action {
                        icon.name: "configure"
                        text: i18n("Add more timers…")
                        onTriggered: Plasmoid.internalAction("configure").trigger()
                    }
                }
            }
        }
    }
}
