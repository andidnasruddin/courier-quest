## Ambient Darkness Component
##
## Creates ambient darkness overlay that responds to DreadClock visibility_mult.
## Provides base darkness that cone lights can illuminate against.

class_name AmbientDarkness extends CanvasModulate

## Base darkness color (what darkness looks like at 0% visibility)
@export var min_darkness_color: Color = Color(0.1, 0.1, 0.15, 1.0)

## Maximum brightness color (what ambient looks like at 100% visibility)
@export var max_brightness_color: Color = Color(0.4, 0.4, 0.45, 1.0)

## Smooth transition speed
@export var transition_speed: float = 2.0

var _target_color: Color = Color.BLACK
var _dread_clock: Node = null


func _ready() -> void:
	# Get DreadClock reference
	_dread_clock = get_node_or_null("/root/DreadClock")
	
	if _dread_clock:
		# Connect to band changes
		if _dread_clock.has_signal("band_changed"):
			_dread_clock.band_changed.connect(_on_band_changed)
		
		# Set initial darkness based on current band
		_update_darkness_from_clock()
	else:
		# Fallback if no DreadClock
		color = min_darkness_color
		_target_color = min_darkness_color


func _process(delta: float) -> void:
	# Smooth transition to target color
	color = color.lerp(_target_color, transition_speed * delta)


func _update_darkness_from_clock() -> void:
	if not _dread_clock:
		return
	
	# Get visibility multiplier from DreadClock
	var visibility_mult: float = 1.0
	if _dread_clock.has_method("get_visibility_mult"):
		visibility_mult = _dread_clock.get_visibility_mult()
	
	# Interpolate between dark and bright based on visibility
	# visibility_mult ranges: 0.9 (Hunt) → 1.0 (Calm) → 1.15 (False Dawn)
	# Normalize to 0-1 range: (0.9 = darkest, 1.15 = brightest)
	var normalized: float = inverse_lerp(0.85, 1.2, visibility_mult)
	normalized = clampf(normalized, 0.0, 1.0)
	
	_target_color = min_darkness_color.lerp(max_brightness_color, normalized)


func _on_band_changed(_band_name: String) -> void:
	_update_darkness_from_clock()


## Manual darkness override (for cutscenes, etc.)
func set_darkness_level(level: float) -> void:
	var normalized: float = clampf(level, 0.0, 1.0)
	_target_color = min_darkness_color.lerp(max_brightness_color, normalized)
