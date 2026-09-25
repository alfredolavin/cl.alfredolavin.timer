#!/usr/bin/env python3
"""Synthesize the 10 alarm sounds shipped in contents/sounds (requires numpy)."""
import os, wave
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "contents", "sounds")
rng = np.random.default_rng(7)


def note(n):  # MIDI note -> Hz
    return 440.0 * 2 ** ((n - 69) / 12)


def t_(dur):
    return np.arange(int(SR * dur)) / SR


def env(t, attack=0.004, decay=1.0):
    a = np.clip(t / attack, 0, 1)
    return a * np.exp(-t / decay)


def partials(freq, dur, ratios, amps, decays, attack=0.003, detune=0.0):
    t = t_(dur)
    out = np.zeros_like(t)
    for r, a, d in zip(ratios, amps, decays):
        f = freq * r * (1 + detune * rng.uniform(-1, 1))
        out += a * np.sin(2 * np.pi * f * t + rng.uniform(0, 6.28)) * env(t, attack, d)
    return out


def pluck(freq, dur, damp=0.996):
    """Karplus-Strong string."""
    n = int(SR * dur)
    p = max(2, int(SR / freq))
    buf = rng.uniform(-1, 1, p)
    out = np.zeros(n)
    for i in range(n):
        out[i] = buf[i % p]
        buf[i % p] = damp * 0.5 * (buf[i % p] + buf[(i + 1) % p])
    return out * env(t_(dur), 0.002, dur)


def place(total, events):
    out = np.zeros(int(SR * total))
    for start, sig, gain, pan in events:
        i = int(start * SR)
        seg = sig[: max(0, len(out) - i)] * gain
        out[i:i + len(seg)] += seg
    return out


def stereo_place(total, events):
    L = np.zeros(int(SR * total)); R = np.zeros_like(L)
    for start, sig, gain, pan in events:
        i = int(start * SR)
        seg = sig[: max(0, len(L) - i)] * gain
        L[i:i + len(seg)] += seg * np.cos(pan * np.pi / 2)
        R[i:i + len(seg)] += seg * np.sin(pan * np.pi / 2)
    return np.stack([L, R])


def reverb(st, size=1.6, mix=0.28):
    n = int(SR * size)
    t = np.arange(n) / SR
    out = []
    for ch in range(2):
        ir = rng.normal(0, 1, n) * np.exp(-t * 4.5 / size)
        ir[: int(SR * 0.012)] = 0
        ir /= np.sqrt(np.sum(ir ** 2))
        L = len(st[ch]) + n
        wet = np.fft.irfft(np.fft.rfft(st[ch], L) * np.fft.rfft(ir, L), L)
        dry = np.concatenate([st[ch], np.zeros(n)])
        out.append((1 - mix) * dry + mix * wet)
    return np.stack(out)


def write(name, st, tail=1.2, rev=0.28):
    st = reverb(st, tail, rev)
    # trim silence at the end, fade out
    mag = np.max(np.abs(st), axis=0)
    last = np.nonzero(mag > 1e-3 * mag.max())[0][-1]
    st = st[:, : last + 1]
    fade = min(len(st[0]), int(SR * 0.08))
    st[:, -fade:] *= np.linspace(1, 0, fade)
    st = st / np.max(np.abs(st)) * 0.85
    data = (st.T * 32767).astype("<i2").tobytes()
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data)
    print(name, round(len(st[0]) / SR, 2), "s")


BELL = ([0.56, 0.92, 1.19, 1.71, 2.0, 2.74, 3.0, 3.76, 4.07],
        [1, 0.67, 1, 1.8, 2.67, 1.67, 1.46, 1.33, 1.33],
        [1.0, 0.9, 0.65, 0.55, 0.33, 0.35, 0.25, 0.2, 0.15])


def crystal_chime():
    ev = []
    for i, n in enumerate([84, 88, 91, 96]):
        s = partials(note(n), 2.2, [1, 2.76, 5.4, 8.93], [1, .45, .2, .08], [1.4, .6, .3, .15])
        ev.append((i * 0.14, s, 0.5, 0.2 + i * 0.2))
    return stereo_place(3.0, ev)


def marimba():
    ev = []
    for i, n in enumerate([72, 76, 79, 84, 79, 84]):
        s = partials(note(n), 1.0, [1, 3.93, 9.2], [1, .35, .1], [.45, .12, .04], attack=0.002)
        ev.append((i * 0.13 + (0.1 if i > 3 else 0), s, 0.5, 0.3 + 0.08 * i))
    return stereo_place(1.8, ev)


def soft_bell():
    ev = [(0, partials(note(76), 3.5, [r for r in BELL[0]], [a / 3 for a in BELL[1]], [d * 3 for d in BELL[2]]), 0.5, 0.4),
          (0.6, partials(note(83), 3.0, BELL[0], [a / 3 for a in BELL[1]], [d * 2.5 for d in BELL[2]]), 0.35, 0.6)]
    return stereo_place(4.0, ev)


def kalimba():
    ev = []
    for i, n in enumerate([74, 79, 81, 86, 83, 79]):
        s = partials(note(n), 1.4, [1, 5.9, 11.2], [1, .25, .08], [.8, .08, .03], attack=0.001)
        ev.append((i * 0.17, s, 0.5, 0.2 + 0.12 * i))
    return stereo_place(2.4, ev)


def music_box():
    ev = []
    melody = [(84, 0), (88, .2), (91, .4), (93, .6), (91, .8), (88, 1.0), (91, 1.2), (96, 1.45)]
    for n, st in melody:
        s = partials(note(n), 1.6, [1, 3.0, 6.1], [1, .2, .06], [1.0, .25, .08], attack=0.001)
        ev.append((st, s, 0.45, 0.5 + 0.3 * np.sin(n)))
    return stereo_place(3.0, ev)


def singing_bowl():
    t = t_(5.0)
    f = note(57)
    s = np.zeros_like(t)
    for r, a in [(1, 1), (2.71, .5), (5.1, .25), (8.2, .1)]:
        s += a * np.sin(2 * np.pi * f * r * t) * (1 + 0.3 * np.sin(2 * np.pi * (1.3 + r * .4) * t))
    s *= np.clip(t / 0.02, 0, 1) * np.exp(-t / 1.8)
    s2 = np.roll(s, 90) * 0.9
    return np.stack([s, s2])


def harp():
    ev = []
    for i, n in enumerate([60, 64, 67, 71, 72, 76, 79, 83, 84]):
        ev.append((i * 0.07, pluck(note(n), 2.0, 0.997), 0.35, 0.1 + 0.1 * i))
    return stereo_place(2.8, ev)


def sunrise_pad():
    t = t_(3.5)
    out = np.zeros((2, len(t)))
    for j, n in enumerate([60, 67, 72, 76, 79]):
        f = note(n)
        mod = np.sin(2 * np.pi * f * 2 * t) * 1.2 * np.exp(-t / 1.5)
        for ch, dt in enumerate([-0.15, 0.15]):
            s = np.sin(2 * np.pi * (f + dt) * t + mod)
            e = np.clip(t / (0.3 + 0.2 * j), 0, 1) * np.exp(-np.maximum(0, t - 1.5) / 0.8)
            out[ch] += s * e * 0.3
    return out


def digital_pulse():
    ev = []
    for rep in range(2):
        for i, n in enumerate([81, 85, 88]):
            t = t_(0.18)
            f = note(n)
            s = sum(np.sin(2 * np.pi * f * k * t) / k for k in (1, 3, 5))  # soft square
            s *= env(t, 0.005, 0.07)
            ev.append((rep * 0.55 + i * 0.1, s, 0.4, 0.5))
    return stereo_place(1.4, ev)


def bubbles():
    ev = []
    for i in range(7):
        d = 0.18
        t = t_(d)
        f0 = rng.uniform(500, 900)
        f = f0 * (1 + 2.2 * t / d)
        s = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(t, 0.003, 0.05)
        ev.append((i * 0.12 + rng.uniform(0, .04), s, 0.5, rng.uniform(0.1, 0.9)))
    return stereo_place(1.3, ev)


def wind_chimes():
    ev = []
    notes = [79, 81, 84, 86, 88, 91, 93]
    for i in range(10):
        n = notes[rng.integers(len(notes))]
        s = partials(note(n), 2.5, [1, 2.76, 5.4], [1, .4, .15], [1.6, .6, .2])
        ev.append((i * 0.16 + rng.uniform(0, .08), s, 0.3, rng.uniform(0, 1)))
    return stereo_place(4.0, ev)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    write("01-crystal-chime", crystal_chime())
    write("02-marimba", marimba())
    write("03-soft-bell", soft_bell(), 2.0, 0.3)
    write("04-kalimba", kalimba())
    write("05-music-box", music_box())
    write("06-singing-bowl", singing_bowl(), 2.0, 0.25)
    write("07-harp", harp())
    write("08-sunrise-pad", sunrise_pad(), 2.0, 0.35)
    write("09-digital-pulse", digital_pulse(), 0.8, 0.18)
    write("10-wind-chimes", wind_chimes(), 2.0, 0.3)
