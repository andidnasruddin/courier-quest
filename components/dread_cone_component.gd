## Dread Cone Component
##
## Darkwood-style visibility cone that masks areas outside player's view.
## Tracks player state (walk, sprint, aim) and adjusts FOV accordingly.
## Integrates with camera for directional lead effect.

class_name DreadConeComponent extends CanvasLayer

## Player states that affect cone behavior
enum ConeState {
	WALK,      # 100° FOV, no camera lead
	SPRINT,    # 70° FOV, 20% camera lead
	AIM        # 58° FOV, 10% camera lead
}

@export_group("Cone States")
@export var walk_data: DreadConeData
@export var sprint_data: DreadConeData
@export var aim_data: DreadConeData

@export_group("Settings")
@export var target_node: Node2D  # The entity this cone follows (player/vehicle)
@export var cone_follows_cursor: bool = true  # If true, cone direction = cursor; if false, uses target rotation

var _current_state: ConeState = ConeState.WALK
var _active_data: DreadConeData
var _cone_overlay: ColorRect
var _cone_material: ShaderMaterial

# Lerp tracking for smooth transitions
var _current_fov: float = 100.0
var _current_vignette: float = 0.3
var _current_luminance: float = 0.25
var _transition_progress: float = 1.0


func _ready() -> void:
	# Set layer to render on top of everything
	layer = 100

	# Auto-detect target if not assigned (use parent)
	if not target_node:
		target_node = get_parent() as Node2D
		if not target_node:
			push_warning("DreadConeComponent: No target_node assigned and parent is not Node2D")

	# Create default data if not assigned
	if not walk_data:
		walk_data = _create_default_walk_data()
	if not sprint_data:
		sprint_data = _create_default_sprint_data()
	if not aim_data:
		aim_data = _create_default_aim_data()

	_active_data = walk_data

	# Create overlay with shader
	_create_cone_overlay()


func _create_cone_overlay() -> void:
	# Create fullscreen overlay
	_cone_overlay = ColorRect.new()
	_cone_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_cone_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cone_overlay.color = Color.WHITE  # Shader needs a base color to work with
	add_child(_cone_overlay)

	# Load shader
	var shader := load("res://shaders/cone_visibility_mask.gdshader") as Shader
	_cone_material = ShaderMaterial.new()
	_cone_material.shader = shader

	_cone_overlay.material = _cone_material

	# Initialize shader parameters
	_update_shader_params()


func _process(delta: float) -> void:
	if not target_node or not _cone_material:
		return

	# Update cone direction
	_update_cone_direction()

	# Smooth transition between states
	if _transition_progress < 1.0:
		_transition_progress = min(_transition_progress + delta / _active_data.transition_time, 1.0)
		_update_shader_params()


func _update_cone_direction() -> void:
	# Get target position in screen space
	var viewport := get_viewport()
	if not viewport:
		return

	var camera := viewport.get_camera_2d()
	if not camera:
		return

	# Get screen center (cone origin)
	var screen_size := viewport.get_visible_rect().size
	var target_screen_pos := camera.get_screen_center_position()

	# Convert to normalized screen space (0-1)
	var cone_origin := Vector2(0.5, 0.5)  # Always centered for now

	# Determine cone direction
	var cone_dir := Vector2.ZERO
	if cone_follows_cursor:
		# Direction toward mouse cursor
		var mouse_pos := viewport.get_mouse_position()
		var center_pos := screen_size / 2.0
		cone_dir = (mouse_pos - center_pos).normalized()
	else:
		# Direction based on target rotation
		cone_dir = Vector2.from_angle(target_node.rotation - PI / 2.0)  # -90° because "up" is -Y

	# Update shader uniforms
	_cone_material.set_shader_parameter("cone_origin", cone_origin)
	_cone_material.set_shader_parameter("cone_direction", cone_dir)


func _update_shader_params() -> void:
	if not _cone_material or not _active_data:
		return

	# Lerp values during transition
	var target_fov := _active_data.fov_degrees
	var target_vignette := _active_data.vignette_strength
	var target_luminance := _active_data.outside_cone_luminance

	_current_fov = lerp(_current_fov, target_fov, _transition_progress)
	_current_vignette = lerp(_current_vignette, target_vignette, _transition_progress)
	_current_luminance = lerp(_current_luminance, target_luminance, _transition_progress)

	# Apply to shader
	_cone_material.set_shader_parameter("fov_degrees", _current_fov)
	_cone_material.set_shader_parameter("vignette_strength", _current_vignette)
	_cone_material.set_shader_parameter("outside_luminance", _current_luminance)
	_cone_material.set_shader_parameter("edge_softness", _active_data.edge_softness)


## Change cone state (walk, sprint, aim)
func set_state(new_state: ConeState) -> void:
	if _current_state == new_state:
		return

	_current_state = new_state

	# Select appropriate data
	match new_state:
		ConeState.WALK:
			_active_data = walk_data
		ConeState.SPRINT:
			_active_data = sprint_data
		ConeState.AIM:
			_active_data = aim_data

	# Start transition
	_transition_progress = 0.0


## Default data creators (fallback if no .tres assigned)
func _create_default_walk_data() -> DreadConeData:
	var data := DreadConeData.new()
	data.fov_degrees = 100.0
	data.vignette_strength = 0.2
	data.outside_cone_luminance = 0.25
	data.transition_time = 0.12
	data.camera_lead_percent = 0.0
	data.zoom_offset = 0.0
	data.edge_softness = 0.15
	return data


func _create_default_sprint_data() -> DreadConeData:
	var data := DreadConeData.new()
	data.fov_degrees = 70.0
	data.vignette_strength = 0.4
	data.outside_cone_luminance = 0.25
	data.transition_time = 0.12
	data.camera_lead_percent = 0.2
	data.zoom_offset = 0.0
	data.edge_softness = 0.15
	return data


func _create_default_aim_data() -> DreadConeData:
	var data := DreadConeData.new()
	data.fov_degrees = 58.0
	data.vignette_strength = 0.5
	data.outside_cone_luminance = 0.25
	data.transition_time = 0.12
	data.camera_lead_percent = 0.1
	data.zoom_offset = 0.05
	data.edge_softness = 0.1
	return data
