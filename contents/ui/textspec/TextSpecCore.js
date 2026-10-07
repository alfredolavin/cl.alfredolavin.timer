.pragma library

// TextSpecCore: complete text styling model encapsulating font family, font weight,
// glow, shadow, outline width & color, background color or gradient, and inter-letter distance.

var weights = [
    { name: "Thin (100)", value: 100 },
    { name: "Extra Light (200)", value: 200 },
    { name: "Light (300)", value: 300 },
    { name: "Normal (400)", value: 400 },
    { name: "Medium (500)", value: 500 },
    { name: "Semi Bold (600)", value: 600 },
    { name: "Bold (700)", value: 700 },
    { name: "Extra Bold (800)", value: 800 },
    { name: "Black (900)", value: 900 }
];

function weightName(val) {
    var v = parseInt(val) || 400;
    for (var i = 0; i < weights.length; ++i) {
        if (weights[i].value === v) return weights[i].name;
    }
    if (v >= 800) return "Extra Bold (" + v + ")";
    if (v >= 700) return "Bold (" + v + ")";
    if (v >= 600) return "Semi Bold (" + v + ")";
    if (v >= 500) return "Medium (" + v + ")";
    if (v >= 400) return "Normal (" + v + ")";
    if (v >= 300) return "Light (" + v + ")";
    return "Weight (" + v + ")";
}

function defaultSpec() {
    return {
        fontFamily: "",
        weight: 600,
        pixelSize: 12,
        italic: false,
        letterSpacing: 0,
        textColor: "#ffffffff",
        outlineEnabled: false,
        outlineWidth: 1,
        outlineColor: "#ff000000",
        glowEnabled: false,
        glowColor: "#ffffaa00",
        glowRadius: 6,
        shadowEnabled: false,
        shadowColor: "#80000000",
        shadowBlur: 4,
        shadowX: 1,
        shadowY: 1,
        bgMode: "none",        // "none" | "color" | "gradient"
        bgColor: "#40000000",
        bgGradient: "",
        bgRadius: 4,
        bgPadding: 2
    };
}

function normalize(spec) {
    if (!spec || typeof spec !== "object") {
        spec = {};
    }
    var d = defaultSpec();
    return {
        fontFamily: String(spec.fontFamily !== undefined ? spec.fontFamily : d.fontFamily),
        weight: parseInt(spec.weight !== undefined ? spec.weight : d.weight) || 400,
        pixelSize: Math.max(6, parseInt(spec.pixelSize !== undefined ? spec.pixelSize : d.pixelSize) || 12),
        italic: !!spec.italic,
        letterSpacing: parseFloat(spec.letterSpacing !== undefined ? spec.letterSpacing : d.letterSpacing) || 0,
        textColor: String(spec.textColor || d.textColor),
        outlineEnabled: !!spec.outlineEnabled,
        outlineWidth: Math.max(0, parseInt(spec.outlineWidth !== undefined ? spec.outlineWidth : d.outlineWidth) || 0),
        outlineColor: String(spec.outlineColor || d.outlineColor),
        glowEnabled: !!spec.glowEnabled,
        glowColor: String(spec.glowColor || d.glowColor),
        glowRadius: Math.max(1, parseInt(spec.glowRadius !== undefined ? spec.glowRadius : d.glowRadius) || 6),
        shadowEnabled: !!spec.shadowEnabled,
        shadowColor: String(spec.shadowColor || d.shadowColor),
        shadowBlur: Math.max(0, parseInt(spec.shadowBlur !== undefined ? spec.shadowBlur : d.shadowBlur) || 4),
        shadowX: parseFloat(spec.shadowX !== undefined ? spec.shadowX : d.shadowX) || 0,
        shadowY: parseFloat(spec.shadowY !== undefined ? spec.shadowY : d.shadowY) || 0,
        bgMode: spec.bgMode === "color" || spec.bgMode === "gradient" ? spec.bgMode : "none",
        bgColor: String(spec.bgColor || d.bgColor),
        bgGradient: String(spec.bgGradient !== undefined ? spec.bgGradient : d.bgGradient),
        bgRadius: Math.max(0, parseInt(spec.bgRadius !== undefined ? spec.bgRadius : d.bgRadius) || 0),
        bgPadding: Math.max(0, parseInt(spec.bgPadding !== undefined ? spec.bgPadding : d.bgPadding) || 0)
    };
}

function parse(str, fallback) {
    if (typeof str === "object" && str !== null) {
        return normalize(str);
    }
    if (typeof str === "string" && str.trim().startsWith("{")) {
        try {
            return normalize(JSON.parse(str));
        } catch (e) {}
    }
    return normalize(fallback || defaultSpec());
}

function stringify(spec) {
    return JSON.stringify(normalize(spec));
}

function summary(spec) {
    var s = normalize(spec);
    var parts = [];
    var fam = s.fontFamily ? s.fontFamily : "Default";
    parts.push(fam + " " + s.pixelSize + "px " + (s.weight >= 700 ? "Bold" : (s.weight <= 300 ? "Light" : "Normal")));
    if (s.italic) parts.push("italic");
    if (s.letterSpacing !== 0) parts.push("spacing " + s.letterSpacing + "px");
    if (s.outlineEnabled && s.outlineWidth > 0) parts.push("outline " + s.outlineWidth + "px");
    if (s.glowEnabled) parts.push("glow");
    if (s.shadowEnabled) parts.push("shadow");
    if (s.bgMode !== "none") parts.push("bg " + s.bgMode);
    return parts.join(", ");
}

var presets = [
    {
        name: "Default Clean",
        spec: {
            fontFamily: "",
            weight: 500,
            pixelSize: 12,
            italic: false,
            letterSpacing: 0,
            textColor: "#ffffffff",
            outlineEnabled: false,
            outlineWidth: 0,
            outlineColor: "#ff000000",
            glowEnabled: false,
            glowColor: "#ffffaa00",
            glowRadius: 6,
            shadowEnabled: false,
            shadowColor: "#80000000",
            shadowBlur: 4,
            shadowX: 1,
            shadowY: 1,
            bgMode: "none",
            bgColor: "#40000000",
            bgGradient: "",
            bgRadius: 4,
            bgPadding: 2
        }
    },
    {
        name: "Badge Number (Centered)",
        spec: {
            fontFamily: "",
            weight: 800,
            pixelSize: 10,
            italic: false,
            letterSpacing: 0,
            textColor: "#ffffffff",
            outlineEnabled: true,
            outlineWidth: 1,
            outlineColor: "#ff660000",
            glowEnabled: false,
            glowColor: "#ffffffff",
            glowRadius: 4,
            shadowEnabled: true,
            shadowColor: "#99000000",
            shadowBlur: 2,
            shadowX: 0,
            shadowY: 1,
            bgMode: "none",
            bgColor: "#40000000",
            bgGradient: "",
            bgRadius: 0,
            bgPadding: 0
        }
    },
    {
        name: "Badge Circle (Filled ●)",
        spec: {
            fontFamily: "",
            weight: 400,
            pixelSize: 22,
            italic: false,
            letterSpacing: 0,
            textColor: "#ffea4335",
            outlineEnabled: true,
            outlineWidth: 1,
            outlineColor: "#ff990000",
            glowEnabled: true,
            glowColor: "#80ff4444",
            glowRadius: 5,
            shadowEnabled: true,
            shadowColor: "#80000000",
            shadowBlur: 3,
            shadowX: 0,
            shadowY: 1,
            bgMode: "none",
            bgColor: "#40000000",
            bgGradient: "",
            bgRadius: 0,
            bgPadding: 0
        }
    },
    {
        name: "Cyber Neon Glow",
        spec: {
            fontFamily: "",
            weight: 700,
            pixelSize: 13,
            italic: false,
            letterSpacing: 1,
            textColor: "#ff00f0ff",
            outlineEnabled: false,
            outlineWidth: 0,
            outlineColor: "#ff000000",
            glowEnabled: true,
            glowColor: "#cc00e5ff",
            glowRadius: 8,
            shadowEnabled: true,
            shadowColor: "#aa003366",
            shadowBlur: 4,
            shadowX: 0,
            shadowY: 2,
            bgMode: "none",
            bgColor: "#40000000",
            bgGradient: "",
            bgRadius: 4,
            bgPadding: 2
        }
    },
    {
        name: "High Contrast Outlined",
        spec: {
            fontFamily: "",
            weight: 700,
            pixelSize: 13,
            italic: false,
            letterSpacing: 0,
            textColor: "#ffffffff",
            outlineEnabled: true,
            outlineWidth: 2,
            outlineColor: "#ff000000",
            glowEnabled: false,
            glowColor: "#ffffff00",
            glowRadius: 4,
            shadowEnabled: true,
            shadowColor: "#aa000000",
            shadowBlur: 3,
            shadowX: 1,
            shadowY: 1,
            bgMode: "none",
            bgColor: "#40000000",
            bgGradient: "",
            bgRadius: 4,
            bgPadding: 2
        }
    },
    {
        name: "Rounded Capsule Gradient",
        spec: {
            fontFamily: "",
            weight: 600,
            pixelSize: 12,
            italic: false,
            letterSpacing: 0.5,
            textColor: "#ffffffff",
            outlineEnabled: false,
            outlineWidth: 0,
            outlineColor: "#ff000000",
            glowEnabled: false,
            glowColor: "#ffffff00",
            glowRadius: 4,
            shadowEnabled: true,
            shadowColor: "#66000000",
            shadowBlur: 3,
            shadowX: 0,
            shadowY: 1,
            bgMode: "gradient",
            bgColor: "#33000000",
            bgGradient: "Cyber Blue",
            bgRadius: 8,
            bgPadding: 4
        }
    }
];
