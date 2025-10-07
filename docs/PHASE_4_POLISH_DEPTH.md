# Phase 4: Polish & Depth

**Goal:** Enhance player experience with variety, polish, and optional advanced features
**Timeline:** Week 5+ (Ongoing)
**Status:** Not Started
**Dependencies:** Phase 1, 2, 3 must be complete
**Note:** This phase is **optional** and can be developed iteratively based on playtesting feedback

---

## Overview

Phase 4 focuses on making the game feel more complete, varied, and replayable. These features add depth without changing the core gameplay loop. Many of these systems can be implemented independently, allowing for flexible prioritization based on player feedback.

---

## Enhancement Categories

### 1. Vehicle Variety & Upgrades

**Goal:** Give players meaningful choices in how they approach deliveries

**New Vehicle Types:**

#### **Motorcycle**
```gdscript
# resources/vehicles/examples/motorcycle.tres
vehicle_name = "Wasteland Motorcycle"
max_speed = 120.0  # Faster than van
acceleration = 200.0  # Quick acceleration
turn_speed = 4.0  # Nimble handling
fuel_capacity = 25.0  # Half of van
fuel_consumption = 0.3  # More efficient
storage_grid_size = Vector2i(6, 4)  # Much smaller storage
max_health = 60.0  # More fragile
cost = 800  # Cheaper than van
```

**Pros:** Fast, fuel-efficient, great for small contracts
**Cons:** Small storage, fragile, poor for heavy cargo

#### **Heavy Truck**
```gdscript
# resources/vehicles/examples/heavy_truck.tres
vehicle_name = "Heavy Cargo Truck"
max_speed = 50.0  # Slow
acceleration = 60.0  # Sluggish
turn_speed = 1.5  # Poor handling
fuel_capacity = 100.0  # Double capacity
fuel_consumption = 1.0  # Thirsty
storage_grid_size = Vector2i(16, 12)  # Massive storage
max_health = 200.0  # Tank-like
cost = 3000  # Expensive
```

**Pros:** Huge storage, durable, fuel lasts longer
**Cons:** Slow, poor handling, expensive fuel costs

**Vehicle Purchase System:**
- Buy vehicles at settlements (new shop UI)
- Keep multiple vehicles in "garage"
- Choose vehicle before starting contract
- Abandoned vehicles can be recovered at settlements (for a fee)

**Vehicle Upgrades:**

**Engine Upgrade:**
- Level 1: +10% max speed (500 credits)
- Level 2: +20% max speed (1000 credits)
- Level 3: +30% max speed (2000 credits)

**Fuel Tank Upgrade:**
- Level 1: +20% capacity (400 credits)
- Level 2: +40% capacity (800 credits)
- Level 3: +60% capacity (1500 credits)

**Cargo Space Upgrade:**
- Level 1: +2 rows storage (600 credits)
- Level 2: +4 rows storage (1200 credits)
- Level 3: +6 rows storage (2400 credits)

**Armor Plating:**
- Level 1: +25% max HP (700 credits)
- Level 2: +50% max HP (1400 credits)
- Level 3: +75% max HP (2800 credits)

**Suspension Upgrade:**
- Level 1: +10% turn speed (300 credits)
- Level 2: +20% turn speed (600 credits)
- Level 3: +30% turn speed (1200 credits)

**Implementation Priority:** MEDIUM (Adds variety to gameplay)

---

### 2. Expanded POI Types

**Goal:** Make the world feel more alive and varied

#### **Abandoned Warehouse**
- Contains random loot (items, ammo, fuel)
- May have 1-2 raiders guarding
- Risk/reward: Worth exploring, but dangerous
- Respawns loot every X in-game hours

```gdscript
# resources/world/examples/poi_warehouse.tres
poi_name = "Abandoned Warehouse"
poi_type = POIData.Type.WAREHOUSE
loot_tier = POIData.LootTier.MEDIUM
enemy_count = Vector2i(1, 3)  # 1-3 enemies
loot_respawn_time = 3600.0  # 1 hour real-time
```

#### **Bandit Camp**
- 3-5 raiders
- High-value loot (weapons, rare items)
- Very dangerous
- Does NOT respawn (permanent clear)

```gdscript
# resources/world/examples/poi_bandit_camp.tres
poi_name = "Bandit Camp"
poi_type = POIData.Type.BANDIT_CAMP
enemy_count = Vector2i(3, 5)
loot_tier = POIData.LootTier.HIGH
respawns = false
```

#### **Crashed Convoy**
- Destroyed vehicles
- Loot scattered around
- No enemies (usually)
- One-time exploration

#### **Radio Tower**
- Reveals nearby POIs on map (fog of war system)
- No loot, no enemies
- Utility POI

**Implementation Priority:** LOW (Nice to have, not essential)

---

### 3. Contract Variety

**Goal:** Make contracts feel unique, not repetitive

**Contract Modifiers:**

#### **Fragile Cargo**
- Cargo takes damage when vehicle is damaged
- Cargo breaks if vehicle destroyed
- Payment reduced if delivered damaged
- Bonus payment if delivered pristine

```gdscript
fragile = true
fragile_damage_threshold = 50  # Vehicle HP below this = cargo starts taking damage
pristine_bonus = 1.5  # 50% bonus if no damage
```

#### **Timed Urgent Delivery**
- Half the normal time limit
- Double payment if delivered on time
- Penalty is tripled if failed

```gdscript
urgent = true
time_limit_multiplier = 0.5
payment_multiplier = 2.0
```

#### **Temperature-Sensitive Cargo**
- Must deliver within time or cargo spoils
- Visual indicator (ice melting, heat gauge)
- Total loss if timer expires

```gdscript
temperature_sensitive = true
spoil_time = 600.0  # 10 minutes real-time
spoiled_penalty = 1.0  # Lose full cargo value
```

#### **Convoy Escort**
- NPC vehicle travels with you
- Must protect them from raiders
- Payment bonus if they survive
- Penalty if they're destroyed

```gdscript
escort_mission = true
escort_vehicle = preload("res://scenes/actors/npc_convoy.tscn")
escort_survival_bonus = 1.3  # 30% bonus
```

**Implementation Priority:** MEDIUM (Adds replayability)

---

### 4. Weather System

**Goal:** Add atmosphere and tactical considerations

**Weather Types:**

#### **Sandstorm**
- Reduces visibility (fog effect)
- Reduces detection range (raiders can't see as far)
- Increases fuel consumption (+20%)
- Reduces max speed (-15%)

#### **Radiation Storm**
- Damages player over time if outside vehicle
- Safe inside vehicle
- Encourages staying in vehicle
- Rare but dangerous

#### **Clear/Sunny**
- Default weather
- No effects

**Weather Cycle:**
- Changes every 15-30 minutes real-time
- Warning before weather change (dark clouds, wind)
- Weather forecast at settlements (plan route accordingly)

**Implementation Priority:** LOW (Atmospheric, not essential)

---

### 5. Map & Navigation System

**Goal:** Help players navigate the procedural world

**Features:**

**Minimap:**
- Top-right corner of screen
- Shows immediate surroundings (500px radius)
- Player dot (blue), enemies (red), POIs (yellow)
- Fog of war (explored vs. unexplored)

**Full Map (Tab to open):**
- Zoom in/out
- Shows all discovered POIs
- Place waypoint markers
- Show current contract destination
- Distance/time estimates

**Waypoint System:**
- Click on map to set waypoint
- Waypoint arrow in HUD (points toward marker)
- Distance to waypoint shown

**Fog of War:**
- Unexplored areas are dark/hidden
- Explored areas revealed
- Radio towers reveal large areas

**Implementation Priority:** MEDIUM (Quality of life improvement)

---

### 6. Permadeath Mode

**Goal:** Ultimate challenge for hardcore players

**Features:**
- Single save file
- Death = game over (save deleted)
- Extra rewards for completing contracts (2x credits)
- Leaderboard for longest survival time
- "Legacy" system: Unlock bonuses for next run

**Implementation:** Toggle at new game creation

**Implementation Priority:** LOW (For experienced players only)

---

### 7. Radio / Music System

**Goal:** Enhance immersion during long drives

**Features:**
- In-vehicle radio (toggle with key)
- Multiple stations (music, talk show, ambient)
- Dynamic music (combat vs. calm)
- Volume control in settings

**Stations:**
1. **Wasteland Radio:** Post-apocalyptic music
2. **News Radio:** Lore/world-building announcements
3. **Ambient Station:** Relaxing background noise

**Implementation Priority:** LOW (Nice to have)

---

### 8. NPC Interactions

**Goal:** Make settlements feel alive

**Features:**

**Settlement NPCs:**
- Wandering NPCs in settlements
- Dialogue system (simple)
- Quest givers (side missions)
- Merchants (buy/sell items)

**Random Events:**
- NPC asks for ride (hitchhiker)
- NPC offers side quest (fetch item, kill raider)
- NPC warns about nearby danger

**Implementation Priority:** LOW (Adds flavor, not core)

---

### 9. Reputation Tiers & Titles

**Goal:** Give players identity/progression feel

**Titles:**
- 0-49 rep: "Rookie Courier"
- 50-99 rep: "Reliable Runner"
- 100-199 rep: "Experienced Hauler"
- 200-299 rep: "Veteran Transporter"
- 300-499 rep: "Elite Courier"
- 500+ rep: "Legendary Deliverer"

**Title Benefits:**
- Cosmetic (shown in UI)
- NPC dialogue changes based on title
- Special contracts unlock at high titles

**Implementation Priority:** LOW (Cosmetic + minor gameplay)

---

### 10. Save System Enhancements

**Goal:** Better save management

**Features:**
- Multiple save slots (3-5 slots)
- Save file details (playtime, rep, credits, last location)
- Cloud save support (if applicable)
- Auto-backup system

**Implementation Priority:** LOW (Quality of life)

---

## Implementation Priorities Summary

**HIGH PRIORITY:**
- None (Phase 4 is all optional)

**MEDIUM PRIORITY:**
- Vehicle variety & upgrades
- Contract variety (modifiers)
- Map & navigation system

**LOW PRIORITY:**
- Expanded POIs
- Weather system
- Permadeath mode
- Radio/music system
- NPC interactions
- Reputation titles
- Save system enhancements

---

## Suggested Implementation Order

1. **Vehicle upgrades** (easy wins, noticeable impact)
2. **Contract modifiers** (adds variety without new systems)
3. **Map system** (major QoL improvement)
4. **New vehicle types** (motorcycle, truck)
5. **Weather system** (atmospheric)
6. **Expanded POIs** (content variety)
7. **Radio system** (immersion)
8. **NPC interactions** (worldbuilding)
9. **Permadeath mode** (challenge mode)
10. **Cosmetic polish** (titles, UI improvements)

---

## Testing Checklist

- [ ] Vehicle upgrades apply bonuses correctly
- [ ] Multiple vehicles can be owned and switched
- [ ] New POI types spawn correctly
- [ ] Contract modifiers work as intended
- [ ] Fragile cargo breaks appropriately
- [ ] Map reveals explored areas correctly
- [ ] Waypoint navigation works
- [ ] Weather effects apply correctly
- [ ] Radio stations play music
- [ ] Permadeath deletes save on death
- [ ] NPCs have functional dialogue
- [ ] Reputation titles display correctly

---

## Known Future Features (Beyond Phase 4)

- Multiplayer co-op (extremely complex)
- Base building (settlement upgrades)
- Faction system (multiple competing factions)
- Crafting system (make items from materials)
- Companion system (recruit NPCs)
- Story mode (scripted narrative campaign)
- Boss enemies (unique encounters)
- Seasonal events (holidays, special contracts)

---

## Notes

- Phase 4 features should be **additive**, not disruptive
- Each feature should be **self-contained** (can be added independently)
- Focus on features that **enhance replayability**
- Avoid feature creep - stick to design doc
- Playtesting after Phase 3 will guide priorities
- Some features can be cut if not fun/polished
