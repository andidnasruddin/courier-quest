## Dread Cone Configuration Resource
##
## Comprehensive data-driven configuration for DreadCone visibility system.
## Every parameter is documented for easy tweaking.
## Used by DreadConeController to configure cone behavior for different states.
##
## @tutorial: docs/specific_systems/system_DreadConeRefactored.md

@tool
class_name DreadConeConfig extends Resource

## Cone state enumeration for different visibility behaviors
enum DreadConeState {
	WALK,          # Normal walking cone
	SPRINT,        # Sprinting cone (narrower)
	AIM,           # Aiming cone (narrowest)
	VEHICLE,       # Vehicle headlights
	VEHICLE_HIGH_BEAM,  # Vehicle high beams
	ENEMY          # Enemy vision cone
}

# === VISUAL PARAMETERS ===
@export var cone_state: DreadConeState = DreadConeState.WALK
@export var cone_angle_degrees: float = 100.0
@export var cone_range_pixels: float = 400.0
@export var cone_origin_offset: Vector2 = Vector2.ZERO
@export var cone_direction: float = 0.0

# === LIGHT2D PARAMETERS ===
@export var light_color: Color = Color.WHITE
@export var light_intensity: float = 1.0
@export var cone_range_scale: float = 1.0
@export var cast_shadows: bool = true

# === SHADER PARAMETERS ===
@export var edge_softness: float = 0.15
@export var vignette_strength: float = 0.3
@export var vignette_color: Color = Color.BLACK

# === DREAD CLOCK INTEGRATION ===
@export var shadow_flicker_enabled: bool = true
@export var dread_clock_intensity_scale: float = 1.0

# === TRANSITION PARAMETERS ===
@export var transition_speed: float = 5.0
@export var smooth_transitions: bool = true

# === PERFORMANCE PARAMETERS ===
@export var update_rate: float = 60.0
@export var enable_distance_culling: bool = false
@export var culling_distance: float = 1000.0


## Validation and Utility Functions

## Validate configuration values and auto-correct invalid settings
func validate() -> void:
	# Clamp values to reasonable ranges
	cone_angle_degrees = clampf(cone_angle_degrees, 30.0, 180.0)
	cone_range_pixels = clampf(cone_range_pixels, 100.0, 1000.0)
	light_intensity = clampf(light_intensity, 0.1, 3.0)
	edge_softness = clampf(edge_softness, 0.0, 1.0)
	vignette_strength = clampf(vignette_strength, 0.0, 1.0)
	transition_speed = clampf(transition_speed, 1.0, 10.0)
	update_rate = clampf(update_rate, 1.0, 120.0)
	culling_distance = clampf(culling_distance, 100.0, 2000.0)


## Get human-readable description of this config
func get_description() -> String:
	var parts: Array[String] = []
	
	parts.append("FOV: %.0f°" % cone_angle_degrees)
	parts.append("Range: %.0fpx" % cone_range_pixels)
	parts.append("Intensity: %.1f" % light_intensity)
	
	if cast_shadows:
		parts.append("Shadows: ON")
	
	if shadow_flicker_enabled:
		parts.append("Flicker: ON")
	
	return ", ".join(parts)


## Create a copy of this configuration
func create_copy() -> DreadConeConfig:
	var new_config := DreadConeConfig.new()
	
	# Copy all properties
	new_config.cone_state = cone_state
	new_config.cone_angle_degrees = cone_angle_degrees
	new_config.cone_range_pixels = cone_range_pixels
	new_config.cone_origin_offset = cone_origin_offset
	new_config.cone_direction = cone_direction
	new_config.light_color = light_color
	new_config.light_intensity = light_intensity
	new_config.cone_range_scale = cone_range_scale
	new_config.cast_shadows = cast_shadows
	new_config.edge_softness = edge_softness
	new_config.vignette_strength = vignette_strength
	new_config.vignette_color = vignette_color
	new_config.shadow_flicker_enabled = shadow_flicker_enabled
	new_config.dread_clock_intensity_scale = dread_clock_intensity_scale
	new_config.transition_speed = transition_speed
	new_config.smooth_transitions = smooth_transitions
	new_config.update_rate = update_rate
	new_config.enable_distance_culling = enable_distance_culling
	new_config.culling_distance = culling_distance
	
	return new_config


## Convert to dictionary for serialization
func to_dict() -> Dictionary:
	return {
		"cone_state": cone_state,
		"cone_angle_degrees": cone_angle_degrees,
		"cone_range_pixels": cone_range_pixels,
		"cone_origin_offset": cone_origin_offset,
		"cone_direction": cone_direction,
		"light_color": light_color,
		"light_intensity": light_intensity,
		"cone_range_scale": cone_range_scale,
		"cast_shadows": cast_shadows,
		"edge_softness": edge_softness,
		"vignette_strength": vignette_strength,
		"vignette_color": vignette_color,
		"shadow_flicker_enabled": shadow_flicker_enabled,
		"dread_clock_intensity_scale": dread_clock_intensity_scale,
		"transition_speed": transition_speed,
		"smooth_transitions": smooth_transitions,
		"update_rate": update_rate,
		"enable_distance_culling": enable_distance_culling,
		"culling_distance": culling_distance
	}


## Load from dictionary for deserialization
func from_dict(data: Dictionary) -> void:
	if data.has("cone_state"):
		cone_state = data["cone_state"]
	if data.has("cone_angle_degrees"):
		cone_angle_degrees = data["cone_angle_degrees"]
	if data.has("cone_range_pixels"):
		cone_range_pixels = data["cone_range_pixels"]
	if data.has("cone_origin_offset"):
		cone_origin_offset = data["cone_origin_offset"]
	if data.has("cone_direction"):
		cone_direction = data["cone_direction"]
	if data.has("light_color"):
		light_color = data["light_color"]
	if data.has("light_intensity"):
		light_intensity = data["light_intensity"]
	if data.has("cone_range_scale"):
		cone_range_scale = data["cone_range_scale"]
	if data.has("cast_shadows"):
		cast_shadows = data["cast_shadows"]
	if data.has("edge_softness"):
		edge_softness = data["edge_softness"]
	if data.has("vignette_strength"):
		vignette_strength = data["vignette_strength"]
	if data.has("vignette_color"):
		vignette_color = data["vignette_color"]
	if data.has("shadow_flicker_enabled"):
		shadow_flicker_enabled = data["shadow_flicker_enabled"]
	if data.has("dread_clock_intensity_scale"):
		dread_clock_intensity_scale = data["dread_clock_intensity_scale"]
	if data.has("transition_speed"):
		transition_speed = data["transition_speed"]
	if data.has("smooth_transitions"):
		smooth_transitions = data["smooth_transitions"]
	if data.has("update_rate"):
		update_rate = data["update_rate"]
	if data.has("enable_distance_culling"):
		enable_distance_culling = data["enable_distance_culling"]
	if data.has("culling_distance"):
		culling_distance = data["culling_distance"]


func _init() -> void:
	# Auto-validate on creation
	validate()
