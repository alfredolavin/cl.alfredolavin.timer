import QtQuick

import "code/gradients.js" as Gradients

// A rounded strip painted with compiled gradient stops (Gradients.compile(def).stops), left to right
Canvas {
    id: strip

    property var stops: []
    property real radius: 4

    implicitWidth: 100
    implicitHeight: 20

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (!stops.length)
            return;
        const r = Math.max(0, Math.min(radius, width / 2, height / 2));
        ctx.beginPath();
        ctx.roundedRect(0, 0, width, height, r, r);
        ctx.clip();
        const g = ctx.createLinearGradient(0, 0, width, 0);
        stops.forEach(s => g.addColorStop(Math.max(0, Math.min(1, s.pos)), s.css));
        ctx.fillStyle = g;
        ctx.fillRect(0, 0, width, height);
    }

    onStopsChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onRadiusChanged: requestPaint()
}
