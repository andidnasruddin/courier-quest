# Phase 1: Core Delivery Loop

**Goal:** Create playable delivery experience - the minimum viable gameplay loop
**Timeline:** Week 1-2
**Status:** Not Started

---

## Overview

Phase 1 establishes the foundational systems that make the game playable. By the end of this phase, a player can:
1. Move around as a character
2. Enter/exit a vehicle
3. Drive the vehicle with realistic physics
4. Navigate a procedurally generated world
5. Accept a delivery contract
6. Complete the delivery and receive payment
7. Save their progress

---

## Systems to Implement

### 1. Player Character System

**Components:**
- `player.gd` - Main player controller
- `locomotion_component.gd` - Movement logic (WASD)
- `interaction_component.gd` - Interact with objects (F key)

**Features:**
- Top-down movement (8-directional or free movement)
- Walk speed: 100 pixels/sec
- Sprint speed: 175 pixels/sec (when shift held)
- Simple sprite with rotation toward mouse cursor
- Collision detection (CharacterBody2D)

**Resources Needed:**
- Player sprite (placeholder circle OK)
- Walk/idle animations (optional for MVP)

**Implementation Priority:** HIGH (Required for everything else)

---

### 2. Vehicle System

**Components:**
- `vehicle_controller.gd` - Physics and input handling
- `vehicle_data.gd` - Resource definition script
- `fuel_system_component.gd` - Fuel consumption logic

**Features:**
- **Realistic driving physics:**
  - Acceleration (gradual speed increase)
  - Braking (friction-based slowdown)
  - Turning radius (speed affects turn sharpness)
  - Momentum/drift on sharp turns
  - Max speed: 60-80 kph

- **Enter/Exit mechanics:**
  - Press F near vehicle to enter
  - Press F while in vehicle to exit
  - Player hidden when in vehicle

- **Fuel system:**
  - Fuel capacity: 50 liters (configurable via .tres)
  - Consumption rate: ~0.5 L/km
  - Fuel gauge UI element
  - Vehicle stops when fuel = 0

- **Separate vehicle storage:**
  - Access when near vehicle or inside
  - Larger capacity than player inventory (12x8 grid vs 8x6)

**Resources:**
- `delivery_van.tres` - Default starter vehicle
  - max_speed: 80.0 kph
  - acceleration: 120.0
  - turn_speed: 2.5
  - fuel_capacity: 50.0
  - fuel_consumption: 0.5
  - storage_grid_size: Vector2i(12, 8)

**Implementation Priority:** HIGH (Core to gameplay)

---

### 3. Camera System

**Salvageable Code:**
- Use `OLD_CODE/driving_camera/LookAheadCamera.gd`
- 8-quadrant racing camera with lookahead
- Speed-based zoom
- Smooth velocity tracking
- Reverse handling

**Integration:**
- Attach to Player when on foot
- Transfer to Vehicle when driving
- Configure lookahead settings for top-down view

**Implementation Priority:** MEDIUM (Use existing code, just integrate)

---

### 4. Grid-Based Inventory System

**Components:**
- `inventory_component.gd` - Core inventory logic
- `inventory_data.gd` - Resource definition
- `item_data.gd` - Resource definition for items

**Features:**
- **Grid system:**
  - Player: 8 columns × 6 rows = 48 slots
  - Vehicle: 12 columns × 8 rows = 96 slots
  - Each item occupies width × height cells

- **Item mechanics:**
  - Rotation (R key) - flip item 90°
  - Drag and drop
  - Auto-stack for stackable items (ammo, consumables)
  - Weight system affects player movement speed

- **Weight effects:**
  - 0-20kg: 100% speed
  - 20-40kg: 75% speed
  - 40-60kg: 50% speed
  - 60kg+: 25% speed (over-encumbered)

**Example Item Resources:**
```gdscript
# resources/items/examples/medkit.tres
item_name = "Medkit"
grid_size = Vector2i(2, 2)  # 2×2 cells
weight = 1.5
stackable = false
icon = preload("res://assets/sprites/items/medkit.png")
```

**UI:**
- Inventory panel (toggle with Tab)
- Item tooltips (hover shows name, weight, description)
- Visual grid layout
- Weight counter (e.g., "35.5 / 60.0 kg")

**Implementation Priority:** HIGH (Required for delivery system)

---

### 5. Procedural World Generation

**Components:**
- `world_generator.gd` - Main generation system
- `chunk_manager.gd` - Chunk loading/unloading
- `biome_data.gd` - Resource definition
- `poi_data.gd` - Resource definition (Points of Interest)

**Features:**
- **Chunk system:**
  - Chunk size: 1024×1024 pixels
  - Load distance: 3 chunks in each direction (7×7 grid around player)
  - Unload chunks beyond 4 chunk distance
  - Chunk pooling for performance

- **Biomes (2 types for MVP):**
  1. **Wasteland** (60% of world)
     - Desert/barren terrain
     - Moderate enemy spawn rate
     - Tan/brown color palette

  2. **Radioactive Zone** (40% of world)
     - Hazardous area
     - Higher enemy spawn rate (Phase 3)
     - Green/toxic color palette

- **Noise-based generation:**
  - Use FastNoiseLite for terrain variation
  - Seed-based (same seed = same world)
  - Smooth biome transitions

- **POI placement:**
  - **Settlements:** 10km apart (~166 chunks = 170,000 pixels)
  - **Gas Stations:** Every 3-5km (~50-83 chunks)
  - Grid-based placement to ensure minimum distance
  - Road connections between POIs (optional for MVP)

**Biome Resources:**
```gdscript
# resources/world/examples/biome_wasteland.tres
biome_name = "Wasteland"
ground_color = Color(0.7, 0.65, 0.5)  # Tan
enemy_spawn_chance = 0.3
movement_speed_modifier = 1.0
```

**POI Resources:**
```gdscript
# resources/world/examples/poi_settlement.tres
poi_name = "Settlement Alpha"
poi_type = POIData.Type.SETTLEMENT
scene_path = "res://scenes/world/settlement.tscn"
min_distance_between = 170000.0  # 10km in pixels
```

**Implementation Priority:** HIGH (Needed for world to exist)

---

### 6. Contract System (Basic)

**Components:**
- `contract_manager.gd` - Singleton (autoload)
- `contract_data.gd` - Resource definition
- `contract_board_component.gd` - UI for accepting contracts

**Features:**
- **Contract structure:**
  - Pickup location (always current settlement)
  - Delivery destination (another settlement)
  - Cargo item (ItemData reference)
  - Payment (based on distance)
  - Deadline (Phase 2)

- **Workflow:**
  1. Player enters settlement
  2. Interact with contract board
  3. View available contracts (3-5 random)
  4. Accept contract → cargo added to inventory
  5. Travel to destination settlement
  6. Interact with delivery point
  7. Cargo removed, payment added

- **Payment calculation:**
  - Base rate: 10 credits/km
  - Example: 10km delivery = 100 credits

**Example Contract Resource:**
```gdscript
# resources/contracts/examples/medicine_delivery.tres
contract_name = "Medicine Delivery"
cargo_item = preload("res://resources/items/examples/medkit.tres")
cargo_quantity = 5
base_payment_per_km = 10.0
destination_settlement = "Settlement Beta"  # Procedurally assigned
```

**UI:**
- Contract board panel
- List of available contracts
- Accept/Decline buttons
- Contract details (destination, payment, cargo)

**Implementation Priority:** HIGH (Core gameplay loop)

---

### 7. Auto-Save System

**Components:**
- `save_manager.gd` - Singleton (autoload)

**Features:**
- **Save trigger:**
  - Detect when player enters 3×3 chunk zone around settlement
  - Auto-save when settlement is nearby
  - No manual save (prevents save-scumming)

- **Data to save:**
  - Player position (global coordinates)
  - Player inventory contents
  - Vehicle position
  - Vehicle fuel level
  - Vehicle inventory contents
  - Current money/credits
  - Active contract (if any)
  - World seed (for world recreation)

- **Save format:**
  - JSON file: `user://save_game.json`
  - Dictionary structure for easy serialization

- **Load system:**
  - On game start, check if save exists
  - If yes: Load player state and spawn at saved position
  - If no: Start new game at default settlement

**Implementation Priority:** MEDIUM (Nice to have, prevents progress loss)

---

## Technical Implementation Order

1. **Player movement** (locomotion_component.gd)
2. **Basic inventory system** (inventory_component.gd, item_data.gd)
3. **World generation** (chunk_manager.gd, basic biome rendering)
4. **Vehicle controller** (vehicle_controller.gd, basic physics)
5. **Camera integration** (integrate LookAheadCamera.gd)
6. **Settlement POI** (basic scene with contract board)
7. **Contract system** (contract_manager.gd, contract_data.gd)
8. **Fuel system** (fuel_system_component.gd)
9. **Save/Load** (save_manager.gd)
10. **UI polish** (inventory UI, contract board UI, HUD)

---

## Definition of Done (Phase 1)

✅ Player can walk around with WASD
✅ Player can enter/exit vehicle with F
✅ Vehicle has realistic driving feel (acceleration, turning)
✅ Vehicle consumes fuel while driving
✅ World generates with 2 biomes (Wasteland, Radioactive)
✅ Settlements spawn 10km apart
✅ Gas stations spawn between settlements
✅ Player can open inventory (Tab key)
✅ Player can pick up/move items in grid
✅ Items have weight that affects player speed
✅ Player can interact with contract board at settlement
✅ Player can accept a delivery contract
✅ Cargo is added to inventory when contract accepted
✅ Player can deliver cargo to destination settlement
✅ Player receives payment upon delivery
✅ Game auto-saves when near settlements
✅ Game loads saved progress on startup

---

## Known Limitations (To Address in Phase 2+)

- No survival mechanics (hunger, thirst, sleep)
- No enemies or combat
- No contract variety (all deliveries are identical)
- No failure states (can't fail a contract)
- No progression/upgrades
- No time limits on contracts
- No reputation system
- Single vehicle type only

---

## Testing Checklist

- [ ] Player movement feels responsive
- [ ] Vehicle handling feels realistic but fun
- [ ] Can complete full delivery loop (accept → travel → deliver)
- [ ] Fuel depletes appropriately during long drives
- [ ] Inventory weight slows player when over-encumbered
- [ ] Save/load preserves all player state
- [ ] World generates consistently from same seed
- [ ] Settlements are actually 10km apart
- [ ] Gas stations appear between settlements
- [ ] No crashes during chunk loading/unloading
- [ ] Camera follows smoothly during driving

---

## Asset Requirements

**Sprites:**
- Player character (32×32 or 64×64)
- Delivery van (64×64 or larger)
- Settlement building placeholder
- Gas station placeholder
- Ground tiles (2 types for biomes)
- Item icons (medkit, ammo, etc.)

**UI:**
- Inventory grid background
- Item slot borders
- Contract board panel
- Fuel gauge
- Speed gauge (optional)

**Audio (Optional for MVP):**
- Engine sound loop
- Footstep sounds
- UI click sounds

---

## Notes

- Keep placeholder art simple (colored rectangles OK)
- Focus on functionality over visuals in Phase 1
- Use `@export` extensively for easy tweaking
- Test frequently - each system should work independently first
- Document any deviations from this plan in `docs/CHANGELOG.md`
