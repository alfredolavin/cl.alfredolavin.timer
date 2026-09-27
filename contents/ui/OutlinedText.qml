import QtQuick

// Text with a 1 px outline: copies in outlineColor shifted to the 8 surrounding pixels are drawn under it
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
    // fully transparent: no outline (and no copies)
    property color outlineColor: "black"

    readonly property var offsets: [{ x: -1, y: -1 }, { x: -1, y: 0 }, { x: -1, y: 1 }, { x: 0, y: -1 },
                                    { x: 0, y: 1 }, { x: 1, y: -1 }, { x: 1, y: 0 }, { x: 1, y: 1 }]

    Repeater {
        model: ot.outlineColor.a > 0 ? ot.offsets : []
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
