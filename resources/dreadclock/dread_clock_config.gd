## DreadClock Configuration Resource
##
## Defines all time band settings, scalars, and timing parameters for the DreadClock system.
## Create .tres instances to customize clock behavior without code changes.

class_name DreadClockConfig extends Resource

# Time loop boundaries
@export_group("Time Loop")
@export var start_hour: int = 18  # Loop starts at this hour
@export var end_hour: int = 6  # Loop resets when reaching this hour (exclusive)
@export var time_scale: float = 1.0  # Real seconds per game minute (1.0 = realtime, 0.1 = 10x faster)

# Band time ranges (hour only, inclusive start, exclusive end)
@export_group("Band Timing")
@export var calm_start_hour: int = 18
@export var calm_end_hour: int = 24  # Wraps to 0

@export var hunt_start_hour: int = 0
@export var hunt_end_hour: int = 3

@export var false_dawn_start_hour: int = 3
@export var false_dawn_end_hour: int = 6

# Band scalars - Calm (18:00–23:59)
@export_group("Calm Band Scalars")
@export_range(0.0, 3.0, 0.1) var calm_danger_mult: float = 0.8
@export_range(0.0, 3.0, 0.1) var calm_visibility_mult: float = 1.0
@export_range(0.0, 3.0, 0.1) var calm_economy_mult: float = 0.9
@export_range(0.0, 3.0, 0.1) var calm_scarcity_mult: float = 0.9

# Band scalars - Hunt (00:00–02:59)
@export_group("Hunt Band Scalars")
@export_range(0.0, 3.0, 0.1) var hunt_danger_mult: float = 1.5
@export_range(0.0, 3.0, 0.1) var hunt_visibility_mult: float = 0.9
@export_range(0.0, 3.0, 0.1) var hunt_economy_mult: float = 1.2
@export_range(0.0, 3.0, 0.1) var hunt_scarcity_mult: float = 1.1

# Band scalars - False Dawn (03:00–05:59)
@export_group("False Dawn Band Scalars")
@export_range(0.0, 3.0, 0.1) var false_dawn_danger_mult: float = 0.6
@export_range(0.0, 3.0, 0.1) var false_dawn_visibility_mult: float = 1.15
@export_range(0.0, 3.0, 0.1) var false_dawn_economy_mult: float = 1.0
@export_range(0.0, 3.0, 0.1) var false_dawn_scarcity_mult: float = 1.3


## Get danger multiplier for a specific band
func get_danger_mult(band: int) -> float:
	match band:
		0:  # CALM
			return calm_danger_mult
		1:  # HUNT
			return hunt_danger_mult
		2:  # FALSE_DAWN
			return false_dawn_danger_mult
		_:
			return 1.0


## Get visibility multiplier for a specific band
func get_visibility_mult(band: int) -> float:
	match band:
		0:  # CALM
			return calm_visibility_mult
		1:  # HUNT
			return hunt_visibility_mult
		2:  # FALSE_DAWN
			return false_dawn_visibility_mult
		_:
			return 1.0


## Get economy multiplier for a specific band
func get_economy_mult(band: int) -> float:
	match band:
		0:  # CALM
			return calm_economy_mult
		1:  # HUNT
			return hunt_economy_mult
		2:  # FALSE_DAWN
			return false_dawn_economy_mult
		_:
			return 1.0


## Get scarcity multiplier for a specific band
func get_scarcity_mult(band: int) -> float:
	match band:
		0:  # CALM
			return calm_scarcity_mult
		1:  # HUNT
			return hunt_scarcity_mult
		2:  # FALSE_DAWN
			return false_dawn_scarcity_mult
		_:
			return 1.0
