## DreadClock — 3-Band Night Cycle System
##
## Manages the looping night cycle (18:00 → 05:59 → 18:00) with three distinct time bands.
## Provides global scalars for other systems to query (danger, visibility, economy, scarcity).
##
## Bands:
##   - Calm (18:00–23:59): Lower threat, best visibility
##   - Hunt (00:00–02:59): Peak threat, darker
##   - False Dawn (03:00–05:59): Safest, slight horizon glow
##
## @tutorial: docs/specific_systems/system_DreadClock.md

extends Node

# Signals
signal band_changed(new_band: Band)
signal loop_reset()
signal time_changed(hours: int, minutes: int)

# Time band enum
enum Band {
	CALM,        # 18:00–23:59
	HUNT,        # 00:00–02:59
	FALSE_DAWN   # 03:00–05:59
}

# Configuration resource
@export var config: DreadClockConfig = preload("res://resources/dreadclock/default_clock_config.tres")

# Constants
const MINUTES_PER_HOUR: int = 60

# Time speed (configurable, can override config)
var time_scale: float = 1.0

# Current time state
var current_hours: int = 18
var current_minutes: int = 0
var current_band: Band = Band.CALM

# Global scalars (read-only for other systems)
var danger_mult: float = 0.8
var visibility_mult: float = 1.0
var economy_mult: float = 0.9
var scarcity_mult: float = 0.9

# Internal tracking
var _time_accumulator: float = 0.0


func _ready() -> void:
	# Load configuration values
	if config:
		current_hours = config.start_hour
		time_scale = config.time_scale
	else:
		push_warning("DreadClock: No config resource found, using defaults")

	_update_band()
	_update_scalars()


func _process(delta: float) -> void:
	if time_scale <= 0.0:
		return

	_time_accumulator += delta

	# Each game minute takes time_scale real seconds
	if _time_accumulator >= time_scale:
		_time_accumulator -= time_scale
		_advance_time()


## Advances time by one minute
func _advance_time() -> void:
	current_minutes += 1

	if current_minutes >= MINUTES_PER_HOUR:
		current_minutes = 0
		current_hours += 1

		# Handle day wrap (00:00 after 23:59)
		if current_hours >= 24:
			current_hours = 0

		# Check for loop reset
		if config and current_hours == config.end_hour:
			_reset_loop()
			return

	# Check for band change
	var previous_band: Band = current_band
	_update_band()

	if previous_band != current_band:
		_update_scalars()
		band_changed.emit(current_band)

	time_changed.emit(current_hours, current_minutes)


## Determines current band based on time
func _update_band() -> void:
	if not config:
		return

	if current_hours >= config.calm_start_hour or current_hours < config.hunt_start_hour:
		current_band = Band.CALM
	elif current_hours >= config.hunt_start_hour and current_hours < config.hunt_end_hour:
		current_band = Band.HUNT
	elif current_hours >= config.false_dawn_start_hour and current_hours < config.false_dawn_end_hour:
		current_band = Band.FALSE_DAWN


## Updates global scalars based on current band
func _update_scalars() -> void:
	if not config:
		return

	danger_mult = config.get_danger_mult(current_band)
	visibility_mult = config.get_visibility_mult(current_band)
	economy_mult = config.get_economy_mult(current_band)
	scarcity_mult = config.get_scarcity_mult(current_band)


## Resets time loop back to start hour
func _reset_loop() -> void:
	if config:
		current_hours = config.start_hour
	else:
		current_hours = 18
	current_minutes = 0
	_update_band()
	_update_scalars()
	loop_reset.emit()
	time_changed.emit(current_hours, current_minutes)


## Returns current time as formatted string (HH:MM)
func get_time_string() -> String:
	return "%02d:%02d" % [current_hours, current_minutes]


## Returns current band as string
func get_band_name() -> String:
	match current_band:
		Band.CALM:
			return "Calm"
		Band.HUNT:
			return "Hunt"
		Band.FALSE_DAWN:
			return "False Dawn"
		_:
			return "Unknown"


## Returns total minutes elapsed since start hour (for calculations)
func get_total_minutes() -> int:
	var minutes: int = current_minutes
	var start_hr: int = config.start_hour if config else 18

	# Handle hour wrapping
	if current_hours >= start_hr:
		minutes += (current_hours - start_hr) * MINUTES_PER_HOUR
	else:
		minutes += (24 - start_hr + current_hours) * MINUTES_PER_HOUR

	return minutes


## Get visibility multiplier for other systems
func get_visibility_mult() -> float:
	return visibility_mult


## Manually set time (for debugging/testing)
func set_time(hours: int, minutes: int) -> void:
	current_hours = clamp(hours, 0, 23)
	current_minutes = clamp(minutes, 0, 59)

	if config:
		# Reset if setting to invalid time outside loop
		if current_hours >= config.end_hour and current_hours < config.start_hour:
			current_hours = config.start_hour
			current_minutes = 0

	_update_band()
	_update_scalars()
	time_changed.emit(current_hours, current_minutes)
