# SYSTEM_DREADCONE_REFACTORED — Hybrid Visibility System

**Goal:** Darkwood-style tunnel vision with dynamic shadow casting for a horror courier delivery game.

**Scope:** Phase 1 foundation (player + vehicle visibility), Phase 2 enemy awareness, Phase 3 polish.

**Depends on:** DreadClock, LocomotionComponent, VehicleController.

---

## 1) Executive Summary

A hybrid visibility system combining Light2D shadow casting with shader-based cone masking. Creates authentic Darkwood-style tunnel vision where only visible areas are illuminated, with proper occlusion from walls, vehicles, and dynamic objects. All parameters are data-driven through `.tres` files for rapid iteration.

### **Key Design Decisions**
- **Hybrid Approach**: Light2D for shadows + shader mask for FOV restriction
- **No Fog of War**: Areas outside current view go completely dark
- **Vehicle Self-Occlusion**: Cone originates from front bumper, not player center
- **Performance Target**: 60 FPS with max 4 shadow-casting lights simultaneously
- **Horror Focus**: Atmospheric tension through restricted vision and shadow dynamics

---

## 2) Architecture Overview

```
┌─────────────────────────────────────────────┐
│  DreadConeController (Master Component)     │
│  - State machine (walk/sprint/aim/drive)    │
│  - Manages both Light2D + Shader systems    │
│  - Camera lead behavior                    │
│  - DreadClock integration                  │
└─────────────────┬───────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
┌───────▼────────┐   ┌──────▼──────┐
│  Light2D       │   │  Shader     │
│  Cone Light    │   │  Mask       │
│  + Shadows     │   │  (FOV)      │
│  (Occlusion)   │   │  (Vignette) │
└────────────────┘   └─────────────┘
        │                   │
        └─────────┬─────────┘
                  │
    ┌─────────────▼─────────────┐
    │  World Occluders          │
    │  - LightOccluder2D        │
    │  - Walls, vehicles,       │
    │  - POI buildings,         │
    │  - Dynamic entities       │
    └───────────────────────────┘
```

---

## 3) Component Architecture

### 3.1 DreadConeController
**File:** `components/dread_cone_controller.gd`

**Responsibilities:**
- Master controller managing entire visibility system
- State transitions (walk/sprint/aim/drive)
- Config loading and switching
- Camera lead calculations
- Synchronizing Light2D angle with shader FOV

**Key Properties:**
```gdscript
@export var walk_config: DreadConeConfig
@export var sprint_config: DreadConeConfig  
@export var aim_config: DreadConeConfig
@export var vehicle_config: DreadConeConfig
@export var enable_camera_lead: bool = true
@export var target_node: Node2D  # Auto-detects parent if not set
```

---

### 3.2 DreadConeLight (Light2D Component)
**File:** `components/dread_cone_light.gd`

**Responsibilities:**
- Generates cone-shaped light texture with proper falloff
- Handles shadow casting against world occluders
- Updates angle based on controller state
- Origin positioning (player center vs vehicle front bumper)

**Key Properties:**
```gdscript
@export_range(30.0, 180.0) var cone_angle: float = 100.0
@export_range(100.0, 1000.0) var cone_range: float = 400.0
@export var enable_shadows: bool = true
@export var light_origin_offset: Vector2 = Vector2.ZERO
```

---

### 3.3 DreadConeMask (Shader Overlay)
**File:** `components/dread_cone_mask.gd`

**Responsibilities:**
- Renders cone visualization overlay
- Handles vignette effects
- Darkens areas outside cone
- Smooth transitions between states

**Key Properties:**
```gdscript
@export var cone_material: ShaderMaterial
@export_range(0.0, 1.0) var edge_softness: float = 0.15
@export_range(0.0, 1.0) var vignette_strength: float = 0.3
```

---

## 4) Data-Driven Configuration

### 4.1 DreadConeConfig Resource
**File:** `resources/visibility/dread_cone_config.gd`

**Complete Properties with Descriptions:**

#### Cone Properties
```gdscript
@export_group("Cone Properties")

@export_range(30.0, 180.0) var fov_degrees: float = 100.0
@export_description("Field of view width in degrees. Wider = more visible area, less horror tension.")

@export_range(100.0, 1000.0) var range_pixels: float = 400.0  
@export_description("How far the cone extends. Longer range = more visibility but more performance cost.")

@export_range(0.0, 1.0) var edge_softness: float = 0.15
@export_description("Softness of cone edges. 0 = hard edge, 1 = very soft/blurred edges.")

@export_range(0.0, 1.0) var outside_cone_luminance: float = 0.25
@export_description("Brightness outside cone. 0 = pure black, 1 = full brightness. Keep low for horror.")
```

#### Visual Effects
```gdscript
@export_group("Visual Effects")

@export_range(0.0, 1.0) var vignette_strength: float = 0.3
@export_description("Edge darkening intensity. Higher = more tunnel vision effect.")

@export_range(0.0, 1.0) var vignette_falloff: float = 0.8
@export_description("How quickly vignette darkens toward edges. Higher = sharper falloff.")

@export var enable_edge_glow: bool = false
@export_description("Subtle glow at cone edges for horror atmosphere. Performance cost.")

@export_range(0.0, 0.5) var edge_glow_intensity: float = 0.1
@export_description("Intensity of edge glow effect when enabled.")
```

#### Camera Behavior
```gdscript
@export_group("Camera Behavior")

@export_range(0.0, 0.3) var camera_lead_percent: float = 0.0
@export_description("Camera offset toward facing direction. 0 = centered, 0.3 = 30% viewport lead.")

@export_range(0.1, 2.0) var camera_lead_speed: float = 3.0
@export_description("How quickly camera moves to lead position. Higher = faster, more responsive.")

@export_range(0.0, 0.1) var zoom_offset: float = 0.0
@export_description("Slight zoom for focus states. 0.05 = 5% zoom in.")
```

#### Transitions
```gdscript
@export_group("Transitions")

@export_range(0.05, 0.5) var transition_time: float = 0.12
@export_description("Time to transition between states in seconds. Faster = more responsive, slower = smoother.")

@export var transition_curve: Curve
@export_description("Easing curve for state transitions. Leave null for default ease-in-out.")
```

#### Horror Effects
```gdscript
@export_group("Horror Effects")

@export_range(-20.0, 20.0) var dread_clock_fov_offset: float = 0.0
@export_description("FOV adjustment during Hunt band. Negative = narrower (more tension), Positive = wider.")

@export_range(-0.2, 0.2) var dread_clock_luminance_offset: float = 0.0
@export_description("Luminance adjustment during Hunt band. Negative = darker, Positive = brighter.")

@export var enable_shadow_flicker: bool = false
@export_description("Occasional shadow flicker during Hunt band for atmosphere.")

@export_range(0.0, 1.0) var shadow_flicker_intensity: float = 0.1
@export_description("Intensity of shadow flicker effect when enabled.")
```

---

## 5) State Definitions

### 5.1 Player States

#### WALK State
- **FOV:** 100° (wide, relaxed)
- **Camera Lead:** 0% (centered)
- **Vignette:** Low (0.2)
- **Use Case:** Normal exploration, reading contracts

#### SPRINT State  
- **FOV:** 70° (narrow, tunnel vision)
- **Camera Lead:** 20% (forward focus)
- **Vignette:** Medium (0.4)
- **Use Case:** Fast movement, escape sequences

#### AIM State
- **FOV:** 58° (very narrow, focused)
- **Camera Lead:** 10% (slight forward)
- **Zoom:** 5% zoom in
- **Vignette:** High (0.5)
- **Use Case:** Weapon aiming, precise interactions

### 5.2 Vehicle States

#### VEHICLE_NORMAL State
- **FOV:** 120° (wider than player - vehicles need more awareness)
- **Origin:** Front bumper offset
- **Camera Lead:** 10-25% based on speed
- **Vignette:** Vehicle-specific tint
- **Use Case:** Normal driving

#### VEHICLE_HIGH_BEAMS State
- **FOV:** 140° (very wide)
- **Range:** +30% longer
- **Risk:** +30% enemy detection radius during Hunt
- **Use Case:** Highway driving, open areas

---

## 6) Integration Points

### 6.1 Player Integration
**File:** `actors/player/player.gd`

```gdscript
# Add to player controller
@onready var dread_cone: DreadConeController = $DreadConeController

func _process(delta: float) -> void:
	_update_dread_cone_state()

func _update_dread_cone_state() -> void:
	if not dread_cone:
		return
	
	if locomotion.is_sprinting:
		dread_cone.set_state(DreadConeController.ConeState.SPRINT)
	elif Input.is_action_pressed("aim"):
		dread_cone.set_state(DreadConeController.ConeState.AIM)
	else:
		dread_cone.set_state(DreadConeController.ConeState.WALK)
```

### 6.2 Vehicle Integration
**File:** `actors/vehicles/vehicle_controller.gd`

```gdscript
# Add to vehicle controller
@onready var dread_cone: DreadConeController = $DreadConeController

func _enter_vehicle() -> void:
	if dread_cone:
		dread_cone.set_state(DreadConeController.ConeState.VEHICLE_NORMAL)
		dread_cone.set_target_node(self)

func _exit_vehicle() -> void:
	if dread_cone:
		dread_cone.set_target_node(player)
```

### 6.3 DreadClock Integration
**File:** `autoload/dread_clock.gd`

```gdscript
# Connect to band changes
func _ready() -> void:
	band_changed.connect(_on_band_changed)

func _on_band_changed(band: Band) -> void:
	# Notify all DreadConeControllers
	var cones := get_tree().get_nodes_in_group("dread_cone")
	for cone in cones:
		cone.apply_dread_clock_effects(band)
```

---

## 7) Performance Optimization

### 7.1 Light Management Rules
- **Maximum 4 shadow-casting lights active simultaneously**
- **Player cone always active**
- **Vehicle cone active when driving**
- **Enemy cones: Maximum 2 closest enemies**
- **Spatial culling: Disable lights outside viewport**

### 7.2 Occluder Optimization
```gdscript
# Simplify occluders based on distance
func get_occluder_lod(distance: float) -> int:
	if distance > 500.0:
		return 0  # Disable occluder
	elif distance > 200.0:
		return 1  # Simple rectangle
	else:
		return 2  # Full detail
```

### 7.3 Shader Performance
- Use `texture_size` uniform instead of calculating in shader
- Cache cone direction calculations
- Avoid complex mathematical operations in fragment shader

---

## 8) Implementation Phases

### Phase 1: Foundation (Ship First)
**Duration:** 3-5 days
**Priority:** CRITICAL

**Deliverables:**
- ✅ DreadConeController with state machine
- ✅ DreadConeConfig resource with full documentation
- ✅ DreadConeLight with shadow casting
- ✅ DreadConeMask shader overlay
- ✅ Player integration (walk/sprint/aim)
- ✅ Vehicle integration (normal driving)
- ✅ Basic LightOccluder2D setup
- ✅ DreadClock integration
- ✅ Camera lead behavior
- ✅ Default .tres configs for all states

**Definition of Done:**
- Player cone works with walk/sprint/aim states
- Vehicle cone works with proper front-bumper origin
- Shadows cast from walls and vehicles
- Camera lead functions correctly
- All parameters adjustable via .tres files
- 60 FPS target achieved with <4 lights active

---

### Phase 2: Enemy Awareness (Add Later)
**Duration:** 2-3 days
**Priority:** HIGH

**Deliverables:**
- Enemy cone visibility system
- Spatial culling for enemy lights
- Enemy "sense" player when in their cone
- Performance monitoring and optimization

---

### Phase 3: Polish (Final)
**Duration:** 2-3 days
**Priority:** MEDIUM

**Deliverables:**
- Complex POI occluders with LOD system
- Edge glow and horror effects
- Shadow flicker during Hunt band
- Peripheral movement hallucinations
- Performance profiling tools

---

## 9) File Structure

```
components/
├── dread_cone_controller.gd          # Master controller
├── dread_cone_light.gd               # Light2D cone component  
├── dread_cone_mask.gd                # Shader overlay component
└── [DEACTIVATED]
    ├── cone_light.gd                 # Old implementation
    ├── flashlight_component.gd
    ├── ambient_darkness.gd
    └── dread_cone_vignette.gd

resources/visibility/
├── dread_cone_config.gd             # Main resource class
└── examples/
    ├── default_walk_cone.tres
    ├── default_sprint_cone.tres
    ├── default_aim_cone.tres
    ├── default_vehicle_cone.tres
    ├── default_vehicle_high_beam.tres
    └── enemy_default_cone.tres

shaders/
├── dread_cone_mask.gdshader          # Refactored cone mask
└── dread_cone_light.gdshader         # Cone light texture generator

docs/specific_systems/
└── system_DreadConeRefactored.md     # This document
```

---

## 10) Testing Strategy

### 10.1 Unit Tests
- Config loading and validation
- State transitions
- Camera lead calculations
- FOV calculations

### 10.2 Integration Tests  
- Player state changes
- Vehicle entry/exit
- DreadClock band effects
- Shadow casting accuracy

### 10.3 Performance Tests
- FPS with 4 active lights + 50 occluders
- Memory usage during state transitions
- Shader performance profiling

### 10.4 Horror Experience Tests
- Does tunnel vision create tension?
- Are shadow transitions jarring?
- Does camera lead feel natural?
- Is vehicle self-occlusion frustrating?

---

## 11) Troubleshooting Guide

### Common Issues

**Problem: Cone not rotating with player**
- Check `target_node` is set correctly
- Verify `_process()` is calling `_update_cone_direction()`
- Ensure cone follows cursor vs rotation based on `cone_follows_cursor`

**Problem: Shadows not appearing**
- Verify LightOccluder2D components exist
- Check `shadow_enabled = true` on Light2D
- Ensure occluder polygons are valid (no self-intersections)

**Problem: Performance drops below 60 FPS**
- Count active shadow-casting lights (max 4)
- Check occluder count in viewport
- Verify LOD system is working
- Profile shader complexity

**Problem: Vehicle blocks own vision**
- Verify `light_origin_offset` is set to front bumper
- Check vehicle LightOccluder2D doesn't overlap cone origin
- Consider partial self-occlusion (50% instead of 100%)

---

## 12) Future Enhancements

### Phase 2+ Features
- Enemy cone awareness system
- Complex POI occluders with LOD
- Fog of war (if requested later)
- Dynamic weather effects on visibility
- Peripheral hallucination effects

### Performance Enhancements
- GPU-based occlusion culling
- Shadow map baking for static geometry
- Compute shader for cone calculations
- Async loading of distant occluders

---

## 13) Success Metrics

### Technical Metrics
- ✅ 60 FPS maintained with 4 lights + 50 occluders
- ✅ State transitions < 150ms
- ✅ Memory usage < 100MB for visibility system
- ✅ Load time impact < 50ms

### Experience Metrics  
- ✅ Player feels tension when cone narrows
- ✅ Camera lead enhances sense of speed
- ✅ Vehicle vision feels natural, not frustrating
- ✅ Horror atmosphere enhanced by shadows
- ✅ All parameters easily adjustable via .tres files

---

## 14) Conclusion

The DreadConeRefactored system provides a robust, performant, and terrifying visibility experience perfect for a horror courier delivery game. The hybrid approach balances visual quality with performance, while the data-driven configuration ensures rapid iteration and fine-tuning.

The phased implementation allows for shipping a solid foundation quickly while leaving room for future enhancements. The system is designed to be modular, maintainable, and extensible as the game evolves.

**Next Step:** Begin Phase 1 implementation starting with DreadConeConfig resource class.
