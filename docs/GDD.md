# Game Design Document
## Wasteland Courier
### Death Stranding-Inspired Delivery Action Game

**Version:** 0.1 MVP
**Last Updated:** 2025-10-05
**Engine:** Godot 4.x
**Genre:** Survival Courier / Action / Procedural Open World
**Platform:** PC (Windows, Linux, Mac)
**Target Audience:** Fans of Death Stranding, Project Zomboid, survival games

---

## Table of Contents

1. [High Concept](#high-concept)
2. [Core Pillars](#core-pillars)
3. [Gameplay Loop](#gameplay-loop)
4. [Game Systems](#game-systems)
5. [Progression](#progression)
6. [World Design](#world-design)
7. [Technical Architecture](#technical-architecture)
8. [Development Phases](#development-phases)
9. [Reference Games](#reference-games)

---

## High Concept

**Elevator Pitch:**
> "Death Stranding meets Project Zomboid in a top-down post-apocalyptic courier simulator. Deliver cargo across a dangerous procedurally generated wasteland while managing survival needs, avoiding raiders, and building your reputation as a legendary courier."

**Core Experience:**
- Strategic route planning (safe vs. fast)
- Tense delivery missions with time limits
- Survival management (hunger, thirst, fatigue)
- Defensive combat (avoid when possible)
- Skill-based progression (get better through practice)
- Meaningful reputation system (high-value courier = bigger target)

**What Makes This Game Unique:**
1. **Inverse reputation system:** Success makes you a target
2. **Delivery-focused gameplay:** Combat is secondary to logistics
3. **Resource-driven architecture:** Beginner-friendly .tres files
4. **Procedural world with purpose:** Every delivery is unique
5. **Project Zomboid-style skills:** Practice makes perfect

---

## Core Pillars

### 1. Delivery First
- Primary gameplay is completing delivery contracts
- Combat exists to threaten deliveries, not as main focus
- Success measured by completed contracts, not kills
- Players should feel like couriers, not soldiers

### 2. Survival Under Pressure
- Hunger, thirst, fatigue affect performance
- Resource scarcity creates tension
- Time limits force difficult decisions
- Death has meaningful consequences

### 3. Risk vs. Reward
- Higher tier contracts = better pay, more danger
- High reputation = better contracts, more ambushes
- Fast route = dangerous, slow route = safe
- Fighting vs. fleeing both viable strategies

### 4. Skill-Based Progression
- Driving skill improves fuel efficiency
- Combat skill improves accuracy
- Fitness skill increases carry capacity
- Mechanical skill reduces repair costs

### 5. Beginner-Friendly Development
- .tres resource files for easy modding
- Clear separation of data and logic
- Component-based architecture
- Extensive documentation

---

## Gameplay Loop

### **Core Loop (5-30 minutes per delivery):**

```
1. Visit Settlement
   ↓
2. Accept Contract (choose tier based on reputation)
   ↓
3. Load Cargo into Inventory/Vehicle
   ↓
4. Plan Route (fast & dangerous vs. slow & safe)
   ↓
5. Drive/Walk to Destination
   ├─ Manage fuel
   ├─ Manage survival needs
   ├─ Avoid/fight raiders
   └─ Refuel at gas stations
   ↓
6. Deliver Cargo
   ↓
7. Receive Payment + Reputation
   ↓
8. Auto-Save (when near settlement)
   ↓
[LOOP REPEATS]
```

### **Extended Loop (1-2 hours):**
- Complete multiple contracts
- Upgrade vehicle or buy new vehicle
- Improve skills through use
- Unlock higher tier contracts
- Explore POIs for loot

### **Session Goals:**
- Short session (30 min): 1-2 contracts
- Medium session (1-2 hours): 3-5 contracts, upgrade vehicle
- Long session (3+ hours): Grind reputation, explore world

---

## Game Systems

### 1. Player Character

**Movement:**
- Top-down perspective
- WASD movement (8-directional or free)
- Walk speed: 100 px/sec
- Sprint speed: 175 px/sec (hold Shift)
- Rotation: Face mouse cursor

**Inventory:**
- Grid-based: 8 columns × 6 rows
- Items have size (e.g., 2×2, 1×3)
- Item rotation (R key)
- Weight affects movement speed
- Weight capacity: 60kg base (+ 5kg per Fitness level)

**Survival:**
- Hunger: 0-100 (depletes over time)
- Thirst: 0-100 (depletes faster than hunger)
- Fatigue: 0-100 (depletes with activity)
- Health: 100 HP (no regen)

**Skills:**
- Driving (0-10)
- Fitness (0-10)
- Mechanical (0-10)
- Combat (0-10)

---

### 2. Vehicle System

**Vehicles:**
- **Delivery Van** (starter): Balanced stats
- **Motorcycle** (optional): Fast, fragile, small storage
- **Heavy Truck** (optional): Slow, durable, huge storage

**Physics:**
- Realistic acceleration/braking
- Turn radius based on speed
- Momentum/drift
- Fuel consumption

**Vehicle Stats (example: Delivery Van):**
```
Max Speed: 80 kph
Acceleration: 120
Turn Speed: 2.5
Fuel Capacity: 50 L
Fuel Consumption: 0.5 L/km
Storage: 12×8 grid
Max HP: 100
```

**Enter/Exit:**
- Press F near vehicle to enter
- Press F in vehicle to exit
- Player hidden when driving

**Camera:**
- 8-quadrant racing camera (from OLD_CODE)
- Speed-based zoom
- Lookahead prediction
- Smooth velocity tracking

---

### 3. Inventory & Items

**Grid System:**
- Tetris-style inventory
- Items occupy multiple cells
- Drag-and-drop
- Rotate items (R key)
- Auto-stack stackable items
- Drop items to ground (D key while hovering)
- Pick up ground items (F key with arrow/scroll wheel selection)

**Item Types:**

**Consumables:**
- Food (restores hunger)
- Water (restores thirst)
- Coffee (restores fatigue)
- Medkit (restores health)

**Weapons:**
- Pistol (2×2, 1.2kg)
- Shotgun (3×1, 3.5kg)
- Assault Rifle (4×2, 4.0kg)

**Ammo:**
- 9mm (stackable, 0.1kg each)
- 12_gauge (stackable, 0.2kg each)
- 762 (stackable, 0.15kg each)

**Cargo:**
- Contract-specific items
- Various sizes and weights
- Fragile items take damage

---

### 4. Contract System

**Tiers:**

**Tier 1: Novice (0+ rep)**
- Distance: 5-15 km
- Payment: 8 credits/km
- Time Limit: 20 minutes
- Cargo: Common items

**Tier 2: Experienced (100+ rep)**
- Distance: 15-30 km
- Payment: 15 credits/km
- Time Limit: 30 minutes
- Cargo: Valuable items

**Tier 3: Expert (300+ rep)**
- Distance: 30-60 km
- Payment: 25 credits/km
- Time Limit: 45 minutes
- Cargo: High-value items

**Failure Consequences:**
- Lose reputation (-5 to -30 based on tier)
- Pay cargo value (50-100% based on tier)
- Go into debt if insufficient funds
- Cannot accept new contracts while in debt

---

### 5. World Generation

**Chunk System:**
- Chunk size: 1024×1024 pixels
- Load radius: 3 chunks
- Unload distance: 4 chunks
- Seed-based generation (reproducible)

**Biomes:**
1. **Wasteland** (60%): Desert, moderate danger
2. **Radioactive Zone** (40%): Toxic, high danger

**Points of Interest (POIs):**
- **Settlements:** 10 km apart (~170,000 pixels)
- **Gas Stations:** Every 3-5 km
- **Warehouses:** Random loot, raiders (Phase 4)
- **Bandit Camps:** High-value loot, many enemies (Phase 4)

**Generation:**
- FastNoiseLite for terrain
- Grid-based POI placement
- Minimum distance enforcement

---

### 6. Combat System

**Philosophy:**
- Combat is **defensive**, not offensive
- Fleeing is often the best option
- Ammo is limited and valuable
- Death has severe consequences

**Player Combat (On Foot Only):**
- Mouse cursor aiming
- Left click to shoot
- R to reload
- Cannot shoot while driving

**Weapons:**
- Pistol: Medium damage, fast fire rate
- Shotgun: High damage, slow fire rate, spread
- Assault Rifle: Fast auto-fire, moderate damage

**Enemy AI:**
- Raiders: Chase and attack player
- Detection: Line of sight + sound
- Spawning: Danger zones only (not near settlements)

**Vehicle Ramming:**
- Damage to enemy: Speed × 0.5
- Damage to vehicle: 10% of dealt damage
- Minimum speed: 20 kph

---

### 7. Reputation System

**Gain Reputation:**
- Complete contract on time: +10
- Complete early (>20% time left): +15
- Deliver fragile cargo undamaged: +5
- Complete Tier 3: +20

**Lose Reputation:**
- Fail contract: -5 to -30 (tier-based)
- Damage fragile cargo: -10
- Go into debt: -5

**Effects:**
- **Contract Access:** Tier unlocks at 100, 300 rep
- **Ambush Frequency (Inverse):**
  - Low rep (0-99): 10% ambush chance
  - Medium rep (100-299): 25% ambush chance
  - High rep (300+): 40% ambush chance
- **Settlement Prices:** Discount at high rep

**Rationale:** High-value couriers attract raiders

---

### 8. Survival Mechanics

**Hunger:**
- Depletion: -1 per 2 minutes
- < 30: -15% movement speed
- 0: -1 HP per 10 seconds

**Thirst:**
- Depletion: -1 per 90 seconds
- < 30: Screen desaturation
- 0: -2 HP per 10 seconds

**Fatigue:**
- Depletion: -1 per 5 minutes (passive)
- Sprinting: -5 per minute
- Driving: -2 per minute
- < 30: Cannot sprint
- 0: Forced sleep (collapse)

**Sleep:**
- Settlements: Safe, free
- Vehicle: Risky, can be robbed
- Duration: 6 seconds real-time
- Restores fatigue fully

---

### 9. Skill System

**Driving (0-10):**
- XP: 1 per 100 pixels driven
- Bonuses: +2% fuel efficiency, +1 kph speed, +3% turn sharpness per level

**Fitness (0-10):**
- XP: 1 per 10 sec sprinting, 2 per min over-encumbered
- Bonuses: +5kg capacity, +10% sprint duration, +2% sprint speed per level

**Mechanical (0-10):**
- XP: 10 per refuel, 25 per repair
- Bonuses: -5% refuel time, +5% repair effectiveness per level

**Combat (0-10):**
- XP: 2 per shot, 5 per hit, 50 per kill
- Bonuses: -5% reload time, -8% weapon sway, -5% recoil per level

**Level Requirements:**
```
Level 1: 100 XP    Level 6: 1400 XP
Level 2: 250 XP    Level 7: 1900 XP
Level 3: 450 XP    Level 8: 2500 XP
Level 4: 700 XP    Level 9: 3200 XP
Level 5: 1000 XP   Level 10: 4000 XP
```

---

## Progression

### Short-Term (Per Session)
- Complete 1-5 contracts
- Earn 200-1000 credits
- Gain 10-50 reputation
- Level up 1-2 skills

### Medium-Term (5-10 hours)
- Unlock Tier 2 contracts (100 rep)
- Upgrade vehicle (engine, fuel tank, storage)
- Max out 1-2 skills
- Explore multiple biomes

### Long-Term (20+ hours)
- Unlock Tier 3 contracts (300 rep)
- Purchase additional vehicles
- Max out all skills
- Discover all POI types
- Achieve highest reputation title

---

## World Design

### Scale
- 1 km = ~10,000 pixels
- Settlement spacing: 10 km = ~170,000 pixels
- Driving 60 kph = ~167 pixels/sec
- 10 km journey = ~17 minutes real-time at 60 kph

### Procedural Generation
- Seed-based (same seed = same world)
- Noise-based biome distribution
- Guaranteed POI placement (minimum distances)
- No hand-crafted content (all procedural)

### Save System
- Manual save/load (K/L keys)
- Auto-save disabled by default (configurable)
- 5-second cooldown prevents spam
- Saves player state, inventory, vehicle, contracts, world seed
- JSON format: `user://save_game.json`
- Single save slot (MVP), multiple slots (Phase 4)

### Ground Item System
- Drop items from inventory (D key)
- Items spawn as WorldItem nodes with visual representation
- Pickup prompt UI shows nearby items (80px radius)
- Scroll wheel or arrow keys (↑↓) to select
- Press F to pick up selected item
- Multiple items can be dropped in same area

### DreadClock System (3-Band Night Cycle)
- **Time Loop**: Always night, 18:00 → 05:59 → resets to 18:00
- **Three Time Bands**:
  - **Calm** (18:00-23:59): Lower threat, normal visibility, worst economy
  - **Hunt** (00:00-02:59): Peak danger, reduced visibility, best payouts
  - **False Dawn** (03:00-05:59): Safest period, best visibility, most scarcity
- **Global Scalars** (readable by all systems):
  - `danger_mult`: Affects spawns/aggro/accuracy
  - `visibility_mult`: Ambient brightness/fog
  - `economy_mult`: Payouts/repair costs
  - `scarcity_mult`: Loot/shop stock availability
- **Visual Effects**:
  - Ambient color overlay shifts per band (bluish → dark → warm)
  - Dynamic vignette intensity (20% → 50% → 10%)
  - Smooth 2-second transitions between bands
  - Loop reset glitch at 06:00 (screen shake + flash)
- **Resource-Driven**: All settings in .tres config files
- **Signals**: `band_changed`, `loop_reset`, `time_changed`
- **Documentation**: See `docs/specific_systems/system_DreadClock.md` for full spec and future integration plans

---

## Technical Architecture

### File Structure
```
res://
├── actors/           # Player, enemies, vehicles
├── components/       # Reusable component scripts
├── resources/        # All .tres data files
├── systems/          # Game systems (managers)
├── scenes/           # .tscn scene files
├── ui/               # UI scenes and scripts
├── assets/           # Textures, audio, fonts
├── autoload/         # Singleton scripts
├── tests/            # Test scenes
└── docs/             # All documentation
```

### Resource-Driven Design
- **Data in .tres files:** Items, contracts, vehicles, biomes
- **Logic in scripts:** Components, systems, AI
- **Separation of concerns:** Easy to modify, beginner-friendly
- **Hot-reloading:** Change .tres files in editor, see results instantly

### Coding Standards
- **Naming:** snake_case for files and variables
- **Type hints:** Always use static types
- **Indentation:** Tabs (Godot default)
- **Comments:** Only for complex logic, self-documenting code preferred
- **Signals:** Use for decoupling systems

### Component-Based Architecture
- Small, focused components (HealthComponent, InventoryComponent)
- Attach to entities as needed
- Configured via @export parameters
- Reusable across player, enemies, vehicles

---

## Development Phases

### **Phase 1: Core Delivery Loop** (Week 1-2)
- Player movement
- Vehicle driving
- Grid-based inventory
- Procedural world generation
- Basic contract system
- Auto-save
- DreadClock system (3-band night cycle with visual/audio atmosphere)

**Goal:** Complete one full delivery from settlement A to settlement B in a looping night environment

### **Phase 2: Survival & Progression** (Week 3)
- Hunger/thirst/fatigue mechanics
- Consumable items (food, water, coffee)
- Skill system (4 skills)
- Contract tiers (1, 2, 3)
- Time limits & failure consequences
- Reputation system

**Goal:** Add depth, make deliveries strategic

### **Phase 3: Danger & Combat** (Week 4)
- Enemy AI (raiders)
- Player combat (weapons, shooting)
- Vehicle ramming
- Ambush system
- Health & healing
- Vehicle damage & repair

**Goal:** Add risk, make world dangerous

### **Phase 4: Polish & Depth** (Week 5+, Optional)
- Vehicle variety (motorcycle, truck)
- Vehicle upgrades
- Expanded POIs (warehouses, camps)
- Contract variety (fragile, urgent, escort)
- Weather system
- Map & navigation
- Radio/music system
- Permadeath mode

**Goal:** Add variety, replayability, polish

---

## Reference Games

### Primary Inspirations

**Death Stranding (Kojima Productions)**
- Delivery-focused gameplay
- Strategic route planning
- Cargo management
- Traverse dangerous terrain
- **Differentiation:** Top-down, procedural, combat is defensive

**Project Zomboid (The Indie Stone)**
- Skill progression through use
- Survival mechanics (hunger, thirst, fatigue)
- Grid-based inventory
- Vehicle gameplay
- **Differentiation:** Not zombie survival, delivery-focused

**FTL: Faster Than Light (Subset Games)**
- Resource management
- Risk vs. reward decisions
- Procedural events
- Permadeath (optional mode)
- **Differentiation:** Real-time, open world, vehicle-based

**Euro Truck Simulator 2 (SCS Software)**
- Driving simulation
- Delivery contracts
- Vehicle upgrades
- Fuel management
- **Differentiation:** Post-apocalyptic, survival, combat

### Secondary Influences
- **Tarkov (Battlestate Games):** Grid inventory, risk of losing cargo
- **Resident Evil 4:** Inventory Tetris
- **Mad Max:** Post-apocalyptic vehicle aesthetic
- **The Long Dark:** Survival resource management

---

## Design Principles

### What This Game IS:
✅ A strategic courier simulator
✅ A survival game with purpose (deliveries)
✅ A risk/reward decision-making experience
✅ A skill-based progression game
✅ Beginner-developer friendly (resource-driven)

### What This Game IS NOT:
❌ A combat-focused shooter
❌ A narrative-driven story game
❌ A multiplayer PvP game (MVP)
❌ A base-building/crafting game (MVP)
❌ A hand-crafted open world (all procedural)

---

## Success Metrics (MVP Goals)

**Gameplay:**
- Average contract completion time: 5-15 minutes
- Contract failure rate: 20-30% (challenging but fair)
- Player death rate: < 10% per session (combat is avoidable)

**Engagement:**
- Session length: 30-120 minutes
- Contracts per session: 2-8
- Skill progression: 1-2 levels per hour

**Technical:**
- Stable 60 FPS on mid-range PC
- No crashes during chunk loading
- Save/load works 100% of time
- Procedural world consistent from seed

**Development:**
- Phase 1 complete in 2 weeks
- Phase 2 complete in 1 week
- Phase 3 complete in 1 week
- Phase 4 features added iteratively

---

## Known Scope Limitations (MVP)

**Not Included in MVP:**
- Multiplayer/co-op
- Story/narrative campaign
- Hand-crafted missions
- Crafting system
- Base building
- Faction system
- Companion NPCs
- Boss enemies
- Modding support (future)

**Post-MVP Considerations:**
- Community feedback will guide Phase 4 priorities
- Some Phase 4 features may be cut if not fun
- Modding support via .tres files is inherent
- Multiplayer would require complete rewrite (not planned)

---

## Changelog

**Version 0.1 (2025-10-05):**
- Initial GDD created
- All 4 phases documented
- Technical architecture defined
- Coding standards established

---

## Document Control

**Owner:** Development Team
**Reviewers:** N/A (Solo/Small Team)
**Next Review Date:** After Phase 1 completion
**Status:** Living Document (updated as game evolves)

---

**End of Game Design Document**
