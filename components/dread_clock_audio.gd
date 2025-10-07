## DreadClock Audio Component
##
## Handles band-change stingers and loop reset audio effects.
## Attach to any scene that needs clock-based audio atmosphere.

extends Node

# Audio players
@onready var band_stinger: AudioStreamPlayer = $BandStinger
@onready var loop_reset_sound: AudioStreamPlayer = $LoopResetSound

# Audio settings
@export_group("Band Stinger Sounds")
@export var calm_stinger: AudioStream  # Subtle, low tone
@export var hunt_stinger: AudioStream  # Tense, ominous
@export var false_dawn_stinger: AudioStream  # Hopeful, light

@export_group("Loop Reset")
@export var loop_reset_audio: AudioStream  # Glitch/snap sound
@export var loop_reset_volume_db: float = 0.0


func _ready() -> void:
	if not DreadClock:
		push_error("DreadClock autoload not found")
		return

	# Connect to DreadClock signals
	DreadClock.band_changed.connect(_on_band_changed)
	DreadClock.loop_reset.connect(_on_loop_reset)


func _on_band_changed(new_band: int) -> void:
	if not band_stinger:
		return

	var stinger_sound: AudioStream = null

	match new_band:
		0:  # CALM
			stinger_sound = calm_stinger
		1:  # HUNT
			stinger_sound = hunt_stinger
		2:  # FALSE_DAWN
			stinger_sound = false_dawn_stinger

	if stinger_sound:
		band_stinger.stream = stinger_sound
		band_stinger.play()
		print("[DreadClock Audio] Band change stinger: ", DreadClock.get_band_name())


func _on_loop_reset() -> void:
	if not loop_reset_sound:
		return

	if loop_reset_audio:
		loop_reset_sound.stream = loop_reset_audio
		loop_reset_sound.volume_db = loop_reset_volume_db
		loop_reset_sound.play()
		print("[DreadClock Audio] Loop reset sound at 06:00")
