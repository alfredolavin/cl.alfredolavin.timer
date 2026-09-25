import QtQuick
import QtQuick.Effects

import "code/gradients.js" as Gradients
import "code/util.js" as Util

// Rounded progress bar filled with a CSS-style gradient and a centered, contrast-aware label
Item {
    id: bar

    property var stops: []
    property real progress: 0
    property string text
    property color trackColor: Qt.rgba(0, 0, 0, 0.35)
    property color borderColor: "transparent"
    property int borderWidth: 0
    // [{enabled, x, y, blur, spread, color: "#aarrggbb", inset}] like CSS box-shadow
    property var shadows: []
    // {enabled, useGradient, color, radius, strength, opacity}
    property var glow: null
    // Opaque color behind the bar, used to pick the label color
    property color baseColor: "black"
    property real radius: 4
    property int fontSize: 0
    // Fixed label color; null picks black or white for contrast
    property var labelColor: null
    property bool shadow: true
    property bool blink: false

    readonly property real clamped: Math.max(0, Math.min(1, progress))
    // Color right under the label decides black or white text
    readonly property var underLabel: clamped >= 0.5
        ? Gradients.over(Gradients.colorAt(stops, 0.5), { r: baseColor.r, g: baseColor.g, b: baseColor.b, a: 1 })
        : Gradients.over({ r: trackColor.r, g: trackColor.g, b: trackColor.b, a: trackColor.a }, { r: baseColor.r, g: baseColor.g, b: baseColor.b, a: 1 })
    readonly property bool darkText: Gradients.prefersDark(underLabel)
    readonly property bool glowOn: !!glow && glow.enabled && glow.radius > 0 && glow.opacity > 0
    // Room around the bar for outer shadows and glow
    readonly property int pad: {
        let p = 0;
        for (const sh of shadows)
            if (sh.enabled && !sh.inset)
                p = Math.max(p, sh.blur * 1.5 + Math.max(Math.abs(sh.x), Math.abs(sh.y)) + Math.max(0, sh.spread));
        if (glowOn)
            p = Math.max(p, glow.radius * 1.5);
        return Math.ceil(p) + 1;
    }
    // Only repaint when the fill moves by a whole pixel
    readonly property int fillPx: Math.round(width * clamped)

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

    function cssOf(c) {
        return Gradients.css({ r: c.r, g: c.g, b: c.b, a: c.a });
    }

    // Draws only the shadow of pathFn's shape: the shape itself is moved far away
    // and the shadow offset brings the shadow back into view.
    function shadowOnly(ctx, color, blur, ox, oy, pathFn, oddEven) {
        const far = 10000;
        ctx.save();
        ctx.shadowColor = color;
        ctx.shadowBlur = blur;
        ctx.shadowOffsetX = ox + far;
        ctx.shadowOffsetY = oy;
        ctx.translate(-far, 0);
        pathFn();
        ctx.fillRule = oddEven ? Qt.OddEvenFill : Qt.WindingFill;
        ctx.fillStyle = "black";
        ctx.fill();
        ctx.restore();
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        anchors.margins: -bar.pad
        renderStrategy: Canvas.Cooperative

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const p = bar.pad, w = bar.width, h = bar.height, r = bar.radius;
            if (w <= 0 || h <= 0)
                return;
            const fw = w * bar.clamped;
            const barPath = () => bar.rounded(ctx, p, p, w, h, r);

            // 1. outer shadows, clipped to outside the bar like CSS box-shadow
            const outer = bar.shadows.filter(sh => sh.enabled && !sh.inset);
            if (outer.length) {
                ctx.save();
                ctx.beginPath();
                ctx.rect(0, 0, width, height);
                ctx.roundedRect(p, p, w, h, Math.min(r, w / 2, h / 2), Math.min(r, w / 2, h / 2));
                ctx.fillRule = Qt.OddEvenFill;
                ctx.clip();
                for (const sh of outer) {
                    const s = sh.spread;
                    bar.shadowOnly(ctx, Util.cssOfHex(sh.color), sh.blur, sh.x, sh.y,
                                   () => bar.rounded(ctx, p - s, p - s, w + 2 * s, h + 2 * s, r + s));
                }
                ctx.restore();
            }

            // 2. background
            barPath();
            ctx.fillStyle = bar.cssOf(bar.trackColor);
            ctx.fill();

            // 3. glow around the filled part
            if (bar.glowOn && fw > 0) {
                const gc = bar.glow.useGradient ? Gradients.colorAt(bar.stops, bar.clamped)
                                                : { r: bar.glow.color.r, g: bar.glow.color.g, b: bar.glow.color.b, a: bar.glow.color.a };
                const col = Gradients.css({ r: gc.r, g: gc.g, b: gc.b, a: gc.a * bar.glow.opacity });
                for (let i = 0; i < Math.max(1, bar.glow.strength); ++i)
                    bar.shadowOnly(ctx, col, bar.glow.radius, 0, 0, () => bar.rounded(ctx, p, p, fw, h, r));
            }

            // 4. gradient fill
            if (fw > 0 && bar.stops.length) {
                const g = ctx.createLinearGradient(p, 0, p + w, 0);
                bar.stops.forEach(s => g.addColorStop(s.pos, s.css));
                ctx.save();
                barPath();
                ctx.clip();
                bar.rounded(ctx, p, p, fw, h, r);
                ctx.fillStyle = g;
                ctx.fill();
                ctx.restore();
            }

            // 5. inset shadows, clipped to the bar
            const insets = bar.shadows.filter(sh => sh.enabled && sh.inset);
            if (insets.length) {
                ctx.save();
                barPath();
                ctx.clip();
                for (const sh of insets) {
                    const s = sh.spread, m = sh.blur * 2 + Math.abs(sh.x) + Math.abs(sh.y) + 20;
                    bar.shadowOnly(ctx, Util.cssOfHex(sh.color), sh.blur, sh.x, sh.y, () => {
                        ctx.beginPath();
                        ctx.rect(p - m, p - m, w + 2 * m, h + 2 * m);
                        ctx.roundedRect(p + s, p + s, Math.max(0, w - 2 * s), Math.max(0, h - 2 * s), Math.max(0, r - s), Math.max(0, r - s));
                    }, true);
                }
                ctx.restore();
            }

            // 6. border
            if (bar.borderWidth > 0 && bar.borderColor.a > 0) {
                const bw = bar.borderWidth;
                bar.rounded(ctx, p + bw / 2, p + bw / 2, w - bw, h - bw, Math.max(0, r - bw / 2));
                ctx.lineWidth = bw;
                ctx.strokeStyle = bar.cssOf(bar.borderColor);
                ctx.stroke();
            }
        }
    }

    onFillPxChanged: canvas.requestPaint()
    onStopsChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()
    onRadiusChanged: canvas.requestPaint()
    onBorderColorChanged: canvas.requestPaint()
    onBorderWidthChanged: canvas.requestPaint()
    onShadowsChanged: canvas.requestPaint()
    onGlowChanged: canvas.requestPaint()
    onPadChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Text {
        id: label
        anchors.centerIn: parent
        // shrinks to the bar's real size minus 2 px padding on each side
        width: Math.max(1, bar.width - 4)
        height: Math.max(1, bar.height - 4)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        fontSizeMode: Text.Fit
        minimumPixelSize: 6
        text: bar.text
        visible: text.length > 0
        opacity: bar.blink ? 0.25 : 1
        color: bar.labelColor ?? (bar.darkText ? "black" : "white")
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
