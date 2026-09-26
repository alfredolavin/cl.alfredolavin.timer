import QtQuick
import QtQuick.Effects

import "code/gradients.js" as Gradients
import "code/util.js" as Util

// Rounded progress bar filled with a CSS-style gradient and outlined Rubik labels:
// `text` centered, or right-aligned when `leftText` is shown on the left
Item {
    id: bar

    property var stops: []
    property real progress: 0
    property string text
    property string leftText
    property int leftFontSize: 9
    property color trackColor: Qt.rgba(0, 0, 0, 0.35)
    property color borderColor: "transparent"
    property int borderWidth: 0
    // [{enabled, x, y, blur, spread, color: "#aarrggbb", inset}] like CSS box-shadow
    property var shadows: []
    // {enabled, useGradient, color, radius, strength, opacity}
    property var glow: null
    property real radius: 4
    property int fontSize: 0
    property int fontWeight: 800
    property color textColor: "white"
    property color outlineColor: "black"
    property int outlineWidth: 1
    // Color of `text` only, overriding textColor (e.g. the "time is up" message)
    property var labelColor: null
    property bool shadow: true
    property bool blink: false

    readonly property real clamped: Math.max(0, Math.min(1, progress))
    readonly property bool split: leftText.length > 0
    // Horizontal padding of the labels, clear of the rounded ends and fitting the outline
    readonly property real inset: 2 + outlineWidth + Math.min(radius, height / 2) / 2
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

    // Bundled Rubik (variable weight, Latin only); FontLoader caches it, so every bar shares one copy
    FontLoader {
        id: rubik
        source: Qt.resolvedUrl("../fonts/Rubik.ttf")
    }

    readonly property string fontFamily: rubik.font.family

    // inline components can't see this file's ids, so the bar is passed in as `b`
    component BarText: OutlinedText {
        required property Item b
        anchors.verticalCenter: parent.verticalCenter
        // the outline stays inside the 2 px padding too
        height: Math.max(1, b.height - 4 - 2 * b.outlineWidth)
        minimumPixelSize: 6
        opacity: b.blink ? 0.25 : 1
        outlineColor: b.outlineColor
        outlineWidth: b.outlineWidth
        font.family: b.fontFamily
        font.weight: b.fontWeight
        font.variableAxes: { "wght": b.fontWeight }

        layer.enabled: b.shadow && visible
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "black"
            shadowOpacity: 0.9
            shadowBlur: 0.35
            shadowHorizontalOffset: 1
            shadowVerticalOffset: 1
            blurMax: 8
        }
    }

    BarText {
        id: nameLabel
        b: bar
        anchors.left: parent.left
        anchors.leftMargin: bar.inset
        // whatever the time on the right leaves free
        width: Math.max(0, bar.width - 2 * bar.inset - (label.visible ? label.contentWidth + bar.inset : 0))
        fontSizeMode: Text.VerticalFit
        elide: Text.ElideRight
        text: bar.leftText
        visible: bar.split && width > 0
        color: bar.textColor
        font.pixelSize: bar.leftFontSize
    }

    BarText {
        id: label
        b: bar
        anchors.horizontalCenter: parent.horizontalCenter
        // shrinks to the bar's real size minus the padding on each side (2 px when centered)
        width: Math.max(1, bar.width - (bar.split ? 2 * bar.inset : 4 + 2 * bar.outlineWidth))
        horizontalAlignment: bar.split ? Text.AlignRight : Text.AlignHCenter
        fontSizeMode: Text.Fit
        text: bar.text
        visible: text.length > 0
        color: bar.labelColor ?? bar.textColor
        font.pixelSize: bar.fontSize > 0 ? bar.fontSize : Math.max(7, Math.round(bar.height * 0.62))
        font.features: { "tnum": 1 }
    }
}
