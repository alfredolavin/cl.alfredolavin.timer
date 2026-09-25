.pragma library

var sounds = [
    { name: "Crystal chime", file: "01-crystal-chime.wav" },
    { name: "Marimba", file: "02-marimba.wav" },
    { name: "Soft bell", file: "03-soft-bell.wav" },
    { name: "Kalimba", file: "04-kalimba.wav" },
    { name: "Music box", file: "05-music-box.wav" },
    { name: "Singing bowl", file: "06-singing-bowl.wav" },
    { name: "Harp", file: "07-harp.wav" },
    { name: "Sunrise pad", file: "08-sunrise-pad.wav" },
    { name: "Digital pulse", file: "09-digital-pulse.wav" },
    { name: "Wind chimes", file: "10-wind-chimes.wav" }
];

var defaultTimers = [
    { id: "pomodoro", name: "Pomodoro", icon: "f051f", duration: 1500, sound: 2, repeat: 3, gradient: "Sunset Glow" },
    { id: "break", name: "Short break", icon: "f0176", duration: 300, sound: 3, repeat: 2, gradient: "Mint Fresh" },
    { id: "tea", name: "Tea", icon: "f0d9e", duration: 180, sound: 0, repeat: 3, gradient: "Emerald City" },
    { id: "eggs", name: "Boiled eggs", icon: "f0aaf", duration: 420, sound: 4, repeat: 3, gradient: "Golden Hour" },
    { id: "pasta", name: "Pasta", icon: "f1160", duration: 600, sound: 1, repeat: 3, gradient: "Lava Flow" },
    { id: "workout", name: "Workout", icon: "f01e6", duration: 2700, sound: 8, repeat: 4, gradient: "Electric Indigo" },
    { id: "meditate", name: "Meditation", icon: "f117b", duration: 900, sound: 5, repeat: 1, gradient: "Ocean Breeze" },
    { id: "reading", name: "Reading", icon: "f14f7", duration: 1800, sound: 6, repeat: 2, gradient: "Aurora Borealis" }
];

function glyph(hex) {
    var cp = parseInt(hex, 16);
    if (isNaN(cp))
        return "";
    if (cp <= 0xFFFF)
        return String.fromCharCode(cp);
    cp -= 0x10000;
    return String.fromCharCode(0xD800 + (cp >> 10), 0xDC00 + (cp & 0x3FF));
}

function pad(n) {
    return n < 10 ? "0" + n : "" + n;
}

// Remaining time, e.g. "04:59" or "1:02:03"
function formatTime(ms) {
    var s = Math.max(0, Math.ceil(ms / 1000));
    var h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), sec = s % 60;
    return h > 0 ? h + ":" + pad(m) + ":" + pad(sec) : pad(m) + ":" + pad(sec);
}

// Human duration, e.g. "1h 5m" or "45s"
function formatDuration(sec) {
    var h = Math.floor(sec / 3600), m = Math.floor(sec % 3600 / 60), s = sec % 60;
    var parts = [];
    if (h) parts.push(h + "h");
    if (m) parts.push(m + "m");
    if (s || !parts.length) parts.push(s + "s");
    return parts.join(" ");
}

function newId() {
    return "t" + Date.now().toString(36) + Math.floor(Math.random() * 1e6).toString(36);
}

function normalize(t) {
    return {
        id: t.id || newId(),
        name: t.name || "Timer",
        icon: t.icon || "f051b",
        duration: Math.max(1, parseInt(t.duration) || 60),
        sound: Math.min(sounds.length - 1, Math.max(0, parseInt(t.sound) || 0)),
        repeat: Math.max(0, isNaN(parseInt(t.repeat)) ? 3 : parseInt(t.repeat)),
        gradient: t.gradient || ""
    };
}

function loadTimers(json) {
    if (!json)
        return defaultTimers.map(normalize);
    try {
        var a = JSON.parse(json);
        if (Array.isArray(a))
            return a.map(normalize);
    } catch (e) {}
    return defaultTimers.map(normalize);
}

function loadRunning(json) {
    try {
        var a = JSON.parse(json || "[]");
        if (Array.isArray(a))
            return a.filter(function (r) { return r && r.uid; });
    } catch (e) {}
    return [];
}

// Prefer a pure symbols Nerd Font, otherwise any family with "nerd" in its name.
function pickNerdFont(families) {
    var nerd = families.filter(function (f) { return /nerd/i.test(f); });
    var prefs = [/^Symbols Nerd Font$/i, /^Symbols Nerd Font Mono$/i, /Nerd Font Propo$/i, /Nerd Font Mono$/i, /Nerd Font$/i];
    for (var i = 0; i < prefs.length; ++i)
        for (var j = 0; j < nerd.length; ++j)
            if (prefs[i].test(nerd[j]))
                return nerd[j];
    return nerd.length ? nerd[0] : "";
}

// ---- progress bar shadows ----

var shadowPresets = [
    { name: "Soft drop", shadows: [{ x: 0, y: 2, blur: 4, spread: 0, color: "#80000000", inset: false }] },
    { name: "Long soft", shadows: [{ x: 0, y: 4, blur: 12, spread: -1, color: "#66000000", inset: false }] },
    { name: "Hard edge", shadows: [{ x: 2, y: 2, blur: 0, spread: 0, color: "#cc000000", inset: false }] },
    { name: "Inner depth", shadows: [{ x: 0, y: 2, blur: 3, spread: 0, color: "#99000000", inset: true }] },
    { name: "Top highlight", shadows: [{ x: 0, y: 1, blur: 1, spread: 0, color: "#80ffffff", inset: true }] },
    { name: "Embossed", shadows: [{ x: 0, y: 1, blur: 2, spread: 0, color: "#80ffffff", inset: true },
                                 { x: 0, y: -1, blur: 2, spread: 0, color: "#80000000", inset: true },
                                 { x: 0, y: 1, blur: 2, spread: 0, color: "#66000000", inset: false }] },
    { name: "Neon halo", shadows: [{ x: 0, y: 0, blur: 8, spread: 1, color: "#cc00e5ff", inset: false },
                                  { x: 0, y: 0, blur: 3, spread: 0, color: "#ffffffff", inset: false }] }
];

function normalizeShadow(s) {
    function n(v, d) { v = parseFloat(v); return isNaN(v) ? d : v; }
    return {
        enabled: s.enabled !== false,
        x: n(s.x, 0), y: n(s.y, 2), blur: Math.max(0, n(s.blur, 4)), spread: n(s.spread, 0),
        color: typeof s.color === "string" && s.color.length ? s.color : "#80000000",
        inset: !!s.inset
    };
}

function parseShadows(json) {
    try {
        var a = JSON.parse(json || "[]");
        if (Array.isArray(a))
            return a.map(normalizeShadow);
    } catch (e) {}
    return [];
}

// Qt color strings ("#rrggbb" or "#aarrggbb") to {r, g, b, a} in 0..1
function qtColor(str) {
    var h = (str || "").replace("#", "");
    var a = 1;
    if (h.length === 8) {
        a = parseInt(h.substr(0, 2), 16) / 255;
        h = h.substr(2);
    }
    if (h.length !== 6)
        return { r: 0, g: 0, b: 0, a: 0.5 };
    return { r: parseInt(h.substr(0, 2), 16) / 255, g: parseInt(h.substr(2, 2), 16) / 255, b: parseInt(h.substr(4, 2), 16) / 255, a: a };
}

function cssOfHex(str) {
    var c = qtColor(str);
    return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + c.a.toFixed(3) + ")";
}
