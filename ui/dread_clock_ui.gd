## DreadClock UI Widget
##
## Displays current time (HH:MM) and time band badge.
## Minimal design for top-right corner of screen.

class_name DreadClockUI extends Control

@onready var time_label: Label = $MarginContainer/VBoxContainer/TimeLabel
@onready var band_label: Label = $MarginContainer/VBoxContainer/BandLabel

# Band colors
const CALM_COLOR: Color = Color(0.6, 0.7, 0.8)  # Bluish gray
const HUNT_COLOR: Color = Color(0.9, 0.3, 0.2)  # Red
const FALSE_DAWN_COLOR: Color = Color(0.9, 0.8, 0.5)  # Golden


func _ready() -> void:
	if not DreadClock:
		push_error("DreadClock autoload not found")
		return

	# Connect to DreadClock signals
	DreadClock.time_changed.connect(_on_time_changed)
	DreadClock.band_changed.connect(_on_band_changed)

	# Initialize display
	_update_time_display()
	_update_band_display()


func _update_time_display() -> void:
	if time_label:
		time_label.text = DreadClock.get_time_string()


func _update_band_display() -> void:
	if not band_label:
		return

	band_label.text = DreadClock.get_band_name()

	# Update color based on band
	match DreadClock.current_band:
		DreadClock.Band.CALM:
			band_label.add_theme_color_override("font_color", CALM_COLOR)
		DreadClock.Band.HUNT:
			band_label.add_theme_color_override("font_color", HUNT_COLOR)
		DreadClock.Band.FALSE_DAWN:
			band_label.add_theme_color_override("font_color", FALSE_DAWN_COLOR)


func _on_time_changed(_hours: int, _minutes: int) -> void:
	_update_time_display()


func _on_band_changed(_new_band: DreadClock.Band) -> void:
	_update_band_display()
