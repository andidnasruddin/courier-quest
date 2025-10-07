## Dread Cone Data Resource
##
## Defines visibility cone parameters for different player/vehicle states.
## Used by DreadConeComponent to control FOV, vignette, and camera behavior.
##
## Based on Darkwood-style visibility system where only the cone area is visible.

class_name DreadConeData extends Resource

@export_group("Cone Properties")
@export_range(30.0, 180.0) var fov_degrees: float = 100.0  # Field of view width
@export_range(0.0, 1.0) var vignette_strength: float = 0.3  # Edge darkening intensity
@export_range(0.0, 1.0) var outside_cone_luminance: float = 0.25  # Brightness outside cone (never pure black)
@export_range(0.0, 0.5) var transition_time: float = 0.12  # Time to lerp between states

@export_group("Camera Behavior")
@export_range(0.0, 0.3) var camera_lead_percent: float = 0.0  # Camera offset toward cursor/facing (0-30% of viewport)
@export_range(0.0, 0.1) var zoom_offset: float = 0.0  # Slight zoom for aim states (0-5%)

@export_group("Visual Effects")
@export var edge_softness: float = 0.15  # Softness of cone edge (0 = hard, 1 = very soft)
@export var enable_edge_glow: bool = false  # Subtle glow at cone edges (for horror effect)
