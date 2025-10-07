## Visibility Controller (Simple Refactor)
##
## Controls player visibility cone by adjusting flashlight cone angle.
## No complex shaders - just adjusts the light itself.
## Integrates with movement state (walk/sprint/aim).

class_name VisibilityController extends Node

enum VisibilityState {
	WALK,
	SPRINT,
	AIM
}

@export var flashlight: SimpleFlashlight
@export var camera: Camera2D

# FOV angles per state
@export var walk_fov: float = 100.0
@export var sprint_fov: float = 70.0
@export var aim_fov: float = 58.0

# Transition settings
@export var transition_speed: float = 8.0  # Higher = faster transitions

var _current_state: VisibilityState = VisibilityState.WALK
var _target_fov: float = 100.0
var _current_fov: float = 100.0


func _ready() -> void:
	_target_fov = walk_fov
	_current_fov = walk_fov


func _process(delta: float) -> void:
	# Smooth lerp to target FOV
	if abs(_current_fov - _target_fov) > 0.1:
		_current_fov = lerpf(_current_fov, _target_fov, transition_speed * delta)

		if flashlight:
			flashlight.set_cone_angle(_current_fov)


## Set visibility state
func set_state(new_state: VisibilityState) -> void:
	if _current_state == new_state:
		return

	_current_state = new_state

	match new_state:
		VisibilityState.WALK:
			_target_fov = walk_fov
		VisibilityState.SPRINT:
			_target_fov = sprint_fov
		VisibilityState.AIM:
			_target_fov = aim_fov
