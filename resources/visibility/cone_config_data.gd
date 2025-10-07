## Cone Configuration Resource
##
## Defines cone angle settings for different player states (walk, sprint, aim)
## and vehicle beam modes (low, high).

class_name ConeConfigData extends Resource

## Player on-foot cone angles
@export_group("Player Cone Angles")
@export_range(30.0, 120.0) var walk_angle: float = 100.0
@export_range(30.0, 120.0) var sprint_angle: float = 70.0
@export_range(30.0, 120.0) var aim_angle: float = 58.0

## Vehicle cone angles
@export_group("Vehicle Cone Angles")
@export_range(30.0, 120.0) var low_beam_angle: float = 90.0
@export_range(30.0, 120.0) var high_beam_angle: float = 120.0

## Cone appearance
@export_group("Cone Appearance")
@export_range(200.0, 800.0) var player_cone_length: float = 400.0
@export_range(200.0, 800.0) var vehicle_cone_length: float = 500.0
@export var cone_color: Color = Color(1.0, 0.95, 0.85, 1.0)
@export_range(0.5, 3.0) var light_energy: float = 1.5

## Transition settings
@export_group("Transitions")
@export_range(0.05, 0.5) var transition_duration: float = 0.12
@export_range(1.0, 10.0) var transition_speed: float = 5.0

## Vignette settings
@export_group("Vignette")
@export_range(0.0, 1.0) var vignette_min_intensity: float = 0.2
@export_range(0.0, 1.0) var vignette_max_intensity: float = 0.7
@export var vignette_color: Color = Color(0.0, 0.0, 0.0, 1.0)

## Camera lead settings
@export_group("Camera Lead")
@export var camera_lead_enabled: bool = true
@export_range(0.0, 0.5) var sprint_lead_percent: float = 0.20
@export_range(1.0, 10.0) var camera_lead_speed: float = 3.0
