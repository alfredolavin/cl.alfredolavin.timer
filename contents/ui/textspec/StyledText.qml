import QtQuick
import QtQuick.Effects
import "TextSpecCore.js" as TextSpecCore
import "../gradientpicker"

// Renders text fully styled according to a TextSpec (JSON string or object):
// font family, font-weight, glow, shadow, outline width, outline color,
// background color or gradient, and inter-letter distance.
Item {
    id: root

    // Configuration spec: can be a JSON string or JS object
    property var spec: null
    property string specString: ""

    readonly property var activeSpec: {
        if (spec && typeof spec === "object") return TextSpecCore.normalize(spec);
        if (specString && specString.length > 0) return TextSpecCore.parse(specString);
        return TextSpecCore.defaultSpec();
    }

    // Direct property aliases and overrides
    property string text: ""
    property int horizontalAlignment: activeSpec.justified ? Text.AlignJustify : (activeSpec.horizontalAlignment !== undefined ? activeSpec.horizontalAlignment : Text.AlignLeft)
    property int verticalAlignment: activeSpec.verticalAlignment !== undefined ? activeSpec.verticalAlignment : Text.AlignVCenter
    property int elide: Text.ElideNone
    property int wrapMode: Text.NoWrap

    // Gradients lookup function or store (optional, fallback to smooth color)
    property var gradientStopsProvider: null

    implicitWidth: Math.ceil(bgRect.visible ? contentContainer.implicitWidth + (activeSpec.bgPadding * 2) : contentContainer.implicitWidth)
    implicitHeight: Math.ceil(bgRect.visible ? contentContainer.implicitHeight + (activeSpec.bgPadding * 2) : contentContainer.implicitHeight)

    // Background solid color layer
    Rectangle {
        id: bgRect
        anchors.fill: parent
        visible: root.activeSpec.bgMode === "color"
        radius: root.activeSpec.bgRadius
        color: root.activeSpec.bgColor
    }

    // Background gradient layer using GradientStore
    Item {
        id: bgGradItem
        anchors.fill: parent
        visible: root.activeSpec.bgMode === "gradient"

        readonly property var gradDef: GradientStore.find(root.activeSpec.bgGradient)
        readonly property var stops: gradDef ? gradDef.stops : []

        Canvas {
            id: gradCanvas
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const w = width, h = height;
                if (w <= 0 || h <= 0) return;
                const r = Math.max(0, Math.min(root.activeSpec.bgRadius, w / 2, h / 2));
                ctx.beginPath();
                ctx.roundedRect(0, 0, w, h, r, r);
                const stops = bgGradItem.stops;
                if (stops && stops.length) {
                    const g = ctx.createLinearGradient(0, 0, w, 0);
                    stops.forEach(s => g.addColorStop(Math.max(0, Math.min(1, s.pos)), s.css));
                    ctx.fillStyle = g;
                } else {
                    ctx.fillStyle = root.activeSpec.bgColor || "#1a73e8";
                }
                ctx.fill();
            }
        }
        Connections {
            target: root
            function onWidthChanged() { gradCanvas.requestPaint(); }
            function onHeightChanged() { gradCanvas.requestPaint(); }
        }
        Connections {
            target: bgGradItem
            function onStopsChanged() { gradCanvas.requestPaint(); }
        }
    }

    Item {
        id: contentContainer
        anchors.centerIn: parent
        width: Math.max(0, root.width - (bgRect.visible ? root.activeSpec.bgPadding * 2 : 0))
        height: Math.max(0, root.height - (bgRect.visible ? root.activeSpec.bgPadding * 2 : 0))
        implicitWidth: mainText.contentWidth + (activeSpec.outlineEnabled ? activeSpec.outlineWidth * 2 : 0)
        implicitHeight: mainText.contentHeight + (activeSpec.outlineEnabled ? activeSpec.outlineWidth * 2 : 0)

        // Glow layer (omnidirectional halo)
        Item {
            id: glowLayer
            anchors.fill: parent
            visible: root.activeSpec.glowEnabled
            layer.enabled: root.activeSpec.glowEnabled
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: Math.min(1.0, root.activeSpec.glowRadius / 16.0)
                blurMax: 32
                saturation: 1.5 * (root.activeSpec.glowStrength || 1.0)
            }

            Text {
                anchors.centerIn: parent
                width: mainText.width
                height: mainText.height
                text: root.text
                color: root.activeSpec.glowColor
                font: mainText.font
                horizontalAlignment: mainText.horizontalAlignment
                verticalAlignment: mainText.verticalAlignment
                elide: mainText.elide
                wrapMode: mainText.wrapMode
            }
        }

        // Multiple shadows layer (drawn behind outline and main text)
        Repeater {
            model: (root.activeSpec.shadows && root.activeSpec.shadows.length > 0) ? root.activeSpec.shadows.filter(s => s.enabled) : []
            Item {
                id: shadowItem
                required property var modelData
                anchors.fill: parent

                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: (modelData.blur || 0) > 0
                    blur: Math.min(1.0, (modelData.blur || 0) / 16.0)
                    blurMax: 32
                }

                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: modelData.x || 0
                    anchors.verticalCenterOffset: modelData.y || 0
                    width: mainText.width
                    height: mainText.height
                    text: root.text
                    color: modelData.color || "#80000000"
                    font: mainText.font
                    horizontalAlignment: mainText.horizontalAlignment
                    verticalAlignment: mainText.verticalAlignment
                    elide: mainText.elide
                    wrapMode: mainText.wrapMode
                }
            }
        }

        // Outline layer
        readonly property var outlineOffsets: {
            const w = root.activeSpec.outlineEnabled ? Math.max(0, root.activeSpec.outlineWidth) : 0;
            const list = [];
            if (w <= 0) return list;
            for (let dx = -w; dx <= w; ++dx) {
                for (let dy = -w; dy <= w; ++dy) {
                    if ((dx || dy) && dx * dx + dy * dy <= w * w + w) {
                        list.push({ x: dx, y: dy });
                    }
                }
            }
            return list;
        }

        Repeater {
            model: contentContainer.outlineOffsets
            Text {
                required property var modelData
                x: mainText.x + modelData.x
                y: mainText.y + modelData.y
                width: mainText.width
                height: mainText.height
                text: root.text
                color: root.activeSpec.outlineColor
                font: mainText.font
                horizontalAlignment: mainText.horizontalAlignment
                verticalAlignment: mainText.verticalAlignment
                elide: mainText.elide
                wrapMode: mainText.wrapMode
            }
        }

        // Main text layer (solid text fill when textMode !== "gradient")
        Text {
            id: mainText
            anchors.centerIn: parent
            width: root.width > 0 ? (root.activeSpec.bgMode !== "none" ? root.width - (root.activeSpec.bgPadding * 2) : root.width) : undefined
            text: root.text
            color: root.activeSpec.textColor
            horizontalAlignment: root.horizontalAlignment
            verticalAlignment: root.verticalAlignment
            elide: root.elide
            wrapMode: root.wrapMode
            visible: root.activeSpec.textMode !== "gradient"

            font.family: root.activeSpec.fontFamily || ""
            font.styleName: ""
            font.weight: root.activeSpec.weight
            font.pixelSize: root.activeSpec.pixelSize
            font.italic: root.activeSpec.italic
            font.letterSpacing: root.activeSpec.letterSpacing
        }

        // Dedicated text mask for gradient fill (pure clean glyph shapes, no effects, layer enabled)
        Text {
            id: textMask
            anchors.fill: mainText
            text: root.text
            color: "#ffffff"
            horizontalAlignment: mainText.horizontalAlignment
            verticalAlignment: mainText.verticalAlignment
            elide: mainText.elide
            wrapMode: mainText.wrapMode
            font: mainText.font
            visible: false
            layer.enabled: true
        }

        // Text gradient fill item (masked onto textMask shape)
        Item {
            id: textGradItem
            anchors.fill: mainText
            visible: root.activeSpec.textMode === "gradient"

            readonly property var gradDef: GradientStore.find(root.activeSpec.textGradient)
            readonly property var stops: gradDef ? gradDef.stops : []

            Canvas {
                id: textGradCanvas
                anchors.fill: parent
                renderStrategy: Canvas.Immediate
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const w = width, h = height;
                    if (w <= 0 || h <= 0) return;
                    const stops = textGradItem.stops;
                    if (stops && stops.length) {
                        const g = ctx.createLinearGradient(0, 0, w, 0);
                        stops.forEach(s => g.addColorStop(Math.max(0, Math.min(1, s.pos)), s.css));
                        ctx.fillStyle = g;
                    } else {
                        ctx.fillStyle = root.activeSpec.textColor || "#ffffffff";
                    }
                    ctx.fillRect(0, 0, w, h);
                }
                Connections {
                    target: root
                    function onWidthChanged() { textGradCanvas.requestPaint(); }
                    function onHeightChanged() { textGradCanvas.requestPaint(); }
                    function onSpecChanged() { textGradCanvas.requestPaint(); }
                    function onSpecStringChanged() { textGradCanvas.requestPaint(); }
                }
                Connections {
                    target: textGradItem
                    function onStopsChanged() { textGradCanvas.requestPaint(); }
                    function onVisibleChanged() { if (textGradItem.visible) textGradCanvas.requestPaint(); }
                }
                Component.onCompleted: requestPaint()
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: textMask
            }
        }
    }
}
