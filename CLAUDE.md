# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Wasteland Courier** - Death Stranding-inspired top-down courier simulator built in Godot 4.x (GDScript).

**Core Concept:** Deliver cargo across a dangerous procedurally generated wasteland while managing survival needs, vehicle fuel, and inventory weight. Combat is defensive-focused; fleeing is often the best option.

**Current Status:** Phase 1 nearly complete (~90%). Core delivery loop functional: player movement, vehicle driving, fuel system, grid inventory with hotbar, procedural world generation, POI placement, and contract system all working.

## Running & Testing

### Launch Game
1. Open project in Godot 4.x
2. Press **F5** (runs main scene: `res://scenes/tests/test_vehicle.tscn`)

### Test Scenes
- `res://scenes/tests/test_player.tscn` - Player movement only
- `res://scenes/tests/test_vehicle.tscn` - Player + vehicle (enter/exit, driving)
- `res://scenes/tests/test_worldgen.tscn` - World generation, chunk streaming, POI placement, contract system
- `res://scenes/tests/test_inventory.tscn` - Inventory grid with drag-and-drop, rotation, hotbar
- `res://scenes/tests/test_dread_clock.tscn` - Night cycle system testing

### Test Controls
**On Foot:** WASD (move), Shift (sprint), E (interact), Tab (inventory), 1-5 (hotbar)
**In Vehicle:** W/S (accelerate/brake), A/D (steer), E (exit)
**Debug:** P (toggle chunk/POI debug overlay in test_worldgen)

### Common Workflows
**Complete a delivery:**
1. Run `test_worldgen.tscn`
2. Walk to settlement, press E near contract board
3. Accept a contract (cargo added to inventory)
4. Drive van to destination settlement (HUD shows distance)
5. Enter delivery radius (140px) to auto-complete

**Test inventory:**
1. Run `test_inventory.tscn`
2. Press Tab to open inventory
3. Drag items, press R to rotate
4. Right-click items to assign to hotbar (weapons/consumables only)
5. Press 1-5 to activate hotbar slots

## Architecture Principles

### Resource-Driven Design
- **All game data lives in `.tres` files**, not hardcoded in scripts
- Item stats, vehicle properties, contract details, biomes, POIs → all defined as Resource instances
- Example: `resources/vehicles/examples/delivery_van.tres` defines van speed, fuel capacity, storage size

**Why:** Designers can modify balance without touching code. Hot-reloadable in editor.

### Component-Based Architecture
- Small, focused, reusable components attached to entities
- **Player** = CharacterBody2D + LocomotionComponent + Inventory + InteractionComponent
- **Vehicle** = CharacterBody2D + VehicleController + FuelSystemComponent + Inventory
- Components communicate via signals, not direct references

**Pattern:**
```gdscript
# Component defines functionality
class_name LocomotionComponent extends Node
@export var walk_speed: float = 100.0

# Entity uses component
@onready var locomotion: LocomotionComponent = $LocomotionComponent
```

### Key Resource Scripts
- `item_data.gd` - Base class for all items (extends Resource)
- `vehicle_data.gd` - Defines vehicle stats (speed, fuel, storage)
- `contract_data.gd` - Delivery contract parameters
- `biome_data.gd` - Biome properties (color, spawn rates)
- `poi_data.gd` - POI placement rules (settlements, gas stations)

**Create instances as `.tres` files** (e.g., `medkit.tres`, `delivery_van.tres`, `biome_wasteland.tres`)

## File Structure Logic

```
res://
├── actors/              Entity scenes (player, vehicles, enemies)
│   ├── player/         player.tscn + player.gd
│   └── vehicles/       vehicle_controller.gd + van/delivery_van.tscn
├── components/          Reusable logic components
│   ├── locomotion_component.gd
│   ├── Inventory.gd + InventoryData.gd
│   ├── fuel_system_component.gd
│   ├── interaction_component.gd
│   ├── look_ahead_camera.gd  (8-quadrant racing camera)
│   ├── vehicle_enter_exit_area.gd
│   ├── contract_board_area.gd
│   └── settlement_marker.gd
├── resources/           Resource definition scripts + .tres instances
│   ├── items/          item_data.gd + examples/
│   ├── vehicles/       vehicle_data.gd + examples/
│   ├── contracts/      contract_data.gd + examples/
│   └── world/          biome_data.gd, poi_data.gd + examples/
├── systems/             Game-wide managers (world gen, chunk streaming, POI placement)
│   ├── chunk_manager.gd
│   ├── world_generator.gd
│   ├── poi_placer.gd
│   └── chunk_debug_overlay.gd
├── scenes/              Root scenes + tests/
│   ├── tests/          test_player, test_vehicle, test_worldgen, test_inventory
│   └── world/          settlement.tscn, gas_station.tscn
├── ui/                  UI scenes and scripts
│   ├── player_inventory_ui.gd/.tscn
│   ├── hotbar_ui.gd/.tscn
│   ├── contract_board_ui.gd/.tscn
│   ├── contract_hud.gd/.tscn
│   └── poi_debug_label.gd
├── autoload/            Singletons (ContractManager, SaveSystem, DreadClock)
└── docs/                Design docs (GDD, phase plans, coding standards)
```

**Naming Convention:** All files use `snake_case` (never PascalCase or camelCase).

## Critical Systems (Implemented)

### Inventory System
- **Grid-based** (Resident Evil/Tarkov style), not slot-based
- Player: 8×6 grid, Vehicle: 12×8 grid (vehicle size from VehicleData.storage_grid_size)
- Items have size (e.g., 2×2 cells) and can rotate (R key)
- Weight affects player movement speed (0-20kg: 100%, 20-40kg: 75%, 40-60kg: 50%, 60kg+: 25%)
- Managed by `Inventory` node (attached to player and vehicles)
- UI: `player_inventory_ui.gd` handles drag-and-drop, rotation, multi-tile footprint highlighting

### Hotbar System
- 5 slots (keys 1-5)
- Accepts only Weapons/Consumables (enforced by `item_type` field)
- Each `item_id` can occupy at most one slot (uniqueness enforced)
- Right-click inventory item to assign, right-click hotbar slot to remove
- Managed by `hotbar_ui.gd`

### Vehicle System
- Realistic top-down physics (acceleration, braking, steering)
- Fuel consumption per distance traveled (tracked by `FuelSystemComponent`)
- Enter/exit via interaction (E key when near vehicle)
- Camera switches to `LookAheadCamera` when driving (8-quadrant system with speed zoom)
- Player hidden while driving, shown on exit

### Fuel Consumption
- Calculated as: `distance_km * consumption_rate`
- 1 km = 10,000 pixels
- Default van: 0.5 L/km, 50 L capacity = 100 km range
- Tracked in `fuel_system_component.gd` via position delta

### Interaction System
- `InteractionComponent` (Area2D with 80px radius)
- Detects objects in "interactable" group
- Player presses E → triggers `interaction_triggered` signal
- Player.gd handles signal → calls `enter_vehicle()` or opens contract board

### World Generation & Chunk Streaming
- **Chunk System:**
  - Chunk size: 1024×1024 pixels
  - `ChunkManager` loads chunks by active camera position (Chebyshev distance)
  - Preload margin: 3 chunks, Unload margin: 4 chunks
  - Debug overlay (toggle with P): shows loaded chunks, camera bounds, load/unload rectangles

- **Biomes:**
  - Wasteland (60% of world) - tan/brown, moderate spawn rate
  - Radioactive Zone (40% of world) - green/toxic, higher spawn rate
  - Uses FastNoiseLite for noise-based generation
  - Seed-based (same seed = same world)

- **POI Placement:**
  - Deterministic, data-driven via `poi_data.gd` (allowed_biomes, cell_size_pixels, spawn_chance)
  - Settlements: ~10km apart (170,000 pixels)
  - Gas Stations: ~3-5km spacing
  - Grid-based with jitter to prevent exact alignment
  - Persistent parenting under WorldPOIs to avoid despawn flicker
  - Deduplication per (type, cell) to prevent duplicates
  - Debug overlay shows cell grids, accepted placements (green), biome rejections (orange)

### Contract System
- **ContractManager** (autoload singleton) manages offers and active contract
- Workflow:
  1. Player enters settlement, presses E near contract board
  2. `contract_board_ui.gd` opens, shows 3-5 generated offers
  3. Offers use straight-line distance, payment_per_km (default 12 credits/km)
  4. Accept contract → cargo added to player inventory
  5. `contract_hud.gd` displays: cargo → destination, distance
  6. Contract auto-completes when player within 140px of destination settlement
  7. Cargo removed from inventory, payment awarded

- **Contract Generation:**
  - Uses `ContractManager.generate_offers()` with base `ContractData` template
  - Randomizes cargo from package variations (small, medium, large, letter, etc.)
  - Distance range filtering (attempts to stay within template range)

### Save System
- Manual save/load: K (save), L (load)
- Auto-save near settlements (configurable, disabled by default)
- JSON format: `user://save_game.json`
- Saves: player position, inventories, vehicle state, fuel, active contracts
- 5-second cooldown prevents save spam

### Ground Item System
- Drop items with D key, spawn as WorldItem nodes
- Pickup prompt UI with arrow keys/scroll wheel selection
- 80px pickup radius, visual representation using `world_icon` texture

### DreadClock Night Cycle
- 3-band night system: Calm (18:00-23:59) → Hunt (00:00-02:59) → False Dawn (03:00-05:59)
- Global scalars for danger, visibility, economy, scarcity
- Visual effects: ambient color overlay + dynamic vignette
- Resource-driven configuration (.tres files)
- Loop resets at 06:00 with glitch effect

## Coding Standards

### Type Hints (Required)
```gdscript
var health: float = 100.0
func take_damage(amount: float) -> void:
@export var max_speed: float = 80.0
```

### Signals for Decoupling
```gdscript
signal fuel_changed(current_fuel: float, max_fuel: float)
signal item_added(item: ItemData, quantity: int)
```

### Naming
- **Files/folders:** snake_case (`player.gd`, `delivery_van.tscn`)
- **Variables:** snake_case (`current_speed`, `is_sprinting`)
- **Constants:** SCREAMING_SNAKE_CASE (`MAX_HEALTH`, `FUEL_CAPACITY`)
- **Private vars/functions:** Prefix with `_` (`_cached_velocity`, `_update_physics()`)
- **Class names:** PascalCase (`class_name Player`, `class_name LocomotionComponent`)

### Indentation
- Use **tabs** (Godot default), not spaces

### Comments
- Only for complex logic (avoid stating the obvious)
- Prefer self-documenting names over comments
- Use `##` for documentation headers on classes/functions

## Development Phases

**Phase 1** (90% Complete): Player movement, vehicle driving, fuel, inventory, world gen, POI placement, contracts
**Phase 2** (Planned): Survival (hunger/thirst/fatigue), skill system, contract tiers, reputation
**Phase 3** (Planned): Enemy AI, combat, ambushes
**Phase 4** (Optional): Vehicle upgrades, weather, permadeath mode

**Detailed plans:** `docs/PHASE_X_*.md` files
**Progress tracking:** `docs/PHASE_1_Progress.md`

## Common Patterns

### Component Attachment
```gdscript
# In player.tscn scene tree:
Player (CharacterBody2D)
├── LocomotionComponent (Node)
├── Inventory (Node)
├── InteractionComponent (Area2D)
└── Camera2D

# In player.gd:
@onready var locomotion: LocomotionComponent = $LocomotionComponent
@onready var inventory: Inventory = $Inventory
```

### Resource Usage
```gdscript
# Define resource script
class_name VehicleData extends Resource
@export var max_speed: float = 80.0

# Create .tres instance in editor (or via script):
# resources/vehicles/examples/delivery_van.tres

# Use in scene:
@export var vehicle_data: VehicleData
```

### Signals
```gdscript
# Define
signal fuel_empty()

# Emit
fuel_empty.emit()

# Connect
fuel_system.fuel_empty.connect(_on_fuel_empty)
```

### Interactables
```gdscript
# Add to "interactable" group in scene
# Implement get_interaction_type() method
func get_interaction_type() -> String:
	return "vehicle"  # or "contract_board", etc.
```

## Known Issues & Quirks

- **Camera file:** Must be `look_ahead_camera.gd` (snake_case). Old `LookAheadCamera.gd` causes class name conflicts.
- **Main scene UID:** If you see "Unrecognized UID" errors, check `project.godot` line 14 uses direct path, not UID.
- **Component references:** Always use `@onready` for child node refs to avoid null errors in `_ready()`.
- **Contract completion:** Uses 140px radius check (see `ContractManager.delivery_radius_px`).
- **Cardinal directions in debug label:** Fixed mapping (90° = "S", -90° = "N", etc.).
- **POI cleanup:** `poi_placer.gd` uses safe cleanup with `is_instance_valid()` checks to prevent errors.

## Documentation Hierarchy

1. **CLAUDE.md** (this file) - Quick reference for AI assistants
2. **README.md** - Project overview for developers
3. **docs/GDD.md** - Master game design document (mechanics, systems, pillars)
4. **docs/CODING_STANDARDS.md** - Detailed code style guide
5. **docs/PHASE_1_CORE_DELIVERY_LOOP.md** - Phase 1 implementation plan
6. **docs/PHASE_1_Progress.md** - Current progress tracker (most accurate status)
7. **docs/PHASE_X_*.md** - Implementation plans for each phase

**When implementing features:** Check `PHASE_1_Progress.md` for current status, then corresponding phase doc for detailed specs.

## Critical Design Decisions

### Inverse Reputation System (Phase 2)
- High reputation = better contracts BUT more enemy ambushes
- Rationale: High-value couriers are bigger targets
- Balances risk/reward (stay safe at low rep, or chase profit at high rep)

### Delivery-First Gameplay
- Combat is defensive/optional, not the focus
- Players should feel like couriers avoiding danger, not action heroes
- Fleeing in vehicle is a valid strategy

### Project Zomboid-Style Skills (Phase 2)
- Skills improve through use (drive more → better fuel efficiency)
- No skill trees or XP points
- Driving, Fitness, Mechanical, Combat

### Grid Inventory Philosophy
- Tetris-style placement creates strategic packing decisions
- Weight affects player speed (realistic encumbrance)
- Vehicle storage is larger but immobile (must be near van to access)

## Phase 1 Remaining Tasks

**High Priority:**
- Lighting system debug (cone-based flashlight has performance issues)
- Vehicle lights follow cursor instead of vehicle direction

**Medium Priority:**
- Roads between settlements (greedy/MST algorithm, per-chunk rendering)
- Gas station refueling interaction
- Fuel gauge UI element
- Money/credits display in HUD

See `docs/PHASE_1_Progress.md` for detailed status.

## Testing Checklist

Before committing:
- [ ] No errors in Godot console
- [ ] Type hints on all variables/functions
- [ ] Files use snake_case naming
- [ ] Components work independently (testable in isolation)
- [ ] `.tres` resources used for data (not hardcoded values)
- [ ] Signals used for inter-component communication
- [ ] Test in relevant scene (test_worldgen for world systems, test_inventory for inventory, etc.)

## Tuning Knobs (Exported Properties)

**WorldGenerator** (`systems/world_generator.gd`):
- `biome_noise_frequency` - Controls biome size variation
- `biome_threshold` - Wasteland vs Radioactive ratio

**ChunkManager** (`systems/chunk_manager.gd`):
- `preload_margin_chunks` - How far ahead to load (default: 3)
- `unload_margin_chunks` - When to unload (default: 4)
- `track_active_camera` - Follow active camera vs specific target

**POI Resources** (`resources/world/examples/*.tres`):
- `cell_size_pixels` - Grid cell size for placement
- `spawn_chance` - Probability of spawning in valid cell
- `allowed_biomes` - Which biomes can spawn this POI

**ContractManager** (`autoload/contract_manager.gd`):
- `min_offers` / `max_offers` - Number of contracts to generate
- `delivery_radius_px` - Completion detection radius (default: 140.0)

**POIDebugLabel** (`ui/poi_debug_label.gd`):
- `use_radial_compass` - Use radial sectors vs cardinal directions
- `compass_sector_deg` - Sector size for radial compass
- `use_auto_camera_when_in_vehicle` - Auto-switch to vehicle camera for direction

## Input Actions (project.godot)

**Movement:**
- `move_up` - W
- `move_down` - S
- `move_left` - A
- `move_right` - D
- `sprint` - Shift

**Interaction:**
- `interact` - E
- `vehicle_enter_exit` - E (same as interact)

**Inventory:**
- `inventory_toggle` - Tab
- `rotate_item` - R
- `drop_item` - D

**Hotbar:**
- `hotbar_1` through `hotbar_5` - 1, 2, 3, 4, 5

**Save/Load:**
- `save_now` - K
- `load_save` - L

**Ground Items:**
- Arrow Keys (↑↓) - Select item in pickup prompt
- Mouse Wheel - Alternate selection method
- `interact` (E) - Pick up selected item

**Combat (Phase 3):**
- `fire` - Left Mouse Button
- `reload` - R

## Example Item Resource

```gdscript
# resources/items/examples/package_small.tres
[gd_resource type="Resource" script_class="ItemData" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/items/item_data.gd" id="1_item"]

[resource]
script = ExtResource("1_item")
item_id = "package_small"
item_name = "Small Package"
grid_size = Vector2i(1, 1)  # 1×1 cell
weight = 0.5
stackable = true
max_stack = 10
item_type = "Cargo"  # Cargo, Weapon, Consumable, Tool, Quest
```

## Example Contract Workflow (Code)

```gdscript
# In settlement scene, attach contract_board_area.gd to Area2D
# player.gd handles interaction:

func _on_interaction_triggered(interactable: Node) -> void:
	if interactable.get_interaction_type() == "contract_board":
		var settlement = interactable.get_settlement()
		var base_contract = ContractData.new()
		base_contract.cargo_item = load("res://resources/items/examples/delivery_package.tres")
		base_contract.payment_per_km = 12.0

		# Generate offers and open UI
		var offers = ContractManager.generate_offers(settlement, base_contract)
		contract_board_ui.open(settlement, offers, self)

# When player accepts:
ContractManager.accept_offer(selected_offer, player)

# In player._process():
ContractManager.try_complete(self)  # Auto-checks distance and completes
```

## Autoload Singletons

- **ContractManager** - `res://autoload/contract_manager.gd`
- **SaveSystem** - `res://systems/save_system.gd`
- **DreadClock** - `res://autoload/dread_clock.gd`
- **GDAIMCPRuntime** - `res://addons/gdai-mcp-plugin-godot/gdai_mcp_runtime.gd` (MCP plugin)

Access via: `ContractManager.function_name()`