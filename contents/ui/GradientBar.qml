import QtQuick
import QtQuick.Effects

import "code/gradients.js" as Gradients

// Rounded progress bar filled with a CSS-style gradient and a centered, contrast-aware label
Item {
    id: bar

    property var stops: []
    property real progress: 0
    property string text
    property color trackColor: Qt.rgba(0, 0, 0, 0.35)
    // Opaque color behind the bar, used to pick the label color
    property color baseColor: "black"
    property real radius: 4
    property int fontSize: 0
    property bool shadow: true
    property bool blink: false

    readonly property real clamped: Math.max(0, Math.min(1, progress))
    // Color right under the label decides black or white text
    readonly property var underLabel: clamped >= 0.5
        ? Gradients.over(Gradients.colorAt(stops, 0.5), { r: baseColor.r, g: baseColor.g, b: baseColor.b, a: 1 })
        : Gradients.over({ r: trackColor.r, g: trackColor.g, b: trackColor.b, a: trackColor.a }, { r: baseColor.r, g: baseColor.g, b: baseColor.b, a: 1 })
    readonly property bool darkText: Gradients.prefersDark(underLabel)

    implicitWidth: 100
    implicitHeight: 20

    function rounded(ctx, x, y, w, h, r) {
        r = Math.max(0, Math.min(r, w / 2, h / 2));
        ctx.beginPath();
        ctx.moveTo(x + r, y);
        ctx.arcTo(x + w, y, x + w, y + h, r);
        ctx.arcTo(x + w, y + h, x, y + h, r);
        ctx.arcTo(x, y + h, x, y, r);
        ctx.arcTo(x, y, x + w, y, r);
        ctx.closePath();
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width, h = height;
            if (w <= 0 || h <= 0)
                return;
            const t = bar.trackColor;
            bar.rounded(ctx, 0, 0, w, h, bar.radius);
            ctx.fillStyle = Gradients.css({ r: t.r, g: t.g, b: t.b, a: t.a });
            ctx.fill();

            const fw = w * bar.clamped;
            if (fw <= 0 || !bar.stops.length)
                return;
            const g = ctx.createLinearGradient(0, 0, w, 0);
            bar.stops.forEach(s => g.addColorStop(s.pos, s.css));
            ctx.save();
            bar.rounded(ctx, 0, 0, w, h, bar.radius);
            ctx.clip();
            bar.rounded(ctx, 0, 0, fw, h, bar.radius);
            ctx.fillStyle = g;
            ctx.fill();
            ctx.restore();
        }
    }

    onClampedChanged: canvas.requestPaint()
    onStopsChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()
    onRadiusChanged: canvas.requestPaint()

    Text {
        id: label
        anchors.centerIn: parent
        text: bar.text
        visible: text.length > 0
        opacity: bar.blink ? 0.25 : 1
        color: bar.darkText ? "black" : "white"
        font.pixelSize: bar.fontSize > 0 ? bar.fontSize : Math.max(7, Math.round(bar.height * 0.62))
        font.bold: true
        font.features: { "tnum": 1 }

        layer.enabled: bar.shadow && visible
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: bar.darkText ? "white" : "black"
            shadowOpacity: 0.9
            shadowBlur: 0.35
            shadowHorizontalOffset: 1
            shadowVerticalOffset: 1
            blurMax: 8
        }
    }
}
