# Phase 3: Danger & Combat

**Goal:** Add risk, action elements, and tactical decision-making to the courier experience
**Timeline:** Week 4
**Status:** Not Started
**Dependencies:** Phase 1 & 2 must be complete

---

## Overview

Phase 3 introduces danger to the wasteland. Players must now navigate enemy-infested zones, defend themselves and their cargo, and make tactical choices about routes and engagement. The combat is **defensive-focused** - avoiding or surviving encounters is preferred over seeking them out.

By the end of this phase, players will:
1. Encounter enemy raiders in dangerous zones
2. Defend themselves with firearms (on foot only)
3. Flee or ram enemies while driving
4. Face ambushes based on reputation
5. Repair damaged vehicles
6. Manage health and healing

---

## Combat Philosophy

**Death Stranding-Inspired:**
- Combat is **avoidance-focused**, not combat-focused
- Fleeing is often the best option
- Cargo protection is the priority
- Fighting drains resources (ammo, health)

**Rules:**
- ✅ Can shoot while on foot
- ❌ Cannot shoot while driving
- ✅ Can ram enemies with vehicle
- ❌ No turret or vehicle weapons (not a combat game)
- ✅ Enemies can damage cargo
- ✅ Death = contract failure + respawn at last settlement

---

## Systems to Implement

### 1. Enemy AI System

**Components:**
- `enemy_ai.gd` - Base AI controller
- `raider_ai.gd` - Specific raider behavior
- `enemy_data.gd` - Resource definition

**Enemy Type: Raider**

**Behavior:**
1. **Idle/Patrol:** Wander in small area until player detected
2. **Chase:** Run toward player/vehicle when in detection range
3. **Attack (On Foot):** Shoot at player if within range
4. **Attack (Vehicle):** Try to damage vehicle, force player out
5. **Loot:** Steal cargo if player dies (optional)

**Stats (from enemy_data.tres):**
```gdscript
# resources/enemies/examples/raider.tres
enemy_name = "Wasteland Raider"
max_health = 50.0
move_speed = 120.0  # Slightly faster than player walk
detection_range = 400.0  # pixels
attack_range = 250.0  # shoot from this distance
damage = 15.0  # per hit
attack_cooldown = 2.0  # seconds between shots
loot_table = [...]  # drops ammo, food, etc. (optional)
```

**AI States:**
```gdscript
enum AIState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	FLEE  # If heavily damaged
}
```

**Detection:**
- **Line of sight:** Raycast to check if player visible
- **Sound:** Vehicle noise attracts raiders (200px additional range when driving)
- **High reputation:** Detection range +20% (raiders actively hunt valuable couriers)

**Spawning:**
- Spawn in dangerous zones (Radioactive biome, between settlements)
- Never spawn within 1km of settlements (safe zones)
- Spawn distance from player: 500-800 pixels (not on screen, but close)
- Max active enemies: 6-8 at once (performance limit)

**Implementation Priority:** HIGH (Core to Phase 3)

---

### 2. Player Combat System

**Components:**
- `weapon_component.gd` - Handles shooting, reloading
- `weapon_data.gd` - Resource definition for weapons
- `projectile.gd` - Bullet/projectile behavior

**Weapon Types:**

#### **Pistol**
```gdscript
# resources/weapons/examples/pistol.tres
weapon_name = "9mm Pistol"
damage = 20.0
fire_rate = 0.5  # seconds between shots
magazine_size = 12
reload_time = 2.0  # seconds
ammo_type = "9mm"
projectile_speed = 800.0
accuracy = 0.95  # 95% accuracy (spread)
grid_size = Vector2i(2, 2)
weight = 1.2
```

#### **Shotgun**
```gdscript
# resources/weapons/examples/shotgun.tres
weapon_name = "Pump Shotgun"
damage = 60.0  # Total (10 pellets × 6 damage each)
fire_rate = 1.0
magazine_size = 6
reload_time = 3.5
ammo_type = "12_gauge"
projectile_speed = 600.0
accuracy = 0.7  # Wide spread
pellet_count = 10
grid_size = Vector2i(3, 1)
weight = 3.5
```

#### **Assault Rifle**
```gdscript
# resources/weapons/examples/assault_rifle.tres
weapon_name = "AK-47"
damage = 25.0
fire_rate = 0.15  # Fast fire rate
magazine_size = 30
reload_time = 2.5
ammo_type = "762"
projectile_speed = 1000.0
accuracy = 0.88  # Some recoil
auto_fire = true  # Hold to fire
grid_size = Vector2i(4, 2)
weight = 4.0
```

**Combat Mechanics:**

**Aiming:**
- Mouse cursor aim (top-down)
- Player sprite rotates toward cursor
- Weapon attached to player sprite

**Shooting:**
- Left mouse button (or Fire input action)
- Projectile spawns from player position
- Travels in straight line (with spread based on accuracy)
- Deals damage on hit (raycast or Area2D collision)

**Reloading:**
- R key (or Reload input action)
- Cannot shoot during reload
- Reload animation/timer
- Consumes ammo from inventory

**Ammo Management:**
- Ammo is inventory item (stackable)
- Reloading consumes ammo from inventory
- Different ammo types for different weapons
- Running out of ammo = weapon useless (melee as last resort)

**Restrictions:**
- ❌ Cannot shoot while in vehicle
- ❌ Cannot reload while sprinting
- ✅ Can shoot while walking (reduced accuracy)

**Implementation Priority:** HIGH (Player needs to defend themselves)

---

### 3. Vehicle Ramming & Damage

**Components:**
- Update `vehicle_controller.gd` to handle collisions
- `vehicle_health_component.gd` - Vehicle HP system

**Ramming Mechanics:**

**Collision Damage (to enemy):**
- Damage = Vehicle speed × 0.5
- Example: 60 kph = 30 damage (instant kill most enemies)
- Must be moving > 20 kph to deal damage

**Collision Damage (to vehicle):**
- Vehicle takes 10% of damage dealt to enemy
- Example: Kill enemy (30 dmg) = vehicle takes 3 damage
- Colliding with walls/obstacles = 5-15 damage (based on speed)

**Vehicle Health:**
```gdscript
# Vehicle health stats
max_health = 100.0
current_health = 100.0

# Damage effects
< 75 HP: Smoke particles
< 50 HP: Max speed reduced by 20%
< 25 HP: Max speed reduced by 50%, fuel efficiency -30%
0 HP: Vehicle destroyed (immobilized)
```

**Implementation Priority:** MEDIUM (Alternative to shooting)

---

### 4. Ambush System

**Components:**
- `ambush_manager.gd` - Handles spawn events
- Update `reputation_manager.gd` to affect ambush chance

**Ambush Triggers:**

**Location-Based:**
- Only in "danger zones" (far from settlements)
- Not in settlements or immediate surroundings (< 1km radius)
- Higher chance in Radioactive biome

**Reputation-Based (Inverse Relationship):**
- **0-99 rep:** 10% ambush chance
- **100-299 rep:** 25% ambush chance
- **300+ rep:** 40% ambush chance

**Rationale:** High-value couriers are bigger targets

**Contract-Based:**
- Tier 3 contracts with `high_risk = true`: +20% ambush chance
- Carrying valuable cargo: +15% ambush chance

**Ambush Event:**
1. Check trigger conditions (location, reputation, contract)
2. Roll for ambush (RNG based on chance %)
3. If triggered, spawn 2-4 raiders ahead of player (500-800px away)
4. Raiders start in CHASE state
5. Player must flee, fight, or ram

**Warning System:**
- Visual indicator: Red exclamation mark in direction of enemies
- Audio cue: Distant shouts, engine sounds
- 3-5 second warning before raiders in attack range

**Implementation Priority:** MEDIUM (Adds tension)

---

### 5. Health & Healing System

**Components:**
- `health_component.gd` - Manages player HP
- Update `consumable_data.gd` to include healing

**Player Health:**
- Max HP: 100.0
- Regeneration: None (must heal with items)
- Death: Respawn at last settlement, lose active contracts

**Damage Sources:**
- Enemy bullets: 15-25 damage per hit
- Starvation: 1 damage per 10 seconds (when hunger = 0)
- Dehydration: 2 damage per 10 seconds (when thirst = 0)
- Vehicle explosion: 50 damage (if vehicle destroyed while inside)

**Healing Items:**

```gdscript
# resources/items/examples/medkit.tres
extends ConsumableData
item_name = "Medkit"
grid_size = Vector2i(2, 2)
weight = 1.5
stackable = false
health_restore = 50.0
consumption_time = 4.0  # Slow to use
```

```gdscript
# resources/items/examples/bandage.tres
extends ConsumableData
item_name = "Bandage"
grid_size = Vector2i(1, 1)
weight = 0.2
stackable = true
max_stack = 10
health_restore = 15.0
consumption_time = 2.0
```

**Death Consequences:**
- Respawn at last visited settlement
- Lose all active contracts (failure penalties apply)
- Keep inventory and money
- 10 minute real-time respawn cooldown (optional hardcore mode: permadeath)

**UI:**
- Health bar in HUD (red, top-left)
- Damage flash effect (screen edges turn red)
- Low health warning (pulsing heart icon < 25 HP)

**Implementation Priority:** HIGH (Need death state)

---

### 6. Vehicle Repair System

**Components:**
- `repair_station_component.gd` - Gas station repair feature
- Update `vehicle_health_component.gd` for repair logic

**Repair Locations:**
- Gas stations (primary)
- Settlements (more expensive)

**Repair Costs:**
```
Repair rate: 5 credits per HP
Full repair (0 → 100 HP) = 500 credits
Partial repair: Choose amount to repair
```

**Mechanical Skill Bonus:**
- Level 1-3: No discount
- Level 4-6: 10% discount
- Level 7-9: 20% discount
- Level 10: 30% discount

**Repair UI:**
- Slider to choose repair amount
- Cost displayed (e.g., "Repair 50 HP: 250 credits")
- Confirm/Cancel buttons
- Visual feedback (sparks, repair animation)

**Implementation Priority:** MEDIUM (Needed if vehicle takes damage)

---

## Technical Implementation Order

1. **Enemy AI foundation** (states, detection, pathfinding)
2. **Raider AI** (chase and attack behaviors)
3. **Enemy spawning** (danger zones, distance from player)
4. **Player health system** (HP, death, respawn)
5. **Weapon component** (shooting, aiming, reload)
6. **Projectile system** (bullets, collision, damage)
7. **Weapon resources** (pistol, shotgun, rifle .tres files)
8. **Healing items** (medkit, bandage consumables)
9. **Vehicle health** (HP, damage effects)
10. **Vehicle ramming** (collision damage to enemies)
11. **Ambush system** (reputation-based spawning)
12. **Repair system** (gas station repairs)
13. **Combat UI** (health bar, ammo counter, hit markers)
14. **Audio/VFX** (gunshots, blood, smoke, etc.)

---

## Definition of Done (Phase 3)

✅ Raiders spawn in dangerous zones (far from settlements)
✅ Raiders detect player and chase them
✅ Raiders shoot at player when in range
✅ Player can aim and shoot with weapons
✅ Weapons deal damage to enemies
✅ Enemies die when health reaches 0
✅ Player takes damage from enemy bullets
✅ Player health bar displays correctly
✅ Player can heal with medkits/bandages
✅ Player dies when health reaches 0
✅ Player respawns at last settlement after death
✅ Active contracts fail on player death
✅ Vehicle can ram enemies to deal damage
✅ Ramming damages both enemy and vehicle
✅ Vehicle health depletes from collisions
✅ Vehicle performance degrades at low health
✅ Player can repair vehicle at gas stations
✅ Repair costs scale with damage amount
✅ Ambushes trigger based on reputation
✅ Higher reputation = more frequent ambushes
✅ Ambush warning appears before enemy encounter
✅ Ammo is consumed when reloading
✅ Cannot shoot when out of ammo
✅ Cannot shoot while in vehicle

---

## Balance Tuning Values

**Enemy Stats:**
- Raider HP: 50
- Raider speed: 120 px/sec (player walk = 100)
- Raider damage: 15 per hit
- Raider attack cooldown: 2 seconds

**Player Combat:**
- Base accuracy: 80-95% (weapon-dependent)
- Reload time: 2-3.5 seconds (weapon-dependent)
- Ammo types: 9mm, 12_gauge, 762

**Vehicle:**
- Max HP: 100
- Ram damage: Speed × 0.5
- Ram self-damage: 10% of dealt damage
- Repair cost: 5 credits/HP

**Ambush Chances:**
- Low rep (0-99): 10%
- Medium rep (100-299): 25%
- High rep (300+): 40%

---

## Testing Checklist

- [ ] Raiders spawn appropriately in dangerous zones
- [ ] Raiders don't spawn near settlements
- [ ] Raider AI chases and attacks player
- [ ] Player can kill raiders with weapons
- [ ] Weapons feel responsive and accurate
- [ ] Ammo consumption works correctly
- [ ] Player takes damage and dies correctly
- [ ] Respawn works and fails active contracts
- [ ] Healing items restore HP
- [ ] Vehicle ramming deals damage to enemies
- [ ] Vehicle takes damage from ramming
- [ ] Low vehicle HP affects performance
- [ ] Repair system restores vehicle HP
- [ ] Ambushes trigger at correct frequencies
- [ ] Combat doesn't overshadow delivery focus
- [ ] Fleeing feels like a valid strategy

---

## Known Limitations (To Address in Phase 4+)

- No melee weapons
- No enemy variety (only raiders)
- No vehicle-mounted weapons (intentional)
- No cover system
- No stealth mechanics
- No companion/convoy system
- No boss enemies or special encounters

---

## Difficulty Balance Notes

**Combat should be:**
- **Dangerous:** Fighting is risky, not trivial
- **Avoidable:** Skilled players can dodge/flee
- **Resource-draining:** Ammo is limited, encourage conservation
- **Meaningful:** Death has real consequences (contract failure)

**Not:**
- **Combat-focused:** This isn't a shooter
- **Unavoidable:** Always provide escape routes
- **Grindy:** Don't require hours of combat
- **Punishing:** Failure shouldn't brick the save

**Player Skill Progression:**
- New players: Struggle with combat, prefer fleeing
- Experienced players: Efficient combat, selective engagement
- Expert players: Tactical decisions (when to fight vs. flee)

---

## Audio/Visual Requirements

**Audio:**
- Gunshot sounds (pistol, shotgun, rifle)
- Bullet impact sounds (hit enemy, hit wall)
- Enemy death sounds
- Raider shouts/aggro sounds
- Vehicle collision sounds
- Repair sounds (wrench, welding)

**Visual Effects:**
- Muzzle flash (weapon fire)
- Bullet tracers (optional)
- Blood splatter (enemy hit)
- Smoke particles (damaged vehicle)
- Sparks (vehicle repair)
- Screen shake (taking damage)
- Red screen flash (low health)

**UI:**
- Ammo counter (bottom-right)
- Weapon icon (current equipped)
- Hit markers (when hitting enemy)
- Damage indicators (direction of incoming damage)

---

## Notes

- Combat should feel like **survival**, not power fantasy
- Encourage players to **avoid combat when possible**
- Make fleeing in vehicle a **viable and smart strategy**
- High-rep players should feel like **hunted couriers**, not action heroes
- Balance enemy damage to make combat **tense but not frustrating**
- Vehicle ramming should feel **satisfying but costly** (vehicle damage)
