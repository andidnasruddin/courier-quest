## DreadClock Visual Effects Component
##
## Handles ambient lighting, vignette, and visual transitions for time bands.
## Attach to any scene that needs clock-based visual atmosphere.

extends CanvasLayer

# Visual settings per band
@export_group("Calm Band Visuals")
@export var calm_ambient_color: Color = Color(0.3, 0.35, 0.4, 0.3)  # Bluish dark
@export_range(0.0, 1.0) var calm_vignette_intensity: float = 0.2

@export_group("Hunt Band Visuals")
@export var hunt_ambient_color: Color = Color(0.15, 0.15, 0.2, 0.5)  # Very dark
@export_range(0.0, 1.0) var hunt_vignette_intensity: float = 0.5

@export_group("False Dawn Band Visuals")
@export var false_dawn_ambient_color: Color = Color(0.5, 0.45, 0.35, 0.2)  # Warm glow
@export_range(0.0, 1.0) var false_dawn_vignette_intensity: float = 0.1

@export_group("Transition")
@export var transition_duration: float = 2.0  # Seconds to fade between bands

# UI elements
@onready var ambient_overlay: ColorRect = $AmbientOverlay
@onready var vignette: ColorRect = $Vignette

# Transition tracking
var _target_ambient_color: Color
var _target_vignette_intensity: float
var _transition_time: float = 0.0


func _ready() -> void:
	if not DreadClock:
		push_error("DreadClock autoload not found")
		return

	# Connect to band changes
	DreadClock.band_changed.connect(_on_band_changed)

	# Set initial visuals
	_update_target_visuals(DreadClock.current_band)
	_apply_visuals_immediately()


func _process(delta: float) -> void:
	if _transition_time < transition_duration:
		_transition_time += delta
		var t: float = clampf(_transition_time / transition_duration, 0.0, 1.0)

		# Smooth easing
		t = ease(t, -2.0)  # Ease-in-out

		# Lerp ambient color using delta-based interpolation
		if ambient_overlay:
			var lerp_weight: float = delta * 5.0  # Smooth transition speed
			ambient_overlay.color = ambient_overlay.color.lerp(_target_ambient_color, lerp_weight)

		# Lerp vignette
		if vignette:
			var lerp_weight: float = delta * 5.0
			var current_intensity: float = vignette.color.a
			var new_intensity: float = lerpf(current_intensity, _target_vignette_intensity, lerp_weight)
			vignette.color.a = new_intensity


func _update_target_visuals(band: int) -> void:
	match band:
		0:  # CALM
			_target_ambient_color = calm_ambient_color
			_target_vignette_intensity = calm_vignette_intensity
		1:  # HUNT
			_target_ambient_color = hunt_ambient_color
			_target_vignette_intensity = hunt_vignette_intensity
		2:  # FALSE_DAWN
			_target_ambient_color = false_dawn_ambient_color
			_target_vignette_intensity = false_dawn_vignette_intensity


func _apply_visuals_immediately() -> void:
	if ambient_overlay:
		ambient_overlay.color = _target_ambient_color

	if vignette:
		vignette.color.a = _target_vignette_intensity


func _on_band_changed(new_band: int) -> void:
	print("[DreadClock Visuals] Band changed to: ", new_band)
	_update_target_visuals(new_band)
	_transition_time = 0.0  # Start transition
	print("[DreadClock Visuals] Target ambient: ", _target_ambient_color)
	print("[DreadClock Visuals] Target vignette: ", _target_vignette_intensity)
