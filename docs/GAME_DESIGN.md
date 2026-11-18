# Neon Drift: Game Design

**Core loop:** move and shoot to survive escalating waves of neon enemies, chaining kills to build a score multiplier.

- **Lose:** health (5 pips) reaches zero. There's no win state: it's an endless score attack, and the best score is saved locally.
- **Camera:** fixed, top-down, framing the whole 1216×656 arena (never rotates; screen shake only).

## Controls
| Input | Action |
|---|---|
| WASD / Arrow keys | Move (top speed 370 px/s in ~0.11 s, stops in ~0.14 s) |
| Mouse | Aim |
| Hold left click | Shoot |
| Esc / P | Pause / resume |
| R (paused / game over) | Restart |
| M | Mute |
| Touch: left half | Virtual stick: move |
| Touch: right half | Aim at the finger and fire |

## Entities
| Entity | Behaviour | Readability |
|---|---|---|
| Player | Twin-stick ship, 5 HP, 1.2 s invulnerability after a hit | Cyan, engine trail, blinks while invulnerable |
| Chaser (wave 1+) | Homes in with a wobble | Pink diamond |
| Dasher (wave 2+) | Approaches, winds up for 0.7 s with an aim line, then dashes | Yellow arrow, flickering telegraph line |
| Shooter (wave 3+) | Keeps ~340 px away, strafes, fires slow red shots | Green hexagon, glows red before firing |
| Splitter (wave 4+) | Slow and tanky (6 HP); bursts into 3 fast minis | Orange square, cracks as it takes damage |
| Health pickup | +1 HP | Green cross |
| Rapid fire pickup | 6 s of faster fire with a slight spread | Yellow bolt; the ship tints gold |

## Systems
- **Waves:** point budget `5 + 3.2·n`. Each new enemy type is introduced on its own wave with a banner hint. Spawns are telegraphed for 0.85 s and placed at least 280 px from the player. Clearing a wave gives a bonus.
- **Combo:** every 4 kills inside 2.5 s of each other raises the multiplier (up to ×8). Taking a hit or letting the timer lapse resets it.
- **Juice:** trauma-based screen shake, white hit flash, 70 ms hit-stop when the player is hurt, particle bursts with shockwave rings, floating score text, tweens on spawn, UI pops, and slow motion on death.
- **Rendering:** vector neon drawn with layered glow strokes, plus a full-screen post shader (bloom, chromatic aberration, vignette, scanlines, damage flash). Runs on the Compatibility (WebGL 2) renderer.
- **Audio:** 12 SFX and a music loop, all generated procedurally by `scripts/generate_audio.py`.
