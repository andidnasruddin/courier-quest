# Dreadclock — 3-Band Night Cycle

**Scope:** Low (foundation now, deepen later)  
**Loop:** Always night. Time repeats 18:00 → 06:00 (snap back to 18:00).  
**Bands:** Calm (18:00–23:59) → Hunt (00:00–02:59) → False Dawn (03:00–05:59)

---

## 1) Purpose & Pillars
- **Mood-first:** Silent-Hill-style limbo; it’s always night.
- **Clarity:** 3 distinct time bands that *feel* different without complex logic.
- **Scalability:** Simple global scalars today; systems hook in later.

---

## 2) Player-Facing Fiction
A trucker trapped on an endless highway in a looping night. Time “thins” before dawn, then reality snaps back to 18:00.

---

## 3) Core Spec

### Bands
- **Calm (18:00–23:59):** lower threat, best visibility.
- **Hunt (00:00–02:59):** peak threat, darker feel.
- **False Dawn (03:00–05:59):** safest, slight horizon glow.

### Global Scalars (read-only to other systems)
- `danger_mult` — affects spawns/aggro/accuracy.
- `visibility_mult` — ambient brightness/fog bias.
- `economy_mult` — payouts/repair value bias.
- `scarcity_mult` — loot/shop stock bias.

**Default values (tune later):**
| Band       | danger | visibility | economy | scarcity |
|------------|:------:|:----------:|:-------:|:--------:|
| Calm       | 0.8    | 1.00       | 0.90    | 0.90     |
| Hunt       | 1.5    | 0.90       | 1.20    | 1.10     |
| False Dawn | 0.6    | 1.15       | 1.00    | 1.30     |

### Events (for other systems to subscribe to)
- `on_band_changed(Calm|Hunt|FalseDawn)`
- `on_loop_reset(06:00 → 18:00 snap)`

### Minimal UI
- Small digital clock (24h).
- Tiny badge: **Calm / Hunt / Dawn**.

---

## 4) Foundation (Add Now)
- Global clock that loops 18:00→06:00.
- Set the 3 bands + scalars above.
- Simple visual curve (darker in Hunt, slight lift in Dawn).
- Band-change stinger SFX + vignette tweak.
- Hard snap at 06:00 (brief glitch) back to 18:00.

**Definition of Done:** Bands flip correctly, visuals/SFX sell the shift, scalars are readable, loop snap works.

---

## 5) Integration by Phase

### Phase 2 — Survival/Progression
- Rest effectiveness: best in **False Dawn**; risk of ambush outside it.
- Vendors/windows: repairs open in **Calm/Dawn**; black-market appears in **Hunt**.
- Contracts: bonus for “Deliver before False Dawn.” Lower pay after 03:00 but safer travel.
- Fuel/consumables: small efficiency nerf during **Hunt** (pressure).

### Phase 3 — Danger/Combat
- AI reads only `danger_mult` (no new trees):
  - **Hunt:** +first-shot accuracy, larger sound response.
  - **Dawn:** slower reacquire, fewer ambushes.
- Spawn flavor:
  - **Calm:** more patrols, fewer ambush points.
  - **Hunt:** checkpoints/roadblocks; rare stalkers.
  - **Dawn:** minimal ambush, occasional tailing unit.
- Light tradeoff: headlights improve handling always, but **Hunt** increases aggro radius sharply.

### Phase 4 — Polish/Depth
- Hour-based ambience beds (engines → whispers → wind/birds-glitch).
- Subtle horizon glow in **False Dawn**; instant blackout at snap.
- Small “limbo anomalies” at fixed minutes (e.g., phantom convoy at 00:13).

---

## 6) Tuning Cheats
- Too easy? Raise Hunt `danger` to **1.7** or boost headlight aggro in Hunt.
- Players skip Hunt? Add **high-pay, time-limited** contracts spawning 23:00–01:00.
- Dawn ignored? Pause **rep decay** and allow **free quick-repair** only in False Dawn.

---

## 7) Telemetry & QA
- Track time in band, deaths by band, contracts completed per band.
- Acceptance: ≥95% correct band transitions across 100 loops; no UI desync; no stuck-in-band bugs after snap.

---

## 8) Anti-Scope (Do NOT add now)
- No per-enemy/per-item bespoke schedules.
- No complex dynamic shadows; keep it overlay + curve until Phase 3–4.
- No calendar/holidays/extra day parts.

---

## 9) Open Questions
- Should certain NPCs only appear in False Dawn?
- Do settlements “remember” you across loops, or does lore prefer amnesia?

---

## 10) Changelog
- v0.1 (Foundation): Bands, scalars, UI, snap.
- v0.2 (Phase 2 hooks): Vendors, contracts, rest.
- v0.3 (Phase 3 hooks): AI/scarcity/spawn flavor.
- v0.4 (Phase 4 polish): Audio/anomalies/visuals.
