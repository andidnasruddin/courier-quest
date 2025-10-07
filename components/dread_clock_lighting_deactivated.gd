## DreadClock Lighting System
##
## Uses CanvasModulate to create actual darkness that requires lights to see.
## Replaces the overlay-based visual system with proper 2D lighting.

extends Node

# Lighting settings per band (RGB values for CanvasModulate)
@export_group("Calm Band Lighting")
@export var calm_ambient_light: Color = Color(0.4, 0.45, 0.5)  # Dim bluish

@export_group("Hunt Band Lighting")
@export var hunt_ambient_light: Color = Color(0.2, 0.2, 0.25)  # Very dark

@export_group("False Dawn Band Lighting")
@export var false_dawn_ambient_light: Color = Color(0.6, 0.55, 0.45)  # Warmer, slightly brighter

@export_group("Transition")
@export var transition_duration: float = 2.0

# Canvas modulate node (controls global lighting)
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

# Transition tracking
var _target_light_color: Color
var _transition_time: float = 0.0
var _default_light_texture: Texture2D
@export var auto_assign_default_light_texture: bool = true


func _ready() -> void:
	if not DreadClock:
		push_error("DreadClock autoload not found")
		return

	# Connect to band changes
	DreadClock.band_changed.connect(_on_band_changed)

	# Set initial lighting
	_update_target_lighting(DreadClock.current_band)
	_apply_lighting_immediately()

	# Ensure any PointLight2D in the active scene has a usable texture
	if auto_assign_default_light_texture:
		_ensure_point_light_textures()


func _process(delta: float) -> void:
	if _transition_time < transition_duration:
		_transition_time += delta
		var lerp_weight: float = delta * 3.0

		if canvas_modulate:
			canvas_modulate.color = canvas_modulate.color.lerp(_target_light_color, lerp_weight)


func _update_target_lighting(band: int) -> void:
	match band:
		0:  # CALM
			_target_light_color = calm_ambient_light
		1:  # HUNT
			_target_light_color = hunt_ambient_light
		2:  # FALSE_DAWN
			_target_light_color = false_dawn_ambient_light


func _apply_lighting_immediately() -> void:
	if canvas_modulate:
		canvas_modulate.color = _target_light_color


func _on_band_changed(new_band: int) -> void:
	print("[DreadClock Lighting] Band changed to: ", new_band)
	_update_target_lighting(new_band)
	_transition_time = 0.0
	print("[DreadClock Lighting] Target light: ", _target_light_color)


## Ensures PointLight2D nodes have a texture (Godot 4 lights use a texture to define shape)
func _ensure_point_light_textures() -> void:
	var scene_root: Node = get_tree().get_current_scene()
	if scene_root == null:
		return

	if _default_light_texture == null:
		_default_light_texture = _create_radial_light_texture(256)

	if _default_light_texture == null:
		return

	var stack: Array[Node] = [scene_root]
	while stack.size() > 0:
		var n: Node = stack.pop_back() as Node
		if n is PointLight2D:
			var l: PointLight2D = n as PointLight2D
			if l.texture == null:
				l.texture = _default_light_texture
				# If author set a texture_scale already, keep it; otherwise use a sane default
				if l.texture_scale <= 0.0:
					l.texture_scale = 3.0
				# Ensure wide Z range so world items receive light
				if l.range_z_min > -1024 or l.range_z_max < 1024:
					l.range_z_min = -1024
					l.range_z_max = 1024
		for c in n.get_children():
			if c is Node:
				stack.append(c)


## Creates a simple white radial falloff texture usable for 2D point lights
func _create_radial_light_texture(size: int = 256) -> Texture2D:
	size = max(8, size)
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2((size - 1) * 0.5, (size - 1) * 0.5)
	var max_r: float = center.x  # since image is square

	for y: int in range(size):
		for x: int in range(size):
			var p: Vector2 = Vector2(x as float, y as float)
			var d: float = p.distance_to(center) / max_r  # 0 at center, 1 at edge
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			# Smooth falloff (quadratic)
			a = a * a
			img.set_pixel(x, y, Color(1, 1, 1, a))

	var tex: ImageTexture = ImageTexture.create_from_image(img)
	return tex
