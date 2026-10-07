import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami

import "TextSpecCore.js" as TextSpecCore
import "../colorspec"
import "../gradientpicker"

// Shared RichTextEdit control:
// Displays simply as sample text "Leo" on gray checkerboard with soft emboss shadow,
// moves 1px left and 1px top on hover when not pressed.
// On click, opens a popup with horizontal layout:
// - Left: Box with bigger sample text and 4 selectable background swatches (custom, black, white, checkers)
// - Right: Tabbed view ("Font", "Background", "Effects", "Align") with standard Inkscape-like icons.
Item {
    id: root

    property string value: ""
    property string sampleText: "Leo"
    property string dialogTitle: i18n("Configure Text Style")
    property var gradients: []

    signal edited(string value)

    property var currentSpec: TextSpecCore.parse(value)

    onValueChanged: {
        currentSpec = TextSpecCore.parse(value);
    }

    function setSpecProp(prop, val) {
        const copy = JSON.parse(JSON.stringify(currentSpec));
        copy[prop] = val;
        currentSpec = copy;
        const jsonStr = JSON.stringify(copy);
        value = jsonStr;
        edited(jsonStr);
    }

    implicitWidth: Math.max(84, sampleFrame.implicitWidth + 16)
    implicitHeight: Math.max(34, sampleFrame.implicitHeight + 10)

    // Soft emboss shadow behind the control
    Rectangle {
        id: outerEmbossShadow
        anchors.fill: sampleFrame
        anchors.margins: -1
        radius: 6
        color: "transparent"
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#40000000"
            shadowBlur: 0.4
            shadowHorizontalOffset: 1
            shadowVerticalOffset: 2
        }
    }

    // Main clickable preview frame
    Item {
        id: sampleFrame
        anchors.centerIn: parent

        // Moves 1 pixel left and 1 pixel top on mouse hover when no button is pressed
        x: (mouseArea.containsMouse && !mouseArea.pressed) ? -1 : 0
        y: (mouseArea.containsMouse && !mouseArea.pressed) ? -1 : 0
        Behavior on x { NumberAnimation { duration: 60 } }
        Behavior on y { NumberAnimation { duration: 60 } }

        implicitWidth: Math.max(72, innerText.implicitWidth + 24)
        implicitHeight: Math.max(28, innerText.implicitHeight + 10)
        width: implicitWidth
        height: implicitHeight

        // Gray chequers board background
        Checkerboard {
            anchors.fill: parent
            radius: 5
            cell: 5
            light: "#d5d5d5"
            dark: "#a6a6a6"
        }

        // Soft emboss border: top/left highlight, bottom/right soft shadow
        Rectangle {
            anchors.fill: parent
            radius: 5
            color: "transparent"
            border.width: 1
            border.color: mouseArea.containsMouse ? "#80ffffff" : "#40ffffff"

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: "#50000000"
            }
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: 1
                color: "#50000000"
            }
        }

        // Sample text "Leo" with all configurations applied
        StyledText {
            id: innerText
            anchors.centerIn: parent
            text: root.sampleText || "Leo"
            spec: root.currentSpec
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.open()
        }
    }

    // Reusable PropertyRow with standard Inkscape-like icon at the left
    component PropertyRow: RowLayout {
        id: pRow
        property string iconName: ""
        property string labelText: ""
        property bool isSection: false
        default property alias content: innerContent.data

        spacing: Kirigami.Units.smallSpacing
        Layout.fillWidth: true

        Kirigami.Icon {
            source: pRow.iconName
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            opacity: 0.85
            visible: pRow.iconName.length > 0
        }

        QQC2.Label {
            text: pRow.labelText
            Layout.preferredWidth: Kirigami.Units.gridUnit * 7.5
            elide: Text.ElideRight
            font.bold: pRow.isSection
            visible: pRow.labelText.length > 0
        }

        RowLayout {
            id: innerContent
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
        }
    }

    // Modal popup with horizontal layout
    QQC2.Popup {
        id: popup
        parent: QQC2.Overlay.overlay
        modal: true
        focus: true
        dim: true
        closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutsideParent

        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: Math.min(parent.width - 24, 780)
        height: Math.min(parent.height - 24, 540)

        background: Rectangle {
            color: Kirigami.Theme.backgroundColor
            radius: Kirigami.Units.smallSpacing
            border.color: Kirigami.ColorUtils.tintWithAlpha(color, Kirigami.Theme.textColor, 0.25)
            border.width: 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#70000000"
                shadowBlur: 0.6
                shadowVerticalOffset: 6
            }
        }

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            // Header title
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "preferences-desktop-font"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                }

                QQC2.Label {
                    text: root.dialogTitle
                    font.bold: true
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize + 1
                    Layout.fillWidth: true
                }

                QQC2.ToolButton {
                    icon.name: "window-close"
                    QQC2.ToolTip.text: i18n("Close")
                    onClicked: popup.close()
                }
            }

            Kirigami.Separator { Layout.fillWidth: true }

            // Main horizontal layout: Left preview box + Right tabbed view
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Kirigami.Units.largeSpacing

                // ==========================================
                // LEFT: BOX WITH BIGGER SAMPLE TEXT
                // ==========================================
                Item {
                    id: leftBoxContainer
                    Layout.preferredWidth: 260
                    Layout.minimumWidth: 230
                    Layout.fillHeight: true

                    property string previewBgMode: "custom" // "custom", "black", "white", "chekers"

                    // Box frame
                    Rectangle {
                        id: previewBox
                        anchors.fill: parent
                        radius: 6
                        clip: true
                        border.color: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.2)
                        border.width: 1

                        // Background layers based on previewBgMode
                        // 1. Checkers background
                        Checkerboard {
                            anchors.fill: parent
                            radius: 6
                            cell: 6
                            light: "#d5d5d5"
                            dark: "#9c9c9c"
                            visible: leftBoxContainer.previewBgMode === "chekers"
                        }

                        // 2. Black background
                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: "#000000"
                            visible: leftBoxContainer.previewBgMode === "black"
                        }

                        // 3. White background
                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: "#ffffff"
                            visible: leftBoxContainer.previewBgMode === "white"
                        }

                        // 4. Custom background (reflecting spec's bgMode or neutral backdrop)
                        Item {
                            anchors.fill: parent
                            visible: leftBoxContainer.previewBgMode === "custom"

                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                color: root.currentSpec.bgMode === "color" ? root.currentSpec.bgColor : "#1e2026"
                                visible: root.currentSpec.bgMode !== "gradient"
                            }

                            Canvas {
                                id: customGradCanvas
                                anchors.fill: parent
                                visible: root.currentSpec.bgMode === "gradient"
                                onPaint: {
                                    const ctx = getContext("2d");
                                    ctx.reset();
                                    ctx.beginPath();
                                    ctx.roundedRect(0, 0, width, height, 6, 6);
                                    ctx.clip();
                                    const gradDef = GradientStore.find(root.currentSpec.bgGradient);
                                    const stops = gradDef ? gradDef.stops : [];
                                    if (stops && stops.length) {
                                        const g = ctx.createLinearGradient(0, 0, width, 0);
                                        stops.forEach(s => g.addColorStop(Math.max(0, Math.min(1, s.pos)), s.css));
                                        ctx.fillStyle = g;
                                    } else {
                                        ctx.fillStyle = root.currentSpec.bgColor || "#1a73e8";
                                    }
                                    ctx.fillRect(0, 0, width, height);
                                }
                                Connections {
                                    target: root
                                    function onValueChanged() { customGradCanvas.requestPaint(); }
                                }
                            }
                        }

                        // Bigger sample text with all styles applied
                        StyledText {
                            id: bigSampleText
                            anchors.centerIn: parent
                            text: root.sampleText || "Leo"
                            spec: {
                                const s = JSON.parse(JSON.stringify(root.currentSpec));
                                s.pixelSize = Math.max(26, Math.round((root.currentSpec.pixelSize || 12) * 1.6));
                                return s;
                            }
                        }

                        // Bottom right corner: Small squares to select preview background
                        Row {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 8
                            spacing: 6

                            // Small Square: Custom
                            Rectangle {
                                width: 22
                                height: 22
                                radius: 3
                                border.width: leftBoxContainer.previewBgMode === "custom" ? 2 : 1
                                border.color: leftBoxContainer.previewBgMode === "custom" ? Kirigami.Theme.highlightColor : "#60ffffff"
                                color: "#2d3139"

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: 14
                                    height: 14
                                    source: "fill-color"
                                }

                                QQC2.ToolTip.text: i18n("Custom background")
                                QQC2.ToolTip.visible: customMa.containsMouse

                                MouseArea {
                                    id: customMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: leftBoxContainer.previewBgMode = "custom"
                                }
                            }

                            // Small Square: Black
                            Rectangle {
                                width: 22
                                height: 22
                                radius: 3
                                color: "#000000"
                                border.width: leftBoxContainer.previewBgMode === "black" ? 2 : 1
                                border.color: leftBoxContainer.previewBgMode === "black" ? Kirigami.Theme.highlightColor : "#60ffffff"

                                QQC2.ToolTip.text: i18n("Black background")
                                QQC2.ToolTip.visible: blackMa.containsMouse

                                MouseArea {
                                    id: blackMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: leftBoxContainer.previewBgMode = "black"
                                }
                            }

                            // Small Square: White
                            Rectangle {
                                width: 22
                                height: 22
                                radius: 3
                                color: "#ffffff"
                                border.width: leftBoxContainer.previewBgMode === "white" ? 2 : 1
                                border.color: leftBoxContainer.previewBgMode === "white" ? Kirigami.Theme.highlightColor : "#40000000"

                                QQC2.ToolTip.text: i18n("White background")
                                QQC2.ToolTip.visible: whiteMa.containsMouse

                                MouseArea {
                                    id: whiteMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: leftBoxContainer.previewBgMode = "white"
                                }
                            }

                            // Small Square: Checkers
                            Rectangle {
                                width: 22
                                height: 22
                                radius: 3
                                clip: true
                                border.width: leftBoxContainer.previewBgMode === "chekers" ? 2 : 1
                                border.color: leftBoxContainer.previewBgMode === "chekers" ? Kirigami.Theme.highlightColor : "#60ffffff"

                                Checkerboard {
                                    anchors.fill: parent
                                    cell: 3
                                    radius: 3
                                }

                                QQC2.ToolTip.text: i18n("Checkers background")
                                QQC2.ToolTip.visible: checkMa.containsMouse

                                MouseArea {
                                    id: checkMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: leftBoxContainer.previewBgMode = "chekers"
                                }
                            }
                        }
                    }
                }

                // ==========================================
                // RIGHT: TABBED VIEW
                // ==========================================
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.TabBar {
                        id: tabBar
                        Layout.fillWidth: true

                        QQC2.TabButton {
                            text: i18n("Font")
                            icon.name: "preferences-desktop-font"
                        }
                        QQC2.TabButton {
                            text: i18n("Filling")
                            icon.name: "format-fill-color"
                        }
                        QQC2.TabButton {
                            text: i18n("Effects")
                            icon.name: "draw-effects"
                        }
                        QQC2.TabButton {
                            text: i18n("Align")
                            icon.name: "format-justify-left"
                        }
                    }

                    QQC2.ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: -1

                        StackLayout {
                            id: stack
                            currentIndex: tabBar.currentIndex
                            width: parent.width

                            // ------------------------------------------
                            // TAB 1: FONT
                            // ------------------------------------------
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.mediumSpacing

                                // Font Family
                                PropertyRow {
                                    iconName: "preferences-desktop-font"
                                    labelText: i18n("Font family:")

                                    QQC2.ComboBox {
                                        Layout.fillWidth: true
                                        model: ["(System Default)"].concat(Qt.fontFamilies())
                                        currentIndex: {
                                            const fam = root.currentSpec.fontFamily;
                                            if (!fam) return 0;
                                            const idx = model.indexOf(fam);
                                            return idx >= 0 ? idx : 0;
                                        }
                                        onActivated: idx => {
                                            root.setSpecProp("fontFamily", idx === 0 ? "" : model[idx]);
                                        }
                                    }
                                }

                                // Font Size
                                PropertyRow {
                                    iconName: "format-font-size-more"
                                    labelText: i18n("Font size:")

                                    QQC2.SpinBox {
                                        from: 6
                                        to: 140
                                        editable: true
                                        value: root.currentSpec.pixelSize || 12
                                        onValueModified: root.setSpecProp("pixelSize", value)
                                        textFromValue: v => v + " px"
                                        valueFromText: t => parseInt(t) || 12
                                    }
                                }

                                // Font Weight
                                PropertyRow {
                                    iconName: "format-text-bold"
                                    labelText: i18n("Font weight:")

                                    QQC2.ComboBox {
                                        id: weightCombo
                                        Layout.fillWidth: true
                                        model: TextSpecCore.weights.map(w => w.name)
                                        currentIndex: {
                                            const w = root.currentSpec.weight;
                                            for (let i = 0; i < TextSpecCore.weights.length; ++i) {
                                                if (TextSpecCore.weights[i].value === w) return i;
                                            }
                                            return 3;
                                        }
                                        onActivated: idx => {
                                            root.setSpecProp("weight", TextSpecCore.weights[idx].value);
                                        }
                                        Connections {
                                            target: root
                                            function onCurrentSpecChanged() {
                                                const w = root.currentSpec.weight;
                                                for (let i = 0; i < TextSpecCore.weights.length; ++i) {
                                                    if (TextSpecCore.weights[i].value === w) {
                                                        weightCombo.currentIndex = i;
                                                        return;
                                                    }
                                                }
                                                weightCombo.currentIndex = 3;
                                            }
                                        }
                                    }
                                }

                                // Letter Distance to Each Other
                                PropertyRow {
                                    iconName: "format-text-direction-horizontal"
                                    labelText: i18n("Letter distance:")

                                    QQC2.SpinBox {
                                        from: -20
                                        to: 60
                                        editable: true
                                        value: Math.round(root.currentSpec.letterSpacing || 0)
                                        onValueModified: root.setSpecProp("letterSpacing", value)
                                        textFromValue: v => v + " px"
                                        valueFromText: t => parseInt(t) || 0
                                    }
                                }

                                // Italic Style
                                PropertyRow {
                                    iconName: "format-text-italic"
                                    labelText: i18n("Style:")

                                    QQC2.CheckBox {
                                        text: i18n("Italic")
                                        checked: !!root.currentSpec.italic
                                        onToggled: root.setSpecProp("italic", checked)
                                    }
                                }
                            }

                            // ------------------------------------------
                            // TAB 2: FILLING (Foreground & Background)
                            // ------------------------------------------
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.mediumSpacing

                                // Text Foreground Fill
                                PropertyRow {
                                    iconName: "format-text-color"
                                    labelText: i18n("Text foreground:")
                                    isSection: true
                                }

                                // Text Fill Mode
                                PropertyRow {
                                    iconName: "format-text-color"
                                    labelText: i18n("Text fill mode:")

                                    QQC2.ComboBox {
                                        Layout.fillWidth: true
                                        model: [i18n("Solid Color"), i18n("Gradient")]
                                        currentIndex: root.currentSpec.textMode === "gradient" ? 1 : 0
                                        onActivated: idx => {
                                            const newMode = idx === 1 ? "gradient" : "color";
                                            if (newMode === "gradient" && (!root.currentSpec.textGradient || root.currentSpec.textGradient.length === 0)) {
                                                const names = GradientStore.names();
                                                if (names && names.length > 0) root.setSpecProp("textGradient", names[0]);
                                            }
                                            root.setSpecProp("textMode", newMode);
                                        }
                                    }
                                }

                                // Solid Color Text Fill
                                PropertyRow {
                                    visible: root.currentSpec.textMode !== "gradient"
                                    iconName: "color-fill"
                                    labelText: i18n("Text color:")

                                    ColorSpecButton {
                                        value: root.currentSpec.textColor || "#ffffffff"
                                        dialogTitle: i18n("Choose Text Color")
                                        onEdited: val => root.setSpecProp("textColor", val)
                                    }
                                }

                                // Gradient Text Fill
                                PropertyRow {
                                    visible: root.currentSpec.textMode === "gradient"
                                    iconName: "paint-gradient-linear"
                                    labelText: i18n("Text gradient:")

                                    GradientChooserButton {
                                        Layout.fillWidth: true
                                        selected: root.currentSpec.textGradient || ""
                                        onPicked: name => root.setSpecProp("textGradient", name)
                                    }
                                }

                                Kirigami.Separator { Layout.fillWidth: true }

                                // Background Section Header
                                PropertyRow {
                                    iconName: "fill-color"
                                    labelText: i18n("Background:")
                                    isSection: true
                                }

                                // Background Mode
                                PropertyRow {
                                    iconName: "fill-color"
                                    labelText: i18n("Background mode:")

                                    QQC2.ComboBox {
                                        Layout.fillWidth: true
                                        model: [i18n("None (Transparent)"), i18n("Solid Color"), i18n("Gradient")]
                                        currentIndex: root.currentSpec.bgMode === "color" ? 1 : (root.currentSpec.bgMode === "gradient" ? 2 : 0)
                                        onActivated: idx => {
                                            const modes = ["none", "color", "gradient"];
                                            root.setSpecProp("bgMode", modes[idx]);
                                        }
                                    }
                                }

                                // Solid Color Background Selector
                                PropertyRow {
                                    visible: root.currentSpec.bgMode === "color"
                                    iconName: "color-fill"
                                    labelText: i18n("Solid color:")

                                    ColorSpecButton {
                                        value: root.currentSpec.bgColor || "#40000000"
                                        dialogTitle: i18n("Choose Background Color")
                                        onEdited: val => root.setSpecProp("bgColor", val)
                                    }
                                }

                                // Background Corner Radius
                                PropertyRow {
                                    visible: root.currentSpec.bgMode !== "none"
                                    iconName: "draw-rectangle-rounded"
                                    labelText: i18n("Corner radius:")

                                    QQC2.SpinBox {
                                        from: 0
                                        to: 50
                                        editable: true
                                        value: root.currentSpec.bgRadius || 0
                                        onValueModified: root.setSpecProp("bgRadius", value)
                                        textFromValue: v => v + " px"
                                        valueFromText: t => parseInt(t) || 0
                                    }
                                }

                                // Background Padding
                                PropertyRow {
                                    visible: root.currentSpec.bgMode !== "none"
                                    iconName: "format-border-set-external"
                                    labelText: i18n("Padding:")

                                    QQC2.SpinBox {
                                        from: 0
                                        to: 40
                                        editable: true
                                        value: root.currentSpec.bgPadding || 0
                                        onValueModified: root.setSpecProp("bgPadding", value)
                                        textFromValue: v => v + " px"
                                        valueFromText: t => parseInt(t) || 0
                                    }
                                }

                                Item { Layout.fillHeight: true }

                                // Shared Custom Gradient Background Selector in the Bottom of the Tab
                                Kirigami.Separator {
                                    visible: root.currentSpec.bgMode === "gradient"
                                    Layout.fillWidth: true
                                }

                                PropertyRow {
                                    visible: root.currentSpec.bgMode === "gradient"
                                    iconName: "paint-gradient-linear"
                                    labelText: i18n("Gradient selector:")

                                    GradientChooserButton {
                                        Layout.fillWidth: true
                                        selected: root.currentSpec.bgGradient || ""
                                        onPicked: name => root.setSpecProp("bgGradient", name)
                                    }
                                }
                            }

                            // ------------------------------------------
                            // TAB 3: EFFECTS
                            // ------------------------------------------
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.mediumSpacing

                                // --- Outline ---
                                PropertyRow {
                                    iconName: "format-stroke-color"
                                    labelText: i18n("Outline:")
                                    isSection: true

                                    QQC2.CheckBox {
                                        text: i18n("Enable text outline")
                                        checked: !!root.currentSpec.outlineEnabled
                                        onToggled: root.setSpecProp("outlineEnabled", checked)
                                    }
                                }

                                PropertyRow {
                                    visible: root.currentSpec.outlineEnabled
                                    iconName: "color-picker"
                                    labelText: i18n("Outline color:")

                                    ColorSpecButton {
                                        value: root.currentSpec.outlineColor || "#ff000000"
                                        dialogTitle: i18n("Choose Outline Color")
                                        onEdited: val => root.setSpecProp("outlineColor", val)
                                    }
                                }

                                PropertyRow {
                                    visible: root.currentSpec.outlineEnabled
                                    iconName: "stroke-width"
                                    labelText: i18n("Outline width:")

                                    QQC2.SpinBox {
                                        from: 1
                                        to: 20
                                        editable: true
                                        value: root.currentSpec.outlineWidth || 1
                                        onValueModified: root.setSpecProp("outlineWidth", value)
                                        textFromValue: v => v + " px"
                                        valueFromText: t => parseInt(t) || 1
                                    }
                                }

                                Kirigami.Separator { Layout.fillWidth: true }

                                // --- Multiple Shadows Editor (turbotodo style) ---
                                PropertyRow {
                                    iconName: "edit-shadow"
                                    labelText: i18n("Shadow editor:")
                                    isSection: true

                                    QQC2.Label {
                                        text: i18n("Multiple shadows configuration")
                                        opacity: 0.7
                                    }
                                }

                                TextShadowListEditor {
                                    Layout.fillWidth: true
                                    shadows: root.currentSpec.shadows || []
                                    onEdited: arr => {
                                        root.setSpecProp("shadows", arr);
                                    }
                                }

                                Kirigami.Separator { Layout.fillWidth: true }

                                // --- Glow ---
                                PropertyRow {
                                    iconName: "weather-clear"
                                    labelText: i18n("Glow:")
                                    isSection: true

                                    QQC2.CheckBox {
                                        text: i18n("Enable halo glow")
                                        checked: !!root.currentSpec.glowEnabled
                                        onToggled: root.setSpecProp("glowEnabled", checked)
                                    }
                                }

                                PropertyRow {
                                    visible: root.currentSpec.glowEnabled
                                    iconName: "format-fill-color"
                                    labelText: i18n("Glow color:")

                                    ColorSpecButton {
                                        value: root.currentSpec.glowColor || "#ffffaa00"
                                        dialogTitle: i18n("Choose Glow Color")
                                        onEdited: val => root.setSpecProp("glowColor", val)
                                    }
                                }

                                PropertyRow {
                                    visible: root.currentSpec.glowEnabled
                                    iconName: "contrast"
                                    labelText: i18n("Glow strength:")

                                    QQC2.SpinBox {
                                        from: 1
                                        to: 10
                                        editable: true
                                        value: Math.round((root.currentSpec.glowStrength || 1.0) * 2)
                                        onValueModified: root.setSpecProp("glowStrength", value / 2.0)
                                        textFromValue: v => (v / 2.0).toFixed(1) + "x"
                                        valueFromText: t => Math.round(parseFloat(t) * 2) || 2
                                    }
                                }

                                PropertyRow {
                                    visible: root.currentSpec.glowEnabled
                                    iconName: "draw-brush"
                                    labelText: i18n("Glow blur / radius:")

                                    QQC2.SpinBox {
                                        from: 1
                                        to: 40
                                        editable: true
                                        value: root.currentSpec.glowRadius || 6
                                        onValueModified: root.setSpecProp("glowRadius", value)
                                        textFromValue: v => v + " px"
                                        valueFromText: t => parseInt(t) || 6
                                    }
                                }
                            }

                            // ------------------------------------------
                            // TAB 4: ALIGN
                            // ------------------------------------------
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.mediumSpacing

                                // Horizontal Alignment
                                PropertyRow {
                                    iconName: "format-justify-left"
                                    labelText: i18n("Horizontal align:")

                                    RowLayout {
                                        spacing: Kirigami.Units.smallSpacing

                                        QQC2.ToolButton {
                                            icon.name: "format-justify-left"
                                            text: i18n("Left")
                                            checkable: true
                                            checked: (root.currentSpec.horizontalAlignment === Text.AlignLeft || !root.currentSpec.horizontalAlignment) && !root.currentSpec.justified
                                            onClicked: {
                                                root.setSpecProp("justified", false);
                                                root.setSpecProp("horizontalAlignment", Text.AlignLeft);
                                            }
                                        }

                                        QQC2.ToolButton {
                                            icon.name: "format-justify-center"
                                            text: i18n("Center")
                                            checkable: true
                                            checked: root.currentSpec.horizontalAlignment === Text.AlignHCenter && !root.currentSpec.justified
                                            onClicked: {
                                                root.setSpecProp("justified", false);
                                                root.setSpecProp("horizontalAlignment", Text.AlignHCenter);
                                            }
                                        }

                                        QQC2.ToolButton {
                                            icon.name: "format-justify-right"
                                            text: i18n("Right")
                                            checkable: true
                                            checked: root.currentSpec.horizontalAlignment === Text.AlignRight && !root.currentSpec.justified
                                            onClicked: {
                                                root.setSpecProp("justified", false);
                                                root.setSpecProp("horizontalAlignment", Text.AlignRight);
                                            }
                                        }
                                    }
                                }

                                // Vertical Alignment
                                PropertyRow {
                                    iconName: "align-vertical-center"
                                    labelText: i18n("Vertical align:")

                                    RowLayout {
                                        spacing: Kirigami.Units.smallSpacing

                                        QQC2.ToolButton {
                                            icon.name: "align-vertical-top"
                                            text: i18n("Top")
                                            checkable: true
                                            checked: root.currentSpec.verticalAlignment === Text.AlignTop
                                            onClicked: root.setSpecProp("verticalAlignment", Text.AlignTop)
                                        }

                                        QQC2.ToolButton {
                                            icon.name: "align-vertical-center"
                                            text: i18n("Middle")
                                            checkable: true
                                            checked: root.currentSpec.verticalAlignment === Text.AlignVCenter || !root.currentSpec.verticalAlignment
                                            onClicked: root.setSpecProp("verticalAlignment", Text.AlignVCenter)
                                        }

                                        QQC2.ToolButton {
                                            icon.name: "align-vertical-bottom"
                                            text: i18n("Bottom")
                                            checkable: true
                                            checked: root.currentSpec.verticalAlignment === Text.AlignBottom
                                            onClicked: root.setSpecProp("verticalAlignment", Text.AlignBottom)
                                        }
                                    }
                                }

                                // Justification
                                PropertyRow {
                                    iconName: "format-justify-fill"
                                    labelText: i18n("Justification:")

                                    QQC2.ToolButton {
                                        icon.name: "format-justify-fill"
                                        text: i18n("Justify text lines")
                                        checkable: true
                                        checked: !!root.currentSpec.justified
                                        onToggled: root.setSpecProp("justified", checked)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Kirigami.Separator { Layout.fillWidth: true }

            // Bottom action row
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.Button {
                    icon.name: "edit-undo"
                    text: i18n("Reset to Default")
                    onClicked: {
                        const def = TextSpecCore.defaultSpec();
                        root.currentSpec = def;
                        root.value = JSON.stringify(def);
                        root.edited(root.value);
                    }
                }

                Item { Layout.fillWidth: true }

                QQC2.Button {
                    icon.name: "dialog-ok"
                    text: i18n("Done")
                    QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
                    onClicked: popup.close()
                }
            }
        }
    }
}
