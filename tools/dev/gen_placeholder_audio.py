"""Generates the template's placeholder sounds (CC0, made from scratch).

Run: python tools/dev/gen_placeholder_audio.py
Replace the files in assets/audio/ with real sounds (e.g. Kenney audio packs) whenever you like.
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
ROOT = Path(__file__).resolve().parents[2] / "assets" / "audio"


def write(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32000)) for s in samples))


def tone(freq_start, freq_end, dur, wave_kind="square", vol=0.5, attack=0.005, release=0.05):
    out, phase = [], 0.0
    n = int(RATE * dur)
    for i in range(n):
        t = i / n
        freq = freq_start + (freq_end - freq_start) * t
        phase += freq / RATE
        if wave_kind == "square":
            v = 1.0 if (phase % 1.0) < 0.5 else -1.0
        elif wave_kind == "triangle":
            v = 4 * abs((phase % 1.0) - 0.5) - 1
        elif wave_kind == "noise":
            v = random.uniform(-1, 1)
        else:
            v = math.sin(2 * math.pi * phase)
        sec = i / RATE
        env = min(1.0, sec / attack) * min(1.0, (dur - sec) / release)
        out.append(v * vol * env)
    return out


def notes(seq, dur, kind="square", vol=0.35):
    out = []
    for f in seq:
        out += tone(f, f, dur, kind, vol) if f else [0.0] * int(RATE * dur)
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] if i < len(t) else 0.0 for t in tracks) for i in range(n)]


random.seed(7)
write(ROOT / "sfx" / "click.wav", tone(900, 700, 0.05, "square", 0.25, release=0.03))
write(ROOT / "sfx" / "jump.wav", tone(300, 750, 0.16, "square", 0.3))
write(ROOT / "sfx" / "coin.wav", tone(988, 988, 0.06, "square", 0.3) + tone(1319, 1319, 0.18, "square", 0.3))
write(ROOT / "sfx" / "hit.wav", mix(tone(220, 60, 0.25, "square", 0.35), tone(0, 0, 0.2, "noise", 0.25)))
write(ROOT / "sfx" / "win.wav", notes([523, 659, 784, 1047], 0.12, vol=0.3) + tone(1047, 1047, 0.3, "square", 0.3))
write(ROOT / "sfx" / "lose.wav", notes([392, 330, 262], 0.16, vol=0.3) + tone(196, 150, 0.4, "square", 0.3))

# 8-bar loop at 120 bpm: melody + bass, about 8 seconds.
C4, D4, E4, F4, G4, A4, B4, C5 = 262, 294, 330, 349, 392, 440, 494, 523
beat = 0.25
melody = [E4, G4, A4, G4, E4, D4, C4, 0, E4, G4, A4, C5, B4, A4, G4, 0,
          F4, A4, C5, A4, G4, E4, D4, 0, E4, D4, C4, D4, E4, D4, C4, 0]
bass = [C4 // 2, C4 // 2, A4 // 4, A4 // 4, F4 // 2, F4 // 2, G4 // 2, G4 // 2]
music = mix(notes(melody, beat, "square", 0.16), notes([b for b in bass for _ in range(4)], beat, "triangle", 0.3))
write(ROOT / "music" / "theme.wav", music)
print("wrote audio to", ROOT)
