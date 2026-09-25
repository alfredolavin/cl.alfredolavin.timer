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
