import QtQuick
import QtQuick.Layouts
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

    readonly property var cfg: Plasmoid.configuration
    readonly property var entry: uid ? app.entry(uid) : null
    readonly property var gradient: app.gradientFor(entry ? entry.gradient : "")
    readonly property int inset: cfg.borderWidth + cfg.padding
    readonly property int inner: Math.max(8, height - 2 * inset)
    readonly property int buttonSize: Math.max(8, Math.min(cfg.buttonIconSize, inner - 2 * (cfg.buttonBorderWidth + 1)))
    readonly property bool finished: !!entry && entry.finished
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

        Text {
            readonly property int px: Math.min(cfg.iconSize, frame.inner)
            Layout.preferredWidth: px
            Layout.preferredHeight: px
            Layout.alignment: Qt.AlignVCenter
            text: Util.glyph(frame.entry ? frame.entry.icon : "f051b")
            font.family: frame.app.iconFont
            font.pixelSize: px
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: cfg.useThemeIconColor ? frame.contrastColor : cfg.iconColor
            opacity: frame.finished && frame.app.blink ? 0.3 : 1
        }

        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: cfg.barWidth
            Layout.maximumWidth: cfg.barWidth
            spacing: 0

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: frame.entry ? frame.entry.name : i18n("No timers running")
                color: frame.contrastColor
                font.pixelSize: cfg.nameFontSize
                font.bold: cfg.nameBold
                fontSizeMode: Text.VerticalFit
                minimumPixelSize: 5
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            GradientBar {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(frame.inner * cfg.barHeightPercent / 100)
                stops: frame.gradient.stops
                progress: frame.entry ? frame.app.progressOf(frame.entry) : 0
                text: !frame.entry ? "--:--"
                    : frame.finished ? i18n("Done!")
                    : Util.formatTime(frame.app.remainingOf(frame.entry))
                trackColor: cfg.trackColor
                baseColor: Qt.rgba(frame.baseColor.r, frame.baseColor.g, frame.baseColor.b, 1)
                radius: cfg.barRadius
                fontSize: cfg.timeFontSize
                shadow: cfg.textShadow
                blink: frame.finished && frame.app.blink
                opacity: frame.entry && frame.entry.paused ? 0.6 : 1
            }
        }

        IconButton {
            visible: !!frame.entry
            size: frame.buttonSize
            borderColor: cfg.borderColor
            iconName: !frame.entry ? "" : frame.finished ? "view-refresh"
                    : frame.entry.paused ? "media-playback-start" : "media-playback-pause"
            tooltip: !frame.entry ? "" : frame.finished ? i18n("Restart") : frame.entry.paused ? i18n("Resume") : i18n("Pause")
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

    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: !frame.entry
        onClicked: frame.emptyClicked()
    }
}
