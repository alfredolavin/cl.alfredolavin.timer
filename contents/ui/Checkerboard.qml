import QtQuick

// Light/dark squares shown behind translucent colors
Canvas {
    id: board

    property int cell: 5
    property color light: "#e6e6e6"
    property color dark: "#a8a8a8"
    property real radius: 0

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.beginPath();
        ctx.roundedRect(0, 0, width, height, radius, radius);
        ctx.clip();
        ctx.fillStyle = light.toString();
        ctx.fillRect(0, 0, width, height);
        ctx.fillStyle = dark.toString();
        for (let y = 0; y < height; y += cell)
            for (let x = (y / cell) % 2 ? cell : 0; x < width; x += 2 * cell)
                ctx.fillRect(x, y, cell, cell);
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onRadiusChanged: requestPaint()
}
