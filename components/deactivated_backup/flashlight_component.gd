## Flashlight Component
##
## Adds a configurable flashlight (cone or point light) to any entity.
## Uses FlashlightData resource for all settings.
## The light shape is defined by the texture assigned in FlashlightData.

class_name FlashlightComponent extends Node2D

@export var flashlight_data: FlashlightData
@export var offset: Vector2 = Vector2.ZERO  # Offset from parent position
@export var enabled: bool = true

var _light: PointLight2D


func _ready() -> void:
	if not flashlight_data:
		push_warning("FlashlightComponent: No flashlight_data assigned")
		return

	_create_light()
	_apply_settings()


func _create_light() -> void:
	# Remove existing light if any
	if _light:
		_light.queue_free()

	_light = PointLight2D.new()
	_light.position = offset
	add_child(_light)


func _apply_settings() -> void:
	if not _light or not flashlight_data:
		return

	# Apply texture from FlashlightData (this defines the shape!)
	if flashlight_data.light_texture:
		# Use provided texture
		_light.texture = flashlight_data.light_texture
	elif flashlight_data.use_procedural_cone:
		# Generate procedural cone texture
		_light.texture = flashlight_data.create_cone_texture()
	else:
		# No texture = circular light (Godot default)
		_light.texture = null

	_light.texture_scale = flashlight_data.texture_scale

	# Apply rotation offset (convert degrees to radians and apply to light)
	_light.rotation_degrees = flashlight_data.texture_rotation

	# Common properties
	_light.enabled = enabled
	_light.color = flashlight_data.light_color
	_light.energy = flashlight_data.energy
	_light.blend_mode = flashlight_data.blend_mode
	_light.shadow_enabled = flashlight_data.enable_shadows
	_light.range_z_min = flashlight_data.range_z_min
	_light.range_z_max = flashlight_data.range_z_max


## Toggle flashlight on/off
func toggle() -> void:
	enabled = not enabled
	if _light:
		_light.enabled = enabled


## Set flashlight state
func set_enabled(state: bool) -> void:
	enabled = state
	if _light:
		_light.enabled = enabled


## Update flashlight data and reapply settings
func set_flashlight_data(data: FlashlightData) -> void:
	flashlight_data = data
	_create_light()
	_apply_settings()
