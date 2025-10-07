# Coding Standards & Best Practices
## Wasteland Courier Project

**Version:** 1.0
**Engine:** Godot 4.x (GDScript)
**Last Updated:** 2025-10-05

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [Naming Conventions](#naming-conventions)
3. [File Organization](#file-organization)
4. [GDScript Standards](#gdscript-standards)
5. [Resource (.tres) Design](#resource-tres-design)
6. [Component Architecture](#component-architecture)
7. [Signals & Communication](#signals--communication)
8. [Performance Guidelines](#performance-guidelines)
9. [Documentation](#documentation)
10. [Common Patterns](#common-patterns)

---

## Core Principles

### 1. **Resource-Driven Development**
- Prefer .tres files over hardcoded values
- Separate data from logic
- Make game content modifiable without code changes
- Enable hot-reloading for rapid iteration

### 2. **Beginner-Friendly Code**
- Write self-documenting code (clear variable/function names)
- Keep functions small and focused (< 50 lines ideal)
- Use composition over inheritance
- Avoid clever tricks - clarity > brevity

### 3. **Type Safety**
- Always use type hints
- Leverage Godot 4's static typing
- Catch errors at edit-time, not runtime

### 4. **Godot Best Practices**
- Follow official Godot style guide
- Use built-in nodes when possible
- Prefer signals over direct calls
- Utilize @export for designer-facing values

---

## Naming Conventions

### Files

**Scripts (.gd):**
```
✅ player_controller.gd
✅ inventory_component.gd
✅ world_generator.gd
❌ PlayerController.gd (PascalCase)
❌ inventoryComponent.gd (camelCase)
❌ WORLD_GENERATOR.gd (SCREAMING_SNAKE_CASE)
```

**Scenes (.tscn):**
```
✅ player.tscn
✅ delivery_van.tscn
✅ contract_board_ui.tscn
❌ Player.tscn
❌ DeliveryVan.tscn
```

**Resources (.tres):**
```
✅ pistol.tres
✅ delivery_van_data.tres
✅ biome_wasteland.tres
❌ Pistol.tres
❌ deliveryVanData.tres
```

**Folders:**
```
✅ actors/
✅ world_generation/
✅ ui_elements/
❌ Actors/
❌ WorldGeneration/
```

### Variables

**Local Variables:**
```gdscript
var player_health: float = 100.0
var movement_speed: int = 150
var is_sprinting: bool = false
var target_position: Vector2 = Vector2.ZERO
```

**Constants:**
```gdscript
const MAX_HEALTH: float = 100.0
const SPRINT_MULTIPLIER: float = 1.75
const INVENTORY_SIZE: Vector2i = Vector2i(8, 6)
```

**Private Variables (prefix with _):**
```gdscript
var _cached_velocity: Vector2
var _internal_timer: float = 0.0
var _previous_position: Vector2
```

**Export Variables:**
```gdscript
@export var max_speed: float = 80.0
@export_range(0.0, 1.0) var fuel_efficiency: float = 0.5
@export var item_data: ItemData
```

### Functions

**Public Functions:**
```gdscript
func take_damage(amount: float) -> void:
	health -= amount

func get_current_speed() -> float:
	return velocity.length()

func can_afford(price: int) -> bool:
	return credits >= price
```

**Private Functions (prefix with _):**
```gdscript
func _update_velocity(delta: float) -> void:
	_velocity = _velocity.lerp(_target_velocity, delta * 5.0)

func _calculate_fuel_consumption() -> float:
	return distance_traveled * fuel_rate
```

**Lifecycle Functions (Godot callbacks):**
```gdscript
func _ready() -> void:
	# Initialization

func _process(delta: float) -> void:
	# Frame update

func _physics_process(delta: float) -> void:
	# Physics update
```

### Classes

**Class Names (PascalCase):**
```gdscript
class_name PlayerController
class_name ItemData
class_name VehicleController
class_name InventoryComponent
```

**Enums:**
```gdscript
enum State {
	IDLE,
	WALKING,
	SPRINTING,
	DRIVING
}

enum ContractTier {
	NOVICE,
	EXPERIENCED,
	EXPERT
}
```

---

## File Organization

### Directory Structure

```
res://
├── actors/
│   ├── player/
│   │   ├── player.tscn
│   │   ├── player.gd
│   │   └── components/ (player-specific components)
│   ├── enemies/
│   │   ├── raider.tscn
│   │   └── raider_ai.gd
│   └── vehicles/
│       ├── vehicle_controller.gd
│       └── van/
│           └── delivery_van.tscn
│
├── components/           # Reusable components
│   ├── health_component.gd
│   ├── inventory_component.gd
│   ├── interaction_component.gd
│   └── skill_component.gd
│
├── resources/            # All .tres data files
│   ├── items/
│   │   ├── item_data.gd          # Base resource script
│   │   ├── weapon_data.gd
│   │   ├── consumable_data.gd
│   │   └── examples/
│   │       ├── pistol.tres
│   │       ├── medkit.tres
│   │       └── canned_food.tres
│   │
│   ├── vehicles/
│   │   ├── vehicle_data.gd
│   │   └── examples/
│   │       ├── delivery_van.tres
│   │       └── motorcycle.tres
│   │
│   ├── contracts/
│   │   ├── contract_data.gd
│   │   └── examples/
│   │       ├── tier1_supplies.tres
│   │       └── tier2_medicine.tres
│   │
│   ├── enemies/
│   │   ├── enemy_data.gd
│   │   └── examples/
│   │       └── raider.tres
│   │
│   └── world/
│       ├── biome_data.gd
│       ├── poi_data.gd
│       └── examples/
│           ├── biome_wasteland.tres
│           └── poi_settlement.tres
│
├── systems/              # Game systems (managers)
│   ├── inventory_system.gd
│   ├── contract_system.gd
│   ├── world_generator.gd
│   ├── chunk_manager.gd
│   ├── save_system.gd
│   └── skill_system.gd
│
├── autoload/             # Singleton scripts
│   ├── game_manager.gd
│   ├── event_bus.gd
│   └── audio_manager.gd
│
├── ui/
│   ├── inventory_ui.tscn
│   ├── inventory_ui.gd
│   ├── hud.tscn
│   └── contract_board_ui.tscn
│
├── scenes/
│   ├── main.tscn                  # Root scene
│   ├── world/
│   │   ├── settlement.tscn
│   │   └── gas_station.tscn
│   └── tests/
│       └── test_inventory.tscn
│
├── assets/               # Art, audio, fonts
│   ├── sprites/
│   │   ├── player/
│   │   ├── vehicles/
│   │   └── items/
│   ├── audio/
│   │   ├── sfx/
│   │   └── music/
│   └── fonts/
│
├── docs/                 # All documentation
│   ├── GDD.md
│   ├── CODING_STANDARDS.md
│   ├── PHASE_1_CORE_DELIVERY_LOOP.md
│   └── system_docs/
│
└── tests/                # Test scenes

```

---

## GDScript Standards

### Type Hints (ALWAYS)

**Variables:**
```gdscript
✅ var health: float = 100.0
✅ var player: CharacterBody2D
✅ var items: Array[ItemData] = []
❌ var health = 100.0 (no type)
❌ var player (no type, no initialization)
```

**Function Parameters & Returns:**
```gdscript
✅ func take_damage(amount: float) -> void:
✅ func get_item(index: int) -> ItemData:
✅ func calculate_distance(a: Vector2, b: Vector2) -> float:
❌ func take_damage(amount):
❌ func get_item(index):
```

**Arrays with Type:**
```gdscript
✅ var enemies: Array[Enemy] = []
✅ var positions: Array[Vector2] = []
✅ var names: Array[String] = ["Alice", "Bob"]
❌ var enemies = []
❌ var positions: Array = []
```

### Indentation

**Use TABS (Godot default):**
```gdscript
func _ready() -> void:
	if player:
		player.health = 100.0
		if player.has_method("reset"):
			player.reset()
```

### Comments

**Only for Complex Logic:**
```gdscript
# ✅ Good: Explains non-obvious algorithm
# Calculate lookahead position using exponential smoothing
# to prevent camera jitter during sharp turns
var lookahead: Vector2 = velocity * lookahead_time * (1.0 - exp(-delta * smoothing))

# ❌ Bad: States the obvious
# Set health to 100
health = 100.0
```

**Self-Documenting Code Preferred:**
```gdscript
# ✅ Good: Clear variable/function names
func is_over_encumbered() -> bool:
	return current_weight > max_weight

# ❌ Bad: Needs comment to explain
func check() -> bool:  # Returns true if weight exceeds capacity
	return w > max_w
```

**TODOs:**
```gdscript
# TODO: Implement vehicle damage particles
# FIXME: Fuel consumption calculation is off at high speeds
# HACK: Temporary workaround until physics refactor
```

### Constants vs. Magic Numbers

**Bad (magic numbers):**
```gdscript
func _process(delta: float) -> void:
	if velocity.length() > 200:
		apply_friction(0.95)
```

**Good (named constants):**
```gdscript
const MAX_SPEED: float = 200.0
const FRICTION_COEFFICIENT: float = 0.95

func _process(delta: float) -> void:
	if velocity.length() > MAX_SPEED:
		apply_friction(FRICTION_COEFFICIENT)
```

### Error Handling

**Check for Null:**
```gdscript
func interact_with_vehicle(vehicle: Vehicle) -> void:
	if not vehicle:
		push_error("Vehicle is null")
		return

	vehicle.enter()
```

**Assert for Development:**
```gdscript
func set_health(value: float) -> void:
	assert(value >= 0.0, "Health cannot be negative")
	health = clamp(value, 0.0, max_health)
```

**Graceful Degradation:**
```gdscript
func load_item_data(path: String) -> ItemData:
	if not ResourceLoader.exists(path):
		push_warning("Item data not found: %s" % path)
		return default_item_data  # Fallback

	return load(path) as ItemData
```

---

## Resource (.tres) Design

### Resource Scripts

**Base Resource Definition:**
```gdscript
# resources/items/item_data.gd
class_name ItemData extends Resource

@export var item_name: String = "Unknown Item"
@export var icon: Texture2D
@export var grid_size: Vector2i = Vector2i(1, 1)
@export var weight: float = 1.0
@export var stackable: bool = false
@export var max_stack: int = 1
@export_multiline var description: String = ""
```

**Extending Resources:**
```gdscript
# resources/items/weapon_data.gd
class_name WeaponData extends ItemData

@export var damage: float = 10.0
@export var fire_rate: float = 0.5  # Seconds between shots
@export var magazine_size: int = 10
@export var reload_time: float = 2.0
@export var ammo_type: String = "9mm"
@export var projectile_speed: float = 800.0
@export_range(0.0, 1.0) var accuracy: float = 0.95
```

### Resource Instances (.tres files)

**Example: Pistol**
```gdscript
# resources/items/examples/pistol.tres
# (Created in Godot Inspector)
extends WeaponData

item_name = "9mm Pistol"
grid_size = Vector2i(2, 2)
weight = 1.2
damage = 20.0
fire_rate = 0.5
magazine_size = 12
reload_time = 2.0
ammo_type = "9mm"
projectile_speed = 800.0
accuracy = 0.95
```

### Benefits

✅ **Non-programmers can create content** (designers, artists)
✅ **Easy to balance** (tweak numbers in inspector)
✅ **Version control friendly** (text-based .tres files)
✅ **Hot-reload** (change and see results instantly)
✅ **No recompilation** (not code)

---

## Component Architecture

### Component Pattern

**Small, Focused Components:**
```gdscript
# components/health_component.gd
class_name HealthComponent extends Node

signal health_changed(new_health: float)
signal died()

@export var max_health: float = 100.0
var current_health: float

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)

	if current_health <= 0:
		died.emit()

func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)

func is_alive() -> bool:
	return current_health > 0
```

**Usage (Composition):**
```gdscript
# actors/player/player.gd
class_name Player extends CharacterBody2D

@onready var health_component: HealthComponent = $HealthComponent
@onready var inventory_component: InventoryComponent = $InventoryComponent

func _ready() -> void:
	health_component.died.connect(_on_player_died)

func _on_player_died() -> void:
	print("Player died!")
	# Handle death logic
```

**Scene Structure:**
```
Player (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── HealthComponent
├── InventoryComponent
├── InteractionComponent
└── LocomotionComponent
```

### Benefits

✅ **Reusable** (attach to any entity)
✅ **Testable** (test components in isolation)
✅ **Maintainable** (small files, clear responsibility)
✅ **Flexible** (mix and match components)

---

## Signals & Communication

### Define Signals Clearly

```gdscript
signal health_changed(new_health: float)
signal item_picked_up(item: ItemData)
signal contract_completed(contract: ContractData, payment: int)
signal enemy_spotted(enemy: Enemy, distance: float)
```

### Emit Signals

```gdscript
func complete_contract(contract: ContractData) -> void:
	var payment: int = calculate_payment(contract)
	contract_completed.emit(contract, payment)
```

### Connect Signals

**In Code:**
```gdscript
func _ready() -> void:
	player.health_changed.connect(_on_player_health_changed)

func _on_player_health_changed(new_health: float) -> void:
	health_bar.value = new_health
```

**In Editor:**
- Use Inspector to connect signals visually
- Generated code: `_on_<node_name>_<signal_name>`

### Event Bus (Autoload)

**For Global Events:**
```gdscript
# autoload/event_bus.gd
extends Node

signal contract_started(contract: ContractData)
signal contract_completed(contract: ContractData)
signal player_died()
signal reputation_changed(new_rep: int)
```

**Usage:**
```gdscript
# Anywhere in code
EventBus.contract_completed.emit(current_contract)

# Listen
EventBus.reputation_changed.connect(_on_reputation_changed)
```

---

## Performance Guidelines

### Avoid in _process()

**Bad:**
```gdscript
func _process(delta: float) -> void:
	# Expensive operations every frame
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if global_position.distance_to(enemy.global_position) < 500:
			# Do something
```

**Good:**
```gdscript
var _nearby_enemies: Array[Enemy] = []
@onready var _check_timer: Timer = $CheckTimer

func _ready() -> void:
	_check_timer.timeout.connect(_update_nearby_enemies)
	_check_timer.start(0.5)  # Check every 0.5 seconds

func _update_nearby_enemies() -> void:
	_nearby_enemies.clear()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(enemy.global_position) < 500:
			_nearby_enemies.append(enemy)

func _process(delta: float) -> void:
	# Use cached list
	for enemy in _nearby_enemies:
		# Do something
```

### Object Pooling

**For frequently spawned/destroyed objects:**
```gdscript
# systems/projectile_pool.gd
class_name ProjectilePool extends Node

const POOL_SIZE: int = 50
var _pool: Array[Projectile] = []
var _active: Array[Projectile] = []

func _ready() -> void:
	for i in POOL_SIZE:
		var projectile = preload("res://actors/projectile.tscn").instantiate()
		projectile.process_mode = Node.PROCESS_MODE_DISABLED
		_pool.append(projectile)
		add_child(projectile)

func get_projectile() -> Projectile:
	if _pool.is_empty():
		push_warning("Projectile pool exhausted")
		return null

	var projectile = _pool.pop_back()
	projectile.process_mode = Node.PROCESS_MODE_INHERIT
	_active.append(projectile)
	return projectile

func return_projectile(projectile: Projectile) -> void:
	_active.erase(projectile)
	projectile.process_mode = Node.PROCESS_MODE_DISABLED
	_pool.append(projectile)
```

### Cache Nodes

**Bad:**
```gdscript
func _process(delta: float) -> void:
	$HUD/HealthBar.value = health
	$HUD/FuelGauge.value = fuel
```

**Good:**
```gdscript
@onready var _health_bar: ProgressBar = $HUD/HealthBar
@onready var _fuel_gauge: ProgressBar = $HUD/FuelGauge

func _process(delta: float) -> void:
	_health_bar.value = health
	_fuel_gauge.value = fuel
```

---

## Documentation

### File Headers

**For Complex Systems:**
```gdscript
## World Generator
##
## Handles procedural generation of the game world using chunk-based system.
## Uses FastNoiseLite for biome distribution and ensures POI placement
## respects minimum distance constraints.
##
## @tutorial: docs/system_docs/WORLD_GENERATION_GUIDE.md

class_name WorldGenerator extends Node
```

### Function Documentation

**For Public APIs:**
```gdscript
## Calculates the payment for a completed contract based on distance and tier.
##
## @param contract: The contract data resource
## @param actual_distance: Distance traveled in pixels
## @return: Payment amount in credits
func calculate_payment(contract: ContractData, actual_distance: float) -> int:
	var base_payment: float = contract.payment_per_km * (actual_distance / 10000.0)
	var tier_multiplier: float = contract.get_tier_multiplier()
	return int(base_payment * tier_multiplier)
```

---

## Common Patterns

### Singleton Pattern (Autoload)

```gdscript
# autoload/game_manager.gd
extends Node

var player: Player
var current_contract: ContractData
var credits: int = 500
var reputation: int = 0

func add_credits(amount: int) -> void:
	credits += amount
	EventBus.credits_changed.emit(credits)

func add_reputation(amount: int) -> void:
	reputation += amount
	EventBus.reputation_changed.emit(reputation)
```

**Access Anywhere:**
```gdscript
GameManager.add_credits(100)
print(GameManager.reputation)
```

### State Machine Pattern

```gdscript
enum State {
	IDLE,
	WALKING,
	SPRINTING,
	DRIVING
}

var current_state: State = State.IDLE

func _process(delta: float) -> void:
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.WALKING:
			_process_walking(delta)
		State.SPRINTING:
			_process_sprinting(delta)
		State.DRIVING:
			_process_driving(delta)

func change_state(new_state: State) -> void:
	_exit_state(current_state)
	current_state = new_state
	_enter_state(new_state)
```

### Factory Pattern

```gdscript
# systems/enemy_spawner.gd
class_name EnemySpawner extends Node

const RAIDER_SCENE = preload("res://actors/enemies/raider.tscn")

func spawn_enemy(enemy_data: EnemyData, position: Vector2) -> Enemy:
	var enemy = RAIDER_SCENE.instantiate()
	enemy.global_position = position
	enemy.data = enemy_data
	add_child(enemy)
	return enemy
```

---

## Anti-Patterns (Avoid)

### ❌ Hardcoded Values

```gdscript
# Bad
if speed > 80:
	apply_boost(1.5)
```

### ❌ Deep Nesting

```gdscript
# Bad
if is_alive:
	if has_weapon:
		if ammo > 0:
			if can_shoot:
				shoot()
```

### ❌ God Objects

```gdscript
# Bad: Player class does EVERYTHING
class_name Player extends CharacterBody2D
	# 50+ @export variables
	# 2000+ lines of code
	# Handles movement, combat, inventory, UI, etc.
```

### ❌ Global State Abuse

```gdscript
# Bad: Everything in globals
var player_health = 100
var player_pos = Vector2.ZERO
var enemy_count = 0
var current_level = 1
# ... 100 more global variables
```

---

## Code Review Checklist

Before committing code, verify:

- [ ] All variables have type hints
- [ ] All functions have return type hints
- [ ] File names use snake_case
- [ ] Class names use PascalCase
- [ ] Tabs used for indentation
- [ ] No magic numbers (use constants)
- [ ] @export used for designer-facing values
- [ ] Signals used for decoupling
- [ ] Comments only for complex logic
- [ ] Performance considered (_process usage)
- [ ] Null checks for unsafe operations
- [ ] Resource files (.tres) preferred over hardcoded data

---

## Version History

**Version 1.0 (2025-10-05):**
- Initial coding standards document
- Established naming conventions
- Defined file organization
- Created resource-driven guidelines
