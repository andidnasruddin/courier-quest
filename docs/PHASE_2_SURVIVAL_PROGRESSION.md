# Phase 2: Survival & Progression

**Goal:** Add depth to moment-to-moment gameplay through survival mechanics and skill-based progression
**Timeline:** Week 3
**Status:** Not Started
**Dependencies:** Phase 1 must be complete

---

## Overview

Phase 2 transforms the game from a simple delivery simulator into a survival courier experience. Players must now manage their physical needs while building skills through gameplay. The reputation system creates meaningful choices between high-risk/high-reward contracts.

By the end of this phase, players will:
1. Manage hunger, thirst, and fatigue
2. Improve skills through practice (Project Zomboid-style)
3. Access tiered contracts based on reputation
4. Face consequences for failing contracts
5. Make strategic decisions about risk vs. reward

---

## Systems to Implement

### 1. Survival Mechanics

**Components:**
- `survival_component.gd` - Manages hunger/thirst/fatigue
- `consumable_data.gd` - Extends ItemData for food/water

**Meters:**
- **Hunger:** 0-100 (decreases over time)
  - Depletion rate: -1 per 2 real-time minutes
  - < 30: Movement speed -15%
  - < 10: Movement speed -35%
  - 0: Take 1 HP damage every 10 seconds

- **Thirst:** 0-100 (decreases faster than hunger)
  - Depletion rate: -1 per 90 real-time seconds
  - < 30: Screen desaturation effect
  - < 10: Movement speed -25%
  - 0: Take 2 HP damage every 10 seconds

- **Fatigue:** 0-100 (decreases based on activity)
  - Passive drain: -1 per 5 real-time minutes
  - Sprinting: -5 per minute
  - Driving: -2 per minute
  - < 30: Cannot sprint
  - < 10: Movement speed -20%
  - 0: Character collapses, forced sleep

**Consumable Items:**

```gdscript
# resources/items/examples/canned_food.tres
extends ConsumableData
item_name = "Canned Food"
grid_size = Vector2i(1, 1)
weight = 0.5
stackable = true
max_stack = 10
hunger_restore = 40.0
thirst_restore = 0.0
fatigue_restore = 0.0
consumption_time = 3.0  # seconds
```

```gdscript
# resources/items/examples/water_bottle.tres
extends ConsumableData
item_name = "Water Bottle"
grid_size = Vector2i(1, 2)
weight = 1.0
stackable = true
max_stack = 5
hunger_restore = 0.0
thirst_restore = 50.0
fatigue_restore = 0.0
consumption_time = 2.0
```

```gdscript
# resources/items/examples/coffee.tres
extends ConsumableData
item_name = "Coffee"
grid_size = Vector2i(1, 1)
weight = 0.3
stackable = true
max_stack = 10
hunger_restore = 0.0
thirst_restore = 20.0
fatigue_restore = 35.0
consumption_time = 1.5
```

**Sleep System:**
- Can sleep at settlements (free, safe)
- Can sleep in vehicle (risky, can be robbed in Phase 3)
- Sleep duration: 6 real-time seconds = 6 in-game hours
- Fully restores fatigue
- Small hunger/thirst drain during sleep

**UI Elements:**
- Three vertical bars (hunger/thirst/fatigue) in HUD
- Color coding: Green > 50, Yellow 20-50, Red < 20
- Pulsing animation when critical (< 10)

**Implementation Priority:** HIGH (Core to survival gameplay)

---

### 2. Skill System (Project Zomboid-Inspired)

**Components:**
- `skill_system.gd` - Singleton (autoload)
- `skill_data.gd` - Resource definition for each skill

**Skills:**

#### **Driving** (0-10)
- **Increases through:** Distance driven, sharp turns survived, parking
- **Effects per level:**
  - Fuel efficiency: +2% per level (Level 10 = 20% less fuel consumption)
  - Top speed: +1 kph per level
  - Turn sharpness: +3% per level
  - Drift control: Better momentum management
- **XP gain:**
  - 1 XP per 100 pixels driven
  - 5 XP for successful sharp turn (> 45° at speed)
  - 10 XP for parking near target destination

#### **Mechanical** (0-10)
- **Increases through:** Refueling, repairing vehicles (Phase 3)
- **Effects per level:**
  - Refuel speed: -5% time per level
  - Repair effectiveness: +5% per level (Phase 3)
  - Vehicle inspection: See fuel efficiency at higher levels
- **XP gain:**
  - 10 XP per refuel action
  - 25 XP per vehicle repair (Phase 3)

#### **Fitness** (0-10)
- **Increases through:** Sprinting, carrying heavy items
- **Effects per level:**
  - Weight capacity: +5kg per level (Base 60kg → Max 110kg at level 10)
  - Sprint duration: +10% per level
  - Sprint speed: +2% per level
- **XP gain:**
  - 1 XP per 10 seconds of sprinting
  - 2 XP per minute while over-encumbered (> 80% capacity)

#### **Combat** (0-10)
- **Increases through:** Shooting, reloading, killing enemies (Phase 3)
- **Effects per level:**
  - Reload speed: -5% time per level
  - Weapon sway: -8% per level (better accuracy)
  - Recoil control: -5% per level
- **XP gain:**
  - 2 XP per shot fired
  - 5 XP per successful hit
  - 50 XP per enemy killed (Phase 3)

**Skill UI:**
- Skill panel (accessible from pause menu)
- Progress bars for each skill
- Tooltip showing current bonuses
- Recent skill-up notification (e.g., "Driving +1")

**Implementation Priority:** HIGH (Provides progression feel)

---

### 3. Contract Tier System

**Components:**
- `contract_tier_data.gd` - Resource definition for tiers
- Update `contract_data.gd` to include tier

**Tiers:**

#### **Tier 1: Novice**
- **Unlock:** 0+ reputation
- **Distance range:** 5-15 km
- **Payment:** 8 credits/km
- **Cargo:** Common items (food, water, basic supplies)
- **Time limit:** 20 real-time minutes
- **Failure penalty:** -5 reputation, -50% cargo value

**Example Tier 1 Contracts:**
```gdscript
# resources/contracts/tier1/basic_supplies.tres
contract_name = "Basic Supplies Delivery"
tier = 1
cargo_item = preload("res://resources/items/examples/canned_food.tres")
cargo_quantity = 10
payment_per_km = 8.0
distance_range = Vector2(5000, 15000)  # 5-15 km in pixels
time_limit_minutes = 20.0
```

#### **Tier 2: Experienced**
- **Unlock:** 100+ reputation
- **Distance range:** 15-30 km
- **Payment:** 15 credits/km
- **Cargo:** Valuable items (medicine, electronics)
- **Time limit:** 30 real-time minutes
- **Failure penalty:** -15 reputation, -75% cargo value

**Example Tier 2 Contracts:**
```gdscript
# resources/contracts/tier2/medical_supplies.tres
contract_name = "Medical Supplies - Urgent"
tier = 2
cargo_item = preload("res://resources/items/examples/medkit.tres")
cargo_quantity = 8
payment_per_km = 15.0
distance_range = Vector2(15000, 30000)
time_limit_minutes = 30.0
fragile = true  # Taking damage reduces payment
```

#### **Tier 3: Expert**
- **Unlock:** 300+ reputation
- **Distance range:** 30-60 km
- **Payment:** 25 credits/km
- **Cargo:** High-value items (weapons, rare tech)
- **Time limit:** 45 real-time minutes
- **Failure penalty:** -30 reputation, -100% cargo value (debt if broke)

**Example Tier 3 Contracts:**
```gdscript
# resources/contracts/tier3/weapon_shipment.tres
contract_name = "Weapon Shipment - Classified"
tier = 3
cargo_item = preload("res://resources/items/examples/assault_rifle.tres")
cargo_quantity = 5
payment_per_km = 25.0
distance_range = Vector2(30000, 60000)
time_limit_minutes = 45.0
fragile = true
high_risk = true  # Attracts more enemies (Phase 3)
```

**Contract Board Updates:**
- Show available tiers based on reputation
- Display locked tiers with reputation requirement
- Sort contracts by tier
- Show estimated time to destination

**Implementation Priority:** HIGH (Core to progression)

---

### 4. Time Limits & Failure Consequences

**Components:**
- Update `contract_manager.gd` to track time
- `debt_system.gd` - Manages player debt

**Time Limit System:**
- Timer starts when contract accepted
- UI shows remaining time (e.g., "15:30 remaining")
- Warning notification at 5 minutes remaining
- Warning notification at 1 minute remaining

**Failure Conditions:**
1. **Time expired:** Contract auto-fails
2. **Cargo destroyed:** Lost or damaged beyond threshold
3. **Player death:** All active contracts fail (Phase 3)

**Failure Consequences:**

**Immediate:**
- Contract removed from active contracts
- Cargo removed from inventory (if still carried)
- Reputation penalty applied
- Payment deducted from player balance

**Debt System:**
- If payment > current credits:
  - Player goes into debt (negative balance)
  - Cannot accept new contracts until debt paid
  - Can still complete active contracts
  - Settlements offer "debt work" (low-pay deliveries to clear debt)

**Example:**
```
Contract failed: Medical Supplies - Urgent
Penalty: 200 credits (cargo value 50% of 400 credits)
Current balance: 50 credits
New balance: -150 credits (IN DEBT)
```

**Debt Repayment:**
- **Option 1:** Complete active contracts (if any)
- **Option 2:** Accept "debt work" contracts (always available, low pay)
- **Option 3:** Find and sell items in the world (optional loot system)

**UI:**
- Contract timer in HUD
- Debt indicator (red balance display)
- Warning messages when close to failure

**Implementation Priority:** MEDIUM (Adds tension)

---

### 5. Reputation System

**Components:**
- `reputation_manager.gd` - Singleton (autoload)

**Reputation Mechanics:**

**Gain Reputation:**
- Complete contract on time: +10 rep
- Complete contract early (> 20% time remaining): +15 rep
- Complete fragile cargo without damage: +5 bonus rep
- Complete Tier 3 contract: +20 rep

**Lose Reputation:**
- Fail contract: -5 to -30 rep (based on tier)
- Deliver damaged fragile cargo: -10 rep
- Go into debt: -5 rep

**Reputation Effects:**

**Contract Access:**
- 0-99 rep: Tier 1 only
- 100-299 rep: Tier 1-2
- 300+ rep: All tiers

**Ambush Frequency (Phase 3):**
- **Inverse relationship:** Higher rep = MORE danger
- Rationale: Valuable courier attracts raiders
- 0-99 rep: 10% ambush chance
- 100-299 rep: 25% ambush chance
- 300+ rep: 40% ambush chance

**Settlement Prices:**
- High rep (200+): 10% discount on fuel/supplies
- Low rep (< 50): 10% markup on fuel/supplies

**UI:**
- Reputation bar in pause menu
- Current rep number displayed
- Next tier unlock threshold shown
- Reputation change notifications (e.g., "+10 Reputation")

**Implementation Priority:** HIGH (Creates risk/reward dynamics)

---

## Technical Implementation Order

1. **Survival component** (hunger, thirst, fatigue meters)
2. **Consumable items** (food, water, coffee resources)
3. **Sleep system** (rest at settlements, vehicle rest)
4. **Skill system foundation** (XP tracking, level-up logic)
5. **Driving skill** (XP from driving, bonuses apply)
6. **Fitness skill** (XP from sprinting/carrying weight)
7. **Mechanical skill** (XP from refueling)
8. **Contract tiers** (tier 1, 2, 3 definitions)
9. **Time limit system** (timer, warnings, failure)
10. **Debt system** (negative balance, repayment)
11. **Reputation manager** (gain/loss, tier unlocks)
12. **UI updates** (survival bars, skill panel, contract timers)

---

## Definition of Done (Phase 2)

✅ Survival meters (hunger/thirst/fatigue) drain over time
✅ Eating food restores hunger
✅ Drinking water restores thirst
✅ Sleeping at settlements/vehicles restores fatigue
✅ Survival meters affect player performance when low
✅ Player can die from starvation/dehydration
✅ Driving skill increases while driving
✅ Fitness skill increases while sprinting/over-encumbered
✅ Mechanical skill increases when refueling
✅ Skills provide visible bonuses (fuel efficiency, weight capacity, etc.)
✅ Contract board shows Tier 1, 2, 3 contracts
✅ Higher tiers locked behind reputation thresholds
✅ Contracts have time limits displayed in UI
✅ Contracts fail when time expires
✅ Failed contracts deduct payment from player balance
✅ Player can go into debt and must repay
✅ Reputation increases when completing contracts
✅ Reputation decreases when failing contracts
✅ Higher reputation unlocks higher tier contracts
✅ Skill level-up notifications appear
✅ Reputation change notifications appear

---

## Balance Tuning Values

**Survival Depletion Rates:**
- Hunger: 1 point per 2 minutes (depletes in 3.3 hours)
- Thirst: 1 point per 90 seconds (depletes in 2.5 hours)
- Fatigue: 1 point per 5 minutes passive (depletes in 8.3 hours)

**Skill XP Requirements:**
```
Level 1: 100 XP
Level 2: 250 XP
Level 3: 450 XP
Level 4: 700 XP
Level 5: 1000 XP
Level 6: 1400 XP
Level 7: 1900 XP
Level 8: 2500 XP
Level 9: 3200 XP
Level 10: 4000 XP
```

**Reputation Tiers:**
- Novice: 0-99
- Experienced: 100-299
- Expert: 300+

**Time Limits:**
- Tier 1: 20 minutes
- Tier 2: 30 minutes
- Tier 3: 45 minutes

---

## Testing Checklist

- [ ] Survival meters drain at correct rates
- [ ] Consumables restore appropriate amounts
- [ ] Sleep fully restores fatigue
- [ ] Low survival meters affect gameplay as intended
- [ ] Skills level up from correct actions
- [ ] Skill bonuses apply correctly (fuel efficiency, speed, etc.)
- [ ] Contract tiers unlock at correct reputation levels
- [ ] Time limit warnings appear at 5 min and 1 min
- [ ] Failed contracts apply correct penalties
- [ ] Debt system prevents contract acceptance
- [ ] Reputation changes display correctly
- [ ] High reputation unlocks Tier 3 contracts
- [ ] Balance feels fair (not too punishing, not too easy)

---

## Known Limitations (To Address in Phase 3+)

- No enemies affected by reputation
- No health damage system (only starvation damage)
- No vehicle damage affecting survival
- No weather affecting survival
- No temperature mechanics
- Combat skill has no use yet (Phase 3)

---

## UI/UX Mockups Needed

- Survival bars layout in HUD
- Skill panel design
- Contract timer display
- Debt warning screen
- Reputation progress indicator
- Skill level-up notification design

---

## Notes

- Balance survival to encourage planning (can't ignore hunger for whole session)
- Skills should feel rewarding but not essential (new players viable)
- Reputation system creates strategic choices (stay safe at low rep, or risk it for better contracts)
- Time limits should be achievable but require efficiency
- Debt system prevents "fail and retry" mentality
