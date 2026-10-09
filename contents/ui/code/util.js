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

// Time of day from minutes after midnight, e.g. "07:30"
function formatClock(at) {
    return pad(Math.floor(at / 60) % 24) + ":" + pad(at % 60);
}

// Next moment (ms) the clock shows `at` minutes after midnight, strictly after nowMs
function nextOccurrence(at, nowMs) {
    var d = new Date(nowMs);
    d.setHours(Math.floor(at / 60), at % 60, 0, 0);
    if (d.getTime() <= nowMs)
        d.setDate(d.getDate() + 1);
    return d.getTime();
}

// Quick entry. A "+" prefix (or none) makes a timer, a "-" prefix makes an alarm. A bare number is hours.
// Timer: "2" (2h), "2:30", "1,5" (1.5h), "1h30", "90s", "5m", "1h 30m 10s", "0.45" (0h45).
// Alarm (time of day): "-14:30", "-7pm", "-7:30 am", and without am/pm:
//   "-3.5" decimal hours (the dot): 3:30; "-3.25" 3:15; "-3,5" the comma gives minutes: 3:05; "-3,53" 3:53; "-3:30" 3:30.
//   An hour from 1 to 11 without am/pm is taken in the 12-hour clock with the current am/pm: at 15:00, "-3.5" is 15:30
//   (12 and up, and 0, are literal).
// Returns null when not understood. `nowMs` (default: now) tells am from pm.
function parseQuick(text, nowMs) {
    var s = (text || "").toLowerCase().replace(/\s+/g, "");
    var alarm = false;
    if (s[0] === "+" || s[0] === "-") {
        alarm = s[0] === "-";
        s = s.substr(1);
    }
    if (!s)
        return null;
    var m;
    if (alarm) {
        m = s.match(/^(\d{1,2})(?::(\d{2}))?([ap])\.?m?\.?$/);
        if (m) {
            var h12 = parseInt(m[1], 10), m12 = m[2] ? parseInt(m[2], 10) : 0;
            if (h12 < 1 || h12 > 12 || m12 > 59)
                return null;
            return { kind: "alarm", at: (h12 % 12 + (m[3] === "p" ? 12 : 0)) * 60 + m12 };
        }
        // "8", "14:30", "8.5" (decimal hours: 8:30), "8,5" (minutes: 8:05): a clock time
        m = s.match(/^(\d{1,2})(?:([:.,])(\d*))?$/);
        if (!m)
            return null;
        var h = parseInt(m[1], 10), f = m[3] || "", min = 0;
        if (f && m[2] === ".")
            min = Math.round(parseFloat("0." + f) * 60);
        else if (f && f.length <= 2)
            min = m[2] === "," ? parseInt(f, 10) : parseInt(f.padEnd(2, "0"), 10);
        else if (f)
            return null;
        if (h >= 1 && h < 12 && new Date(nowMs === undefined ? Date.now() : nowMs).getHours() >= 12)
            h += 12;
        return h < 24 && min < 60 ? { kind: "alarm", at: h * 60 + min } : null;
    }
    var sec = -1;
    if (/^\d+$/.test(s))
        sec = parseInt(s, 10) * 3600;
    // "2:30" / "0.45": hours and minutes
    else if ((m = s.match(/^(\d+)[:.](\d{0,2})$/)))
        sec = parseInt(m[1], 10) * 3600 + parseInt((m[2] || "0").padEnd(2, "0"), 10) * 60;
    // "1,5": a decimal number of hours typed with a comma
    else if ((m = s.match(/^(\d+),(\d+)$/)))
        sec = Math.round(parseFloat(m[1] + "." + m[2]) * 3600);
    else if ((m = s.match(/^(\d+)h(\d+)$/)))
        sec = parseInt(m[1], 10) * 3600 + parseInt(m[2], 10) * 60;
    else if ((m = s.match(/^(?:(\d+)h)?(?:(\d+)m(?:in)?)?(?:(\d+)s)?$/)))
        sec = (parseInt(m[1] || 0, 10)) * 3600 + (parseInt(m[2] || 0, 10)) * 60 + (parseInt(m[3] || 0, 10));
    return sec > 0 && sec < 100 * 3600 ? { kind: "timer", duration: sec } : null;
}

function newId() {
    return "t" + Date.now().toString(36) + Math.floor(Math.random() * 1e6).toString(36);
}

function normalize(t) {
    return {
        id: t.id || newId(),
        name: t.name || "Timer",
        icon: t.icon || "f051b",
        // "timer" counts down `duration` seconds; "alarm" counts down to the time of day `at`
        kind: t.kind === "alarm" ? "alarm" : "timer",
        at: Math.min(1439, Math.max(0, isNaN(parseInt(t.at)) ? 420 : parseInt(t.at))),
        duration: Math.max(1, parseInt(t.duration) || 60),
        sound: Math.min(sounds.length - 1, Math.max(0, parseInt(t.sound) || 0)),
        repeat: Math.max(0, isNaN(parseInt(t.repeat)) ? 3 : parseInt(t.repeat)),
        gradient: t.gradient || "",
        // text shown over the bar when the time is up; empty = "<name> Ready!!"
        message: t.message || ""
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

function finishedMessage(t) {
    return t.message && t.message.trim().length ? t.message : (t.name || "Timer") + " Ready!!";
}

function loadRunning(json) {
    try {
        var a = JSON.parse(json || "[]");
        if (Array.isArray(a))
            return a.filter(function (r) { return r && r.uid; });
    } catch (e) {}
    return [];
}
