import QtQuick

// Light/dark gray checkered background for transparent / translucent previews
Canvas {
    id: board

    property int cell: 6
    property color light: "#d0d0d0"
    property color dark: "#9c9c9c"
    property real radius: 0

    renderStrategy: Canvas.Cooperative

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (radius > 0) {
            ctx.beginPath();
            ctx.roundedRect(0, 0, width, height, radius, radius);
            ctx.clip();
        }
        ctx.fillStyle = light.toString();
        ctx.fillRect(0, 0, width, height);
        ctx.fillStyle = dark.toString();
        for (let y = 0; y < height; y += cell) {
            for (let x = (Math.floor(y / cell) % 2) ? cell : 0; x < width; x += 2 * cell) {
                ctx.fillRect(x, y, cell, cell);
            }
        }
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onRadiusChanged: requestPaint()
}
