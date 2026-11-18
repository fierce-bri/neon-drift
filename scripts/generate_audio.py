#!/usr/bin/env python3
"""Procedurally generates every sound effect and the music loop used by Neon Drift.

sfxr-style synthesis with numpy: oscillators + pitch sweeps + noise + envelopes.
Run from the project root:  python3 scripts/generate_audio.py
Outputs 16-bit mono WAVs to assets/sfx/ and an OGG music loop to assets/music/
(the OGG step needs ffmpeg on PATH).
"""
from __future__ import annotations

import os
import shutil
import subprocess
import wave

import numpy as np

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX_DIR = os.path.join(ROOT, "assets", "sfx")
MUSIC_DIR = os.path.join(ROOT, "assets", "music")
rng = np.random.default_rng(7)


# ---------------------------------------------------------------- primitives
def t_axis(dur: float) -> np.ndarray:
    return np.arange(int(dur * SR)) / SR


def sweep_phase(f0: float, f1: float, dur: float, curve: float = 1.0) -> np.ndarray:
    """Phase (in cycles) of an oscillator sweeping f0 -> f1."""
    t = t_axis(dur)
    k = (t / dur) ** curve
    freq = f0 + (f1 - f0) * k
    return np.cumsum(freq) / SR


def osc(phase: np.ndarray, shape: str = "square", duty: float = 0.5) -> np.ndarray:
    p = phase % 1.0
    if shape == "square":
        return np.where(p < duty, 1.0, -1.0)
    if shape == "saw":
        return 2.0 * p - 1.0
    if shape == "tri":
        return 4.0 * np.abs(p - 0.5) - 1.0
    return np.sin(2 * np.pi * p)


def noise(dur: float) -> np.ndarray:
    return rng.uniform(-1, 1, int(dur * SR))


def lowpass(x: np.ndarray, alpha: float | np.ndarray) -> np.ndarray:
    """One-pole low-pass; alpha in (0,1], may vary per sample."""
    y = np.zeros_like(x)
    a = np.broadcast_to(alpha, x.shape)
    acc = 0.0
    for i in range(len(x)):
        acc += a[i] * (x[i] - acc)
        y[i] = acc
    return y


def env(n: int, attack: float = 0.005, decay_pow: float = 1.5) -> np.ndarray:
    a = max(1, int(attack * SR))
    e = np.ones(n)
    e[:a] = np.linspace(0, 1, a)
    e[a:] = np.linspace(1, 0, n - a) ** decay_pow
    return e


def write_wav(name: str, x: np.ndarray, gain: float = 0.8) -> None:
    x = x / (np.max(np.abs(x)) + 1e-9) * gain
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    path = os.path.join(SFX_DIR, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(f"  {path}  ({len(x) / SR:.2f}s)")


# ---------------------------------------------------------------- effects
def sfx_shoot() -> np.ndarray:
    d = 0.09
    x = osc(sweep_phase(1400, 380, d, 0.6), "square", 0.3) * 0.7
    x += osc(sweep_phase(700, 190, d, 0.6), "tri") * 0.5
    return x * env(len(x), 0.002, 2.0)


def sfx_enemy_shoot() -> np.ndarray:
    d = 0.16
    x = osc(sweep_phase(520, 160, d), "saw") * 0.6 + osc(sweep_phase(260, 90, d), "square", 0.5) * 0.4
    return lowpass(x, 0.35) * env(len(x), 0.004, 1.6)


def sfx_hit() -> np.ndarray:
    d = 0.07
    x = noise(d) * 0.6 + osc(sweep_phase(900, 300, d), "square", 0.5) * 0.5
    return x * env(len(x), 0.001, 2.5)


def sfx_explode() -> np.ndarray:
    d = 0.5
    n = noise(d)
    cutoff = np.linspace(0.5, 0.02, len(n)) ** 1.3
    x = lowpass(n, cutoff) * 1.6 + osc(sweep_phase(160, 35, d), "sine") * 0.6
    return x * env(len(x), 0.002, 1.8)


def sfx_player_hit() -> np.ndarray:
    d = 0.32
    x = osc(sweep_phase(600, 70, d, 0.7), "saw") * 0.6 + lowpass(noise(d), 0.25) * 0.8
    return x * env(len(x), 0.002, 1.3)


def sfx_pickup() -> np.ndarray:
    notes = [660, 880, 1320]
    parts = []
    for f in notes:
        d = 0.06
        s = osc(sweep_phase(f, f, d), "square", 0.25) * 0.6 + osc(sweep_phase(f * 2, f * 2, d), "sine") * 0.3
        parts.append(s * env(len(s), 0.002, 1.0))
    return np.concatenate(parts)


def sfx_powerup() -> np.ndarray:
    d = 0.45
    vib = 1 + 0.03 * np.sin(2 * np.pi * 18 * t_axis(d))
    phase = np.cumsum((300 + 1200 * (t_axis(d) / d) ** 1.4) * vib) / SR
    x = osc(phase, "square", 0.4) * 0.5 + osc(phase * 0.5, "tri") * 0.5
    return x * env(len(x), 0.01, 1.2)


def sfx_death() -> np.ndarray:
    d = 1.2
    n = noise(d)
    x = lowpass(n, np.linspace(0.6, 0.01, len(n))) * 1.4
    x += osc(sweep_phase(420, 30, d, 0.5), "saw") * 0.5
    x += osc(sweep_phase(210, 20, d, 0.5), "square", 0.5) * 0.3
    return x * env(len(x), 0.002, 1.1)


def sfx_wave() -> np.ndarray:
    parts = []
    for f in (523.25, 783.99):
        d = 0.16
        s = osc(sweep_phase(f, f, d), "tri") * 0.6 + osc(sweep_phase(f * 2, f * 2, d), "sine") * 0.3
        parts.append(s * env(len(s), 0.004, 1.4))
    return np.concatenate(parts)


def sfx_ui() -> np.ndarray:
    d = 0.08
    x = osc(sweep_phase(880, 1320, d), "square", 0.5) * 0.5
    return x * env(len(x), 0.002, 1.5)


def sfx_dash() -> np.ndarray:
    d = 0.3
    n = noise(d)
    x = lowpass(n, np.linspace(0.03, 0.5, len(n))) * 1.5
    return x * env(len(x), 0.05, 2.0)


def sfx_spawn() -> np.ndarray:
    d = 0.35
    x = osc(sweep_phase(120, 480, d, 1.5), "tri") * 0.5 + osc(sweep_phase(121, 482, d, 1.5), "saw") * 0.2
    e = np.sin(np.pi * t_axis(d) / d) ** 2
    return lowpass(x, 0.3) * e


# ---------------------------------------------------------------- music
def music_loop() -> np.ndarray:
    """8-bar synthwave loop: kick, hats, saw bass arpeggio and a soft pad."""
    bpm = 118
    beat = 60 / bpm
    bars = 8
    total = int(bars * 4 * beat * SR)
    out = np.zeros(total)

    def add(sig: np.ndarray, start_s: float, gain: float) -> None:
        i = int(start_s * SR)
        j = min(total, i + len(sig))
        out[i:j] += sig[: j - i] * gain

    # chords: Am - F - C - G (two bars each), roots in Hz
    roots = [110.0, 87.31, 130.81, 98.0]
    chord_tones = [[0, 3, 7, 12], [0, 4, 7, 12], [0, 4, 7, 12], [0, 4, 7, 12]]
    kick_d = 0.25
    kick = osc(sweep_phase(140, 40, kick_d, 0.4), "sine") * env(int(kick_d * SR), 0.001, 2.0)
    hat_d = 0.04
    hat = (noise(hat_d) - lowpass(noise(hat_d), 0.6)) * env(int(hat_d * SR), 0.001, 3.0)

    for bar in range(bars):
        root = roots[(bar // 2) % 4]
        tones = chord_tones[(bar // 2) % 4]
        bar_t = bar * 4 * beat
        for b in range(4):
            add(kick, bar_t + b * beat, 0.9)
            add(hat, bar_t + b * beat + beat / 2, 0.25)
        # 16th-note bass arpeggio
        for s in range(16):
            semis = tones[s % 4]
            f = root * 2 ** (semis / 12)
            d = beat / 4
            sig = osc(sweep_phase(f, f, d), "saw") * 0.6 + osc(sweep_phase(f / 2, f / 2, d), "square", 0.5) * 0.3
            sig = lowpass(sig, 0.18) * env(len(sig), 0.003, 1.2)
            add(sig, bar_t + s * d, 0.45)
        if bar % 2 == 0:
            d = 8 * beat
            pad = np.zeros(int(d * SR))
            for semis in tones[:3]:
                f = root * 4 * 2 ** (semis / 12)
                pad += osc(sweep_phase(f, f, d), "saw") + osc(sweep_phase(f * 1.004, f * 1.004, d), "saw")
            ta = t_axis(d)
            pad_env = np.minimum(ta / 0.8, 1.0) * np.minimum((d - ta) / 0.8, 1.0)
            add(lowpass(pad, 0.05) * pad_env, bar_t, 0.08)
    return out


def main() -> None:
    os.makedirs(SFX_DIR, exist_ok=True)
    os.makedirs(MUSIC_DIR, exist_ok=True)
    print("Generating SFX ...")
    effects = {
        "shoot": (sfx_shoot, 0.55), "enemy_shoot": (sfx_enemy_shoot, 0.6), "hit": (sfx_hit, 0.6),
        "explode": (sfx_explode, 0.8), "player_hit": (sfx_player_hit, 0.85), "pickup": (sfx_pickup, 0.6),
        "powerup": (sfx_powerup, 0.6), "death": (sfx_death, 0.9), "wave": (sfx_wave, 0.6),
        "ui": (sfx_ui, 0.5), "dash": (sfx_dash, 0.6), "spawn": (sfx_spawn, 0.45),
    }
    for name, (fn, gain) in effects.items():
        write_wav(name, fn(), gain)

    print("Generating music loop ...")
    wav_path = os.path.join(SFX_DIR, "_music_tmp.wav")
    x = music_loop()
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.8
    with wave.open(wav_path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())
    ogg_path = os.path.join(MUSIC_DIR, "neon_loop.ogg")
    if shutil.which("ffmpeg"):
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path, "-c:a", "libvorbis", "-q:a", "4", ogg_path], check=True)
        os.remove(wav_path)
        print(f"  {ogg_path}")
    else:
        print("  ffmpeg not found; left WAV at", wav_path)


if __name__ == "__main__":
    main()
