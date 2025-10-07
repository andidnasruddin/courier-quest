# SYSTEM_DREADCONE — Player & Vehicle Visibility

**Goal:** Darkwood-style tunnel vision that creates risk when sprinting/aiming and tension while driving.

**Scope:** Low (foundation now), deepen in Phases 2–4.

**Depends on:** Dreadclock (Calm / Hunt / False Dawn bands).

---

## 1) Summary
A cone-based visibility system tied to player intent (walk, sprint, aim) and vehicle lighting (low/high beams). Camera subtly leads in the direction of travel/aim to reduce rear awareness. Visual treatment (vignette + outside-cone dim) sells fear without heavy tech.

---

## 2) Core Rules (Foundation — ship now)
### On-foot (cone centered on cursor)
- **Walk:** **100°** FOV
- **Sprint:** **70°** FOV (tunnel vision)
- **Aim weapon:** **58°** FOV (default)
- **State transitions:** ~**0.12s** ease-in/out; never instant pop

### Camera behavior
- **Walk:** centered, light smoothing
- **Sprint:** camera **leads toward cursor** ~**20% of viewport**; rear space feels unsafe
- **Aim:** camera lead ~**10%**; slight zoom-in (≤ **5%**) for focus
- **Quick Look-Back (optional, foundation):** tap/hold to flip cone **180°** for **0.25s**; movement briefly damped; cooldown 1.0s

### Visual treatment
- **Vignette strength** scales with narrower FOV: Walk (low) → Sprint (med) → Aim (high)
- **Outside cone luminance:** ~**25%** (never pure black), soft edge, no hard occluders yet
- **Band cue:** small vignette/contrast shift on Dreadclock band change

### Vehicles (truck)
- **Low beams:** **90°** cone, medium-long range
- **High beams:** **120°** cone, longer range but **+30% enemy detection radius during Hunt** (risk/reward)
- **Speed tunnel:** at top speed, temp **narrow to ~75°**; relax on braking
- **Camera lead:** scales with speed up to **25%** of viewport; brief lag on stop for weight

**Definition of Done (foundation):**
- On-foot states swap cleanly; camera lead works; vehicle beams feel distinct; vignette sells the effect without dropping FPS.

---

## 3) Integration by Phase
### Phase 2 — Survival / Progression hooks
- **Stamina tie-in:** Sprinting drains faster when cone is narrow; recovery widens vignette gradually
- **Consumables:**
  - **Flares:** 360° light bubble for 8–10s that **disables cone** inside radius but greatly increases aggro radius
  - **Batteries:** widen Walk to **110°** for 20s (no Aim change)
- **Comfort toggles (accessibility):** optional **+10° global FOV**, **−50% camera lead**, vignette strength slider

### Phase 3 — Danger / Combat hooks
- **AI reads cone width only** (no new behavior trees):
  - During **Hunt**, enemies flank more aggressively and react to sprint noise faster
  - **Stalkers** attempt to linger at cone edge (design flavor)
- **Sound discipline:** Sprinting increases footstep sound radius and briefly pings enemies just outside cone
- **Weapon nuance:**
  - Pistols Aim at **60°**; Shotguns **65°**; Rifles **52–55°**
- **Rear threat cue:** very faint one-frame silhouette flash at cone edge when a hostile crosses behind (not a reveal)

### Phase 4 — Polish / Depth
- **Edge hallucinations:** rare periphery “movement” during Hunt
- **Weather:** rain/fog slightly narrows vehicle cones; wet roads add high-beam glare
- **Rearview (vehicle):** hold to show a thin rearview strip for **0.3s**; during that, forward cone narrows further (trade awareness for risk)

---

## 4) Balancing — Starting Values
| State            | FOV (deg) | Vignette Strength | Camera Lead |
|------------------|:---------:|:-----------------:|:-----------:|
| Walk             |   100     |      Low          |    0%       |
| Sprint           |    70     |     Medium        |   20%       |
| Aim (default)    |    58     |       High        |   10%       |
| Vehicle Low Beam |    90     |     Vehicle tint  |   10–25%*   |
| Vehicle High Beam|   120     |     Vehicle tint  |   10–25%*   |

*Lead scales with speed (max 25%).

**Band interaction (with Dreadclock):**
- **Hunt:** high beams add **+30%** enemy detection radius; optional −5° effective visibility due to atmospheric darkness
- **False Dawn:** +5° effective visibility on-foot; vehicle glare slightly reduced

---

## 5) Tuning Cheats
- Too blind? **Walk +10°**, vignette −5%.
- Sprint too safe? **Sprint 65°**, camera lead **+25%**.
- Aim camping too strong? Add **slow camera drift** while aiming and louder handling SFX.
- Driving trivial? Increase Hunt high-beam detection to **+40%** and reduce low-beam range by ~10%.

---

## 6) Risks & Mitigations
- **Motion sickness:** provide comfort toggles (lead reduction, vignette slider)
- **Over-darkness:** maintain 25% luminance outside cone; avoid true black until Phase 4 if ever
- **Mobile perf:** prefer overlay + vignette over dynamic shadows until later phases

---

## 7) QA & Telemetry
- **Log:** time in each FOV state, deaths by state, enemy contacts from rear, collisions by beam type
- **Acceptance:**
  - State transitions < 150 ms without stutter
  - Cone direction always matches cursor / facing
  - ≥ 30/60 FPS targets maintained on test devices

---

## 8) Anti‑Scope (Do NOT add now)
- No dynamic occluders/shadow casting
- No per-enemy bespoke visibility rules
- No extra HUD indicators beyond clock/badge

---

## 9) Open Questions
- Should batteries also reduce vignette briefly?
- Do certain weapons (e.g., scopes) apply a temporary zoom rather than further narrowing?

---

## 10) Changelog
- **v0.1 (Foundation):** Walk/Sprint/Aim cones, camera lead, vehicle beams, vignette, Hunt high-beam aggro
- **v0.2 (Phase 2 hooks):** stamina tie-in, consumables, comfort toggles
- **v0.3 (Phase 3 hooks):** cone-aware AI responses, weapon-specific Aim cones, rear threat cue
- **v0.4 (Phase 4 polish):** edge hallucinations, weather effects, rearview mechanic

