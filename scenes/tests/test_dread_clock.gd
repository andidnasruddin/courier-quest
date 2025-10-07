## Test scene for DreadClock system
##
## Tests time progression, band changes, loop resets, and UI display.
## Press Space to speed up time for testing (10x faster).

extends Node2D

@onready var debug_label: Label = $CanvasLayer/DebugInfo

var fast_mode: bool = false


func _ready() -> void:
	if not DreadClock:
		push_error("DreadClock autoload not found")
		return

	# Connect to DreadClock signals
	DreadClock.band_changed.connect(_on_band_changed)
	DreadClock.loop_reset.connect(_on_loop_reset)
	DreadClock.time_changed.connect(_on_time_changed)

	print("DreadClock Test Scene Started")
	print("Press SPACE to toggle fast mode (10x speed)")
	print("Press T to manually set time to 23:55 (near band change)")
	print("Press H to set time to 02:55 (near False Dawn)")
	print("Press D to set time to 05:55 (near loop reset)")


func _process(_delta: float) -> void:
	_update_debug_info()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # Space key
		fast_mode = not fast_mode
		DreadClock.time_scale = 0.1 if fast_mode else 1.0
		print("Fast mode: ", "ON (10x)" if fast_mode else "OFF (realtime)")

	# Testing hotkeys
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_T:
				DreadClock.set_time(23, 55)
				print("Time set to 23:55 (approaching Hunt)")
			KEY_H:
				DreadClock.set_time(2, 55)
				print("Time set to 02:55 (approaching False Dawn)")
			KEY_D:
				DreadClock.set_time(5, 55)
				print("Time set to 05:55 (approaching loop reset)")


func _update_debug_info() -> void:
	if not debug_label:
		return

	var info: String = ""
	info += "=== DreadClock Debug Info ===\n"
	info += "Time: %s\n" % DreadClock.get_time_string()
	info += "Band: %s\n" % DreadClock.get_band_name()
	info += "Total Minutes: %d\n" % DreadClock.get_total_minutes()
	info += "\n"
	info += "=== Global Scalars ===\n"
	info += "Danger: %.2f\n" % DreadClock.danger_mult
	info += "Visibility: %.2f\n" % DreadClock.visibility_mult
	info += "Economy: %.2f\n" % DreadClock.economy_mult
	info += "Scarcity: %.2f\n" % DreadClock.scarcity_mult
	info += "\n"
	info += "=== Controls ===\n"
	info += "SPACE: Fast mode %s\n" % ("ON" if fast_mode else "OFF")
	info += "T: Jump to 23:55\n"
	info += "H: Jump to 02:55\n"
	info += "D: Jump to 05:55\n"

	debug_label.text = info


func _on_band_changed(new_band: DreadClock.Band) -> void:
	var band_name: String = DreadClock.get_band_name()
	print("[BAND CHANGE] New band: ", band_name, " at ", DreadClock.get_time_string())


func _on_loop_reset() -> void:
	print("[LOOP RESET] Time snapped back to 18:00")


func _on_time_changed(hours: int, minutes: int) -> void:
	# Only log every 10 minutes to avoid spam
	if minutes % 10 == 0:
		print("[TIME] %02d:%02d - Band: %s" % [hours, minutes, DreadClock.get_band_name()])
