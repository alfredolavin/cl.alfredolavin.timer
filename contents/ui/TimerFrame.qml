import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

import "bundledicons"
import "code/util.js" as Util
import "common"
import "gradientpicker/code/gradients.js" as Gradients
import "code/colorspec.js" as ColorSpec
import "textspec/TextSpecCore.js" as TextSpecCore

// Rounded frame: icon | name + gradient bar | play/pause | delete | extra buttons
Rectangle {
    id: frame

    // the Plasma color scheme, for the "System" source of the configurable colors
    SystemTheme {
        id: sys
    }

    property var app
    property string uid
    default property alias extraButtons: extras.data
    signal emptyClicked
    // When true the progress bar grows to fill the available width
    property bool stretch: false
    // The panel's frame follows the Panel options of Appearance; `revealed` is true while it is hovered
    property bool panelMode: false
    property bool revealed: true

    readonly property var cfg: Plasmoid.configuration
    readonly property var entry: uid ? app.entry(uid) : null
    readonly property var gradient: app.gradientFor(entry ? entry.gradient : "")
    readonly property int inset: cfg.borderWidth + cfg.padding
    readonly property int inner: Math.max(8, height - 2 * inset)
    // Buttons take at most 85% of the available height
    readonly property int buttonSize: Math.max(8, Math.min(cfg.buttonIconSize, Math.round((inner - 2 * (cfg.buttonBorderWidth + 1)) * 0.85)))
    readonly property bool finished: !!entry && entry.finished
    // everything shown (buttons, and the frame unless the bar is the widget): always outside the panel,
    // and in it unless it is set to reveal them on hover; a finished timer shows its dismiss button
    readonly property bool showAll: !panelMode || !cfg.revealOnHover || revealed || finished
    // the bar is the whole widget, with the icon and buttons inside it
    readonly property bool container: panelMode && (cfg.panelLayout === "bar" || !showAll)
    readonly property int barHeight: container ? height : Math.round(inner * cfg.barHeightPercent / 100)
    // "Time is up" text drawn over the bar, e.g. "Tea Ready!! (3m)"
    readonly property bool isAlarm: !!entry && entry.kind === "alarm"
    readonly property string finishedText: finished ? Util.finishedMessage(entry) + " ("
        + (isAlarm ? Util.formatClock(entry.at) : Util.formatDuration(entry.duration)) + ")" : ""
    // with no timer, "No timers running" is centered in the bar, shrunk to fit its width
    readonly property int emptyFontSize: Math.max(6, Math.min(Math.round(barHeight * 0.62),
        Math.floor(100 * (barArea.width - Math.max(4, barHeight / 2)) / Math.max(1, emptyMetrics.width))))
    // the bar grows with the frame: in the popup (stretch) or when set to fill the available width
    readonly property bool fillBar: stretch || cfg.barFillWidth
    // width of the bar, or its smallest width while it fills
    readonly property int barAreaWidth: cfg.barFillWidth ? Kirigami.Units.gridUnit * 3 : cfg.barWidth
    // Opaque color of the frame as seen on the panel, for contrast decisions
    readonly property var baseColor: Gradients.over({ r: color.r, g: color.g, b: color.b, a: color.a },
        { r: Kirigami.Theme.backgroundColor.r, g: Kirigami.Theme.backgroundColor.g, b: Kirigami.Theme.backgroundColor.b, a: 1 })
    readonly property color contrastColor: Gradients.prefersDark(baseColor) ? "#1b1b1b" : "#f5f5f5"
    // Icon over the bar (the bar is the widget): the fill sweeps under it, so its color is mixed between the best
    // contrast against the empty track and against the gradient under the icon, by how much of it the fill covers
    readonly property real iconCovered: iconItem.width > 0 && width > 0
        ? Math.max(0, Math.min(1, (width * fill - row.x) / iconItem.width)) : 0
    readonly property color iconContrastColor: {
        const track = spec(cfg.trackColor);
        const g = Gradients.colorAt(gradient.stops, Math.max(0, Math.min(1, (row.x + iconItem.width / 2) / Math.max(1, width))));
        const onTrack = Gradients.over({ r: track.r, g: track.g, b: track.b, a: track.a }, baseColor);
        const onFill = Gradients.over(g, baseColor);
        const a = Gradients.prefersDark(onTrack) ? 0.11 : 0.96;
        const b = Gradients.prefersDark(onFill) ? 0.11 : 0.96;
        const v = a + (b - a) * iconCovered;
        return Qt.rgba(v, v, v, 1);
    }

    implicitWidth: row.implicitWidth + 2 * inset
    implicitHeight: Math.max(cfg.iconSize, cfg.buttonIconSize + 2 * (cfg.buttonBorderWidth + 1)) + 2 * inset
    radius: cfg.cornerRadius
    border.width: container ? 0 : cfg.borderWidth
    readonly property real fill: entry ? app.progressOf(entry) : 0
    // A configurable color (code/colorspec.js) resolved with this frame's gradient and fill
    function spec(str) {
        const c = ColorSpec.resolveString(str, gradient.stops, fill, sys.map);
        return Qt.rgba(c.r, c.g, c.b, c.a);
    }
    // a color property only notifies real changes, so the bar isn't repainted on every tick for it
    readonly property color glowColor: spec(ColorSpec.glowSpec(cfg.barGlowColor, cfg))
    readonly property color markerColor: spec(cfg.markerColor)
    // frame outline (also the buttons' borders) and background
    readonly property color outlineColor: spec(ColorSpec.frameSpec("outline", cfg.frameOutlineColor, cfg))

    border.color: finished && app.blink ? Kirigami.Theme.negativeTextColor : outlineColor
    color: container ? "transparent" : spec(ColorSpec.frameSpec("background", cfg.frameBackgroundColor, cfg))

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: frame.inset
        spacing: cfg.spacing

        SvgIcon {
            id: iconItem
            readonly property int px: Math.min(cfg.iconSize, frame.inner)
            Layout.preferredWidth: px
            Layout.preferredHeight: px
            Layout.alignment: Qt.AlignVCenter
            hex: frame.entry ? frame.entry.icon : "f051b"
            // over the bar it fades between black and white as the fill passes behind it
            color: !cfg.useThemeIconColor ? frame.spec(cfg.iconColor) : frame.container ? frame.iconContrastColor : frame.contrastColor
            opacity: frame.finished && frame.app.blink ? 0.3 : 1
        }

        Item {
            id: barArea
            // as the widget, the bar is drawn under the icon and buttons
            z: frame.container ? -1 : 0
            Layout.fillHeight: true
            Layout.fillWidth: frame.fillBar
            Layout.preferredWidth: frame.barAreaWidth
            Layout.maximumWidth: frame.fillBar ? Number.POSITIVE_INFINITY : frame.barAreaWidth

            // name on the left inside the bar, time on the right
            GradientBar {
                // its own place in the row, or the whole frame when the bar is the widget
                x: frame.container ? -(row.x + barArea.x) : 0
                y: frame.container ? -(row.y + barArea.y) : Math.round((barArea.height - height) / 2)
                width: frame.container ? frame.width : barArea.width
                height: frame.container ? frame.height : frame.barHeight
                // labels start after the icon and end before the buttons (or at the edge while they are hidden)
                contentLeft: frame.container ? row.x + barArea.x : 0
                contentRight: frame.container && frame.showAll ? frame.width - (row.x + barArea.x + barArea.width) : 0
                stops: frame.gradient.stops
                progress: frame.fill
                text: !frame.entry ? i18n("No timers running")
                    : frame.finished ? frame.finishedText
                    : frame.entry.showElapsed ? "+" + Util.formatTime(frame.app.elapsedOf(frame.entry))
                    : Util.formatTime(frame.app.remainingOf(frame.entry))
                leftText: frame.entry && !frame.finished ? frame.entry.name : ""
                clickableTime: !!frame.entry && !frame.finished
                onTimeClicked: frame.app.toggleTimeDisplay(frame.uid)
                nameSpec: cfg.nameStyle ? TextSpecCore.parse(cfg.nameStyle) : null
                timeSpec: cfg.timeStyle ? TextSpecCore.parse(cfg.timeStyle) : null
                finishedSpec: cfg.finishedStyle ? TextSpecCore.parse(cfg.finishedStyle) : null
                finished: frame.finished
                leftFontSize: cfg.nameFontSize
                fontWeight: cfg.barFontWeight
                textColor: frame.spec(cfg.barTextColor)
                outlineColor: frame.spec(cfg.barTextOutlineColor)
                outlineWidth: cfg.barTextOutlineWidth
                trackColor: frame.spec(cfg.trackColor)
                borderColor: frame.spec(cfg.barBorderColor)
                borderWidth: cfg.barBorderWidth
                shadows: TextSpecCore.parseShadows(cfg.barShadows)
                glow: ({ enabled: cfg.glowEnabled, color: frame.glowColor,
                         radius: cfg.glowRadius, strength: cfg.glowStrength, opacity: cfg.glowOpacity / 100 })
                radius: frame.container ? cfg.cornerRadius : cfg.barRadius
                // only while a timer counts down
                marker: frame.entry && !frame.finished
                    ? { line: cfg.markerLine, lineWidth: cfg.markerLineWidth, circle: cfg.markerCircle, circleSize: cfg.markerCircleSize,
                        circlePosition: cfg.markerCirclePosition, color: frame.markerColor, blink: cfg.markerBlink,
                        period: cfg.markerBlinkPeriod }
                    : null
                // when finished: bold text at 95% of the bar height in the configured color
                fontSize: !frame.entry ? frame.emptyFontSize
                        : frame.finished ? Math.max(6, Math.round(frame.barHeight * 0.95)) : cfg.timeFontSize
                labelColor: frame.finished ? frame.spec(cfg.finishedTextColor) : null
                shadow: cfg.textShadow
                blink: frame.finished && frame.app.blink
                opacity: frame.entry && frame.entry.paused ? 0.6 : 1
            }
        }

        IconButton {
            // an alarm is tied to a time of day, so it is not paused
            visible: !!frame.entry && !frame.finished && !frame.isAlarm
            size: frame.buttonSize
            opacity: frame.showAll ? 1 : 0
            enabled: frame.showAll
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
            borderColor: frame.outlineColor
            iconName: !frame.entry ? "" : frame.entry.paused ? "media-playback-start" : "media-playback-pause"
            tooltip: !frame.entry ? "" : frame.entry.paused ? i18n("Resume") : i18n("Pause")
            onClicked: frame.app.togglePause(frame.uid)
        }

        IconButton {
            visible: !!frame.entry
            size: frame.buttonSize
            opacity: frame.showAll ? 1 : 0
            enabled: frame.showAll
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
            borderColor: frame.outlineColor
            iconName: "edit-delete"
            tooltip: frame.finished ? i18n("Dismiss") : i18n("Stop and remove")
            onClicked: frame.app.remove(frame.uid)
        }

        RowLayout {
            id: extras
            spacing: cfg.spacing
            visible: children.length > 0
            opacity: frame.showAll ? 1 : 0
            enabled: frame.showAll
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
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
