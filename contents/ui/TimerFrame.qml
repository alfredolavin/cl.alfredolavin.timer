import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

import "code/util.js" as Util
import "code/gradients.js" as Gradients

// Rounded frame: icon | name + gradient bar | play/pause | delete | extra buttons
Rectangle {
    id: frame

    property var app
    property string uid
    default property alias extraButtons: extras.data
    signal emptyClicked
    // When true the progress bar grows to fill the available width
    property bool stretch: false

    readonly property var cfg: Plasmoid.configuration
    readonly property var entry: uid ? app.entry(uid) : null
    readonly property var gradient: app.gradientFor(entry ? entry.gradient : "")
    readonly property int inset: cfg.borderWidth + cfg.padding
    readonly property int inner: Math.max(8, height - 2 * inset)
    // Buttons take at most 85% of the available height
    readonly property int buttonSize: Math.max(8, Math.min(cfg.buttonIconSize, Math.round((inner - 2 * (cfg.buttonBorderWidth + 1)) * 0.85)))
    readonly property bool finished: !!entry && entry.finished
    readonly property int barHeight: Math.round(inner * cfg.barHeightPercent / 100)
    // "Time is up" text drawn over the bar, e.g. "Tea Ready!! (3m)"
    readonly property string finishedText: finished ? Util.finishedMessage(entry) + " (" + Util.formatDuration(entry.duration) + ")" : ""
    // with no timer, "No timers running" is centered in the bar, shrunk to fit its width
    readonly property int emptyFontSize: Math.max(6, Math.min(Math.round(barHeight * 0.62),
        Math.floor(100 * (cfg.barWidth - Math.max(4, barHeight / 2)) / Math.max(1, emptyMetrics.width))))
    readonly property int barAreaWidth: cfg.barWidth
    // Opaque color of the frame as seen on the panel, for contrast decisions
    readonly property var baseColor: Gradients.over({ r: color.r, g: color.g, b: color.b, a: color.a },
        { r: Kirigami.Theme.backgroundColor.r, g: Kirigami.Theme.backgroundColor.g, b: Kirigami.Theme.backgroundColor.b, a: 1 })
    readonly property color contrastColor: Gradients.prefersDark(baseColor) ? "#1b1b1b" : "#f5f5f5"

    implicitWidth: row.implicitWidth + 2 * inset
    implicitHeight: Math.max(cfg.iconSize, cfg.buttonIconSize + 2 * (cfg.buttonBorderWidth + 1)) + 2 * inset
    radius: cfg.cornerRadius
    border.width: cfg.borderWidth
    border.color: finished && app.blink ? Kirigami.Theme.negativeTextColor : cfg.borderColor
    color: Qt.rgba(cfg.borderColor.r, cfg.borderColor.g, cfg.borderColor.b, 1 - cfg.backgroundTransparency / 100)

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: frame.inset
        spacing: cfg.spacing

        SvgIcon {
            readonly property int px: Math.min(cfg.iconSize, frame.inner)
            Layout.preferredWidth: px
            Layout.preferredHeight: px
            Layout.alignment: Qt.AlignVCenter
            hex: frame.entry ? frame.entry.icon : "f051b"
            color: cfg.useThemeIconColor ? frame.contrastColor : cfg.iconColor
            opacity: frame.finished && frame.app.blink ? 0.3 : 1
        }

        // Name drawn above the bar (higher z) so it can be larger and overlap it
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: frame.stretch
            Layout.preferredWidth: frame.barAreaWidth
            Layout.maximumWidth: frame.stretch ? Number.POSITIVE_INFINITY : frame.barAreaWidth

            Text {
                z: 1
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 2
                visible: !!frame.entry && !frame.finished
                text: frame.entry ? frame.entry.name : ""
                color: frame.contrastColor
                font.pixelSize: cfg.nameFontSize
                font.bold: cfg.nameBold
                elide: Text.ElideRight

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Gradients.prefersDark(frame.baseColor) ? "white" : "black"
                    shadowOpacity: 0.8
                    shadowBlur: 0.3
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 1
                    blurMax: 6
                }
            }

            GradientBar {
                // under the name; vertically centered when there is no name to show
                y: !frame.entry || frame.finished ? Math.round((parent.height - height) / 2) : parent.height - height
                anchors.left: parent.left
                anchors.right: parent.right
                height: frame.barHeight
                stops: frame.gradient.stops
                progress: frame.entry ? frame.app.progressOf(frame.entry) : 0
                text: !frame.entry ? i18n("No timers running")
                    : frame.finished ? frame.finishedText
                    : Util.formatTime(frame.app.remainingOf(frame.entry))
                z: -1 // outer shadows and glow go under the name
                trackColor: cfg.trackColor
                borderColor: cfg.barBorderColor
                borderWidth: cfg.barBorderWidth
                shadows: Util.parseShadows(cfg.barShadows)
                glow: ({ enabled: cfg.glowEnabled, useGradient: cfg.glowUseGradient, color: cfg.glowColor,
                         radius: cfg.glowRadius, strength: cfg.glowStrength, opacity: cfg.glowOpacity / 100 })
                baseColor: Qt.rgba(frame.baseColor.r, frame.baseColor.g, frame.baseColor.b, 1)
                radius: cfg.barRadius
                // when finished: bold text at 95% of the bar height in the configured color
                fontSize: !frame.entry ? frame.emptyFontSize
                        : frame.finished ? Math.max(6, Math.round(frame.barHeight * 0.95)) : cfg.timeFontSize
                labelColor: frame.finished ? cfg.finishedTextColor : null
                shadow: cfg.textShadow
                blink: frame.finished && frame.app.blink
                opacity: frame.entry && frame.entry.paused ? 0.6 : 1
            }
        }

        IconButton {
            visible: !!frame.entry && !frame.finished
            size: frame.buttonSize
            borderColor: cfg.borderColor
            iconName: !frame.entry ? "" : frame.entry.paused ? "media-playback-start" : "media-playback-pause"
            tooltip: !frame.entry ? "" : frame.entry.paused ? i18n("Resume") : i18n("Pause")
            onClicked: frame.app.togglePause(frame.uid)
        }

        IconButton {
            visible: !!frame.entry
            size: frame.buttonSize
            borderColor: cfg.borderColor
            iconName: "edit-delete"
            tooltip: frame.finished ? i18n("Dismiss") : i18n("Stop and remove")
            onClicked: frame.app.remove(frame.uid)
        }

        RowLayout {
            id: extras
            spacing: cfg.spacing
            visible: children.length > 0
        }
    }

    // measured at 100 px, scaled down to the bar width
    TextMetrics {
        id: emptyMetrics
        font.bold: true
        font.pixelSize: 100
        text: i18n("No timers running")
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: !frame.entry
        onClicked: frame.emptyClicked()
    }
}
