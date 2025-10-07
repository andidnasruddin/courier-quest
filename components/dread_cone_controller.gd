class_name DreadConeController
extends Node2D

## Main controller for the DreadConeRefactored visibility system.
## Manages the hybrid Light2D + shader approach for player vision cones.
## Supports multiple states (walk, sprint, aim, vehicle) with data-driven configuration.

signal state_changed(new_state: DreadConeConfig.DreadConeState)
signal cone_config_updated(config: DreadConeConfig)

# Exported configuration for easy setup in the editor
@export var walk_config: DreadConeConfig : set = set_walk_config
@export var sprint_config: DreadConeConfig : set = set_sprint_config
@export var aim_config: DreadConeConfig : set = set_aim_config
@export var vehicle_config: DreadConeConfig : set = set_vehicle_config
@export var vehicle_high_beam_config: DreadConeConfig : set = set_vehicle_high_beam_config

@export var auto_start := true
@export var debug_mode := false

# Internal components
var dread_cone_light: PointLight2D
var dread_cone_mask: ColorRect
var current_config: DreadConeConfig
var current_state := DreadConeConfig.DreadConeState.WALK

# Performance tracking
var last_update_time := 0.0
var update_rate := 1.0 / 60.0  # 60 FPS target

func _ready() -> void:
	if auto_start:
		initialize()

func initialize() -> void:
	_setup_components()
	_load_default_configs()
	_set_state(DreadConeConfig.DreadConeState.WALK)
	
	if debug_mode:
		print("DreadConeController initialized")

func _setup_components() -> void:
	# Create the Light2D component for dynamic shadows
	dread_cone_light = PointLight2D.new()
	dread_cone_light.name = "DreadConeLight"
	dread_cone_light.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dread_cone_light.texture = preload("res://icon.svg")  # Use existing icon as placeholder
	dread_cone_light.blend_mode = Light2D.BLEND_MODE_ADD
	add_child(dread_cone_light)
	
	# Create the shader mask for FOV restriction
	dread_cone_mask = ColorRect.new()
	dread_cone_mask.name = "DreadConeMask"
	dread_cone_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dread_cone_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dread_cone_mask)
	
	# Set up the shader material
	var shader_material := ShaderMaterial.new()
	shader_material.shader = preload("res://shaders/cone_visibility_mask.gdshader")
	dread_cone_mask.material = shader_material

func _load_default_configs() -> void:
	# Load default configurations if not set
	if not walk_config:
		walk_config = load("res://resources/visibility/examples/default_walk_cone.tres") as DreadConeConfig
	if not sprint_config:
		sprint_config = load("res://resources/visibility/examples/default_sprint_cone.tres") as DreadConeConfig
	if not aim_config:
		aim_config = load("res://resources/visibility/examples/default_aim_cone.tres") as DreadConeConfig
	if not vehicle_config:
		vehicle_config = load("res://resources/visibility/examples/default_vehicle_cone.tres") as DreadConeConfig
	if not vehicle_high_beam_config:
		vehicle_high_beam_config = load("res://resources/visibility/examples/default_vehicle_high_beam_cone.tres") as DreadConeConfig

func _process(_delta: float) -> void:
	if not current_config or not dread_cone_light or not dread_cone_mask:
		return
	
	# Performance limiting
	var current_time := Time.get_time_dict_from_system()
	if current_time.get("second", 0) - last_update_time < update_rate:
		return
	
	_update_cone_transform()
	_update_shader_parameters()
	_apply_dread_clock_effects()

func _update_cone_transform() -> void:
	if not current_config:
		return
	
	# Update Light2D properties
	dread_cone_light.position = current_config.cone_origin_offset
	dread_cone_light.rotation = current_config.cone_direction
	# Godot 4: PointLight2D.texture_scale is a float (uniform). Use it for overall range scaling.
	dread_cone_light.texture_scale = current_config.cone_range_scale
	dread_cone_light.color = current_config.light_color
	dread_cone_light.energy = current_config.light_intensity
	dread_cone_light.shadow_enabled = current_config.cast_shadows
	
	# Update cone angle for Light2D (converted to texture scale)
	var cone_scale: float = current_config.cone_angle_degrees / 90.0
	# Light2D does not support per-axis texture scale; use Node2D scale for horizontal stretch
	dread_cone_light.scale = Vector2(cone_scale, 1.0)

func _update_shader_parameters() -> void:
	if not current_config or not dread_cone_mask.material:
		return
	
	var material := dread_cone_mask.material as ShaderMaterial
	material.set_shader_parameter("cone_origin", current_config.cone_origin_offset)
	material.set_shader_parameter("cone_direction", current_config.cone_direction)
	material.set_shader_parameter("cone_angle", deg_to_rad(current_config.cone_angle_degrees))
	material.set_shader_parameter("cone_range", current_config.cone_range_pixels)
	material.set_shader_parameter("edge_softness", current_config.edge_softness)
	material.set_shader_parameter("vignette_strength", current_config.vignette_strength)
	material.set_shader_parameter("vignette_color", current_config.vignette_color)

func _apply_dread_clock_effects() -> void:
	if not DreadClock or not current_config:
		return
	
	var clock_intensity: float = 1.0
	var clock_flicker: float = 0.0
	if DreadClock.has_method("get_intensity_multiplier"):
		clock_intensity = float(DreadClock.get_intensity_multiplier())
	else:
		var vis_mult :float = DreadClock.get("visibility_mult")
		if typeof(vis_mult) == TYPE_FLOAT:
			clock_intensity = float(vis_mult)
	if DreadClock.has_method("get_flicker_amount"):
		clock_flicker = float(DreadClock.get_flicker_amount())
	
	# Apply intensity modulation
	var modulated_intensity: float = current_config.light_intensity * clock_intensity
	dread_cone_light.energy = modulated_intensity
	
	# Apply flicker effect if enabled
	if current_config.shadow_flicker_enabled and clock_flicker > 0.1:
		var flicker_offset: float = sin(Time.get_time_dict_from_system().get("second", 0) * 10.0) * clock_flicker * 5.0
		dread_cone_light.position += Vector2(flicker_offset, flicker_offset)

func set_state(new_state: DreadConeConfig.DreadConeState) -> void:
	if current_state == new_state:
		return
	
	current_state = new_state
	_set_state(new_state)
	state_changed.emit(new_state)

func _set_state(state: DreadConeConfig.DreadConeState) -> void:
	match state:
		DreadConeConfig.DreadConeState.WALK:
			current_config = walk_config
		DreadConeConfig.DreadConeState.SPRINT:
			current_config = sprint_config
		DreadConeConfig.DreadConeState.AIM:
			current_config = aim_config
		DreadConeConfig.DreadConeState.VEHICLE:
			current_config = vehicle_config
		DreadConeConfig.DreadConeState.VEHICLE_HIGH_BEAM:
			current_config = vehicle_high_beam_config
		_:
			current_config = walk_config
	
	if current_config:
		cone_config_updated.emit(current_config)
		if debug_mode:
			print("DreadCone state changed to: ", state)

func set_walk_config(config: DreadConeConfig) -> void:
	walk_config = config
	if current_state == DreadConeConfig.DreadConeState.WALK:
		_set_state(DreadConeConfig.DreadConeState.WALK)

func set_sprint_config(config: DreadConeConfig) -> void:
	sprint_config = config
	if current_state == DreadConeConfig.DreadConeState.SPRINT:
		_set_state(DreadConeConfig.DreadConeState.SPRINT)

func set_aim_config(config: DreadConeConfig) -> void:
	aim_config = config
	if current_state == DreadConeConfig.DreadConeState.AIM:
		_set_state(DreadConeConfig.DreadConeState.AIM)

func set_vehicle_config(config: DreadConeConfig) -> void:
	vehicle_config = config
	if current_state == DreadConeConfig.DreadConeState.VEHICLE:
		_set_state(DreadConeConfig.DreadConeState.VEHICLE)

func set_vehicle_high_beam_config(config: DreadConeConfig) -> void:
	vehicle_high_beam_config = config
	if current_state == DreadConeConfig.DreadConeState.VEHICLE_HIGH_BEAM:
		_set_state(DreadConeConfig.DreadConeState.VEHICLE_HIGH_BEAM)

func get_current_state() -> DreadConeConfig.DreadConeState:
	return current_state

func get_current_config() -> DreadConeConfig:
	return current_config

func is_active() -> bool:
	return is_inside_tree() and visible

func activate() -> void:
	visible = true
	if dread_cone_light:
		dread_cone_light.enabled = true
	if dread_cone_mask:
		dread_cone_mask.visible = true

func deactivate() -> void:
	visible = false
	if dread_cone_light:
		dread_cone_light.enabled = false
	if dread_cone_mask:
		dread_cone_mask.visible = false

# Debug visualization
func _draw() -> void:
	if not debug_mode or not current_config:
		return
	
	# Draw cone outline for debugging
	var cone_points := PackedVector2Array()
	var steps := 32
	var angle_rad := deg_to_rad(current_config.cone_angle_degrees)
	
	# Add cone apex
	cone_points.append(current_config.cone_origin_offset)
	
	# Add cone arc points
	for i in range(steps + 1):
		var angle := current_config.cone_direction - angle_rad / 2.0 + (angle_rad * i / steps)
		var point := current_config.cone_origin_offset + Vector2.from_angle(angle) * current_config.cone_range_pixels
		cone_points.append(point)
	
	# Draw the cone outline
	draw_colored_polygon(cone_points, Color.RED)
