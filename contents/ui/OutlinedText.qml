import QtQuick

// Text with an outline of any width: copies in outlineColor shifted to every pixel offset
// within outlineWidth are drawn under it
Item {
    id: ot

    property alias text: main.text
    property alias color: main.color
    property alias font: main.font
    property alias horizontalAlignment: main.horizontalAlignment
    property alias fontSizeMode: main.fontSizeMode
    property alias minimumPixelSize: main.minimumPixelSize
    property alias elide: main.elide
    readonly property alias contentWidth: main.contentWidth
    property color outlineColor: "black"
    property int outlineWidth: 1

    readonly property var offsets: {
        const w = Math.max(0, outlineWidth), list = [];
        for (let dx = -w; dx <= w; ++dx)
            for (let dy = -w; dy <= w; ++dy)
                if ((dx || dy) && dx * dx + dy * dy <= w * w + w)
                    list.push({ x: dx, y: dy });
        return list;
    }

    Repeater {
        model: ot.offsets
        Text {
            required property var modelData
            x: modelData.x
            y: modelData.y
            width: ot.width
            height: ot.height
            text: main.text
            color: ot.outlineColor
            font: main.font
            horizontalAlignment: main.horizontalAlignment
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: main.fontSizeMode
            minimumPixelSize: main.minimumPixelSize
            elide: main.elide
        }
    }

    Text {
        id: main
        width: ot.width
        height: ot.height
        verticalAlignment: Text.AlignVCenter
    }
}
