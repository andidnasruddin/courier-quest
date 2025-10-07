## Dread Cone Vignette Component
##
## Creates tunnel vision vignette effect that intensifies as cone narrows.
## Provides visual feedback for reduced awareness when sprinting/aiming.

class_name DreadConeVignette extends ColorRect

## Vignette intensity at widest cone (Walk: 100°)
@export_range(0.0, 1.0) var min_intensity: float = 0.2

## Vignette intensity at narrowest cone (Aim: 58°)
@export_range(0.0, 1.0) var max_intensity: float = 0.7

## Smooth transition speed
@export var transition_speed: float = 5.0

## Vignette color (dark edges)
@export var vignette_color: Color = Color(0.0, 0.0, 0.0, 1.0)

var _current_intensity: float = 0.2
var _target_intensity: float = 0.2
var _vignette_material: ShaderMaterial = null


func _ready() -> void:
	# Setup full-screen overlay
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Create vignette shader
	_setup_vignette_shader()


func _setup_vignette_shader() -> void:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.5;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv);
	float vignette = smoothstep(0.3, 0.8, dist * intensity * 2.0);
	COLOR = mix(vec4(0.0), vignette_color, vignette);
}
"""
	
	_vignette_material = ShaderMaterial.new()
	_vignette_material.shader = shader
	_vignette_material.set_shader_parameter("intensity", _current_intensity)
	_vignette_material.set_shader_parameter("vignette_color", vignette_color)
	
	material = _vignette_material


func _process(delta: float) -> void:
	# Smooth transition
	_current_intensity = lerp(_current_intensity, _target_intensity, transition_speed * delta)
	
	if _vignette_material:
		_vignette_material.set_shader_parameter("intensity", _current_intensity)


## Update vignette based on cone angle
## Wider cone = less vignette, Narrower cone = more vignette
func set_cone_angle(angle_degrees: float) -> void:
	# Map cone angles to intensity
	# 100° (walk) → min_intensity (0.2)
	# 70° (sprint) → medium intensity (~0.45)
	# 58° (aim) → max_intensity (0.7)
	
	var normalized: float = inverse_lerp(100.0, 58.0, angle_degrees)
	normalized = clampf(normalized, 0.0, 1.0)
	
	_target_intensity = lerp(min_intensity, max_intensity, normalized)
