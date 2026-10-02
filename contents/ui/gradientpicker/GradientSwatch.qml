import QtQuick

// A small rounded square filled with a gradient (compiled stops) and a soft drop shadow. The shadow is painted
// outside the item's box, so `width` x `height` is the size of the visible square.
Item {
    id: sw

    property var stops: []
    // CSS angle (180 = top to bottom)
    property real angle: 135
    property real radius: 6
    property bool shadow: true
    property color shadowColor: Qt.rgba(0, 0, 0, 0.35)
    property real shadowBlur: 3
    property real shadowOffset: 1
    property color outlineColor: Qt.rgba(1, 1, 1, 0.25)

    readonly property real room: shadow ? Math.ceil(shadowBlur * 1.5 + shadowOffset) + 1 : 1

    implicitWidth: 28
    implicitHeight: 28

    Canvas {
        id: canvas
        anchors.fill: parent
        anchors.margins: -sw.room

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const o = sw.room, w = sw.width, h = sw.height;
            if (w <= 0 || h <= 0)
                return;
            const r = Math.max(0, Math.min(sw.radius, w / 2, h / 2));
            if (sw.shadow) {
                ctx.save();
                ctx.shadowColor = sw.shadowColor.toString();
                ctx.shadowBlur = sw.shadowBlur;
                ctx.shadowOffsetX = 0;
                ctx.shadowOffsetY = sw.shadowOffset;
                ctx.beginPath();
                ctx.roundedRect(o, o, w, h, r, r);
                ctx.fillStyle = "#000";
                ctx.fill();
                ctx.restore();
                // only the halo stays: translucent stops must not show the shadow body through them
                ctx.save();
                ctx.globalCompositeOperation = "destination-out";
                ctx.beginPath();
                ctx.roundedRect(o, o, w, h, r, r);
                ctx.fillStyle = "#000";
                ctx.fill();
                ctx.restore();
            }
            if (!sw.stops.length)
                return;
            const a = sw.angle * Math.PI / 180;
            const dx = Math.sin(a), dy = -Math.cos(a);
            const len = Math.abs(w * dx) + Math.abs(h * dy);
            const cx = o + w / 2, cy = o + h / 2;
            const g = ctx.createLinearGradient(cx - dx * len / 2, cy - dy * len / 2, cx + dx * len / 2, cy + dy * len / 2);
            sw.stops.forEach(s => g.addColorStop(Math.max(0, Math.min(1, s.pos)), s.css));
            ctx.beginPath();
            ctx.roundedRect(o, o, w, h, r, r);
            ctx.fillStyle = g;
            ctx.fill();
            ctx.lineWidth = 1;
            ctx.strokeStyle = sw.outlineColor.toString();
            ctx.beginPath();
            ctx.roundedRect(o + 0.5, o + 0.5, w - 1, h - 1, Math.max(0, r - 0.5), Math.max(0, r - 0.5));
            ctx.stroke();
        }
    }

    onStopsChanged: canvas.requestPaint()
    onAngleChanged: canvas.requestPaint()
    onRadiusChanged: canvas.requestPaint()
    onShadowChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
}
