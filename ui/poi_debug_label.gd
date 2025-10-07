extends Label
class_name POIDebugLabel

@export var poi_placer_path: NodePath
@export var player_path: NodePath
@export var use_camera_center: bool = false
@export var use_auto_camera_when_in_vehicle: bool = true
@export var use_radial_compass: bool = true
@export_range(15, 180, 1) var compass_sector_deg: int = 60

const PX_PER_KM: float = 10000.0

var _poi: POIPlacer
var _player: Player
var _last_origin: Vector2 = Vector2.ZERO
var _speed_px_s: float = 0.0
var _last_update_time: float = 0.0

func _ready() -> void:
	_poi = get_node_or_null(poi_placer_path) as POIPlacer
	_player = get_node_or_null(player_path) as Player
	text = "Nearest POI: (scanning...)"
	_last_origin = _get_origin()
	_last_update_time = Time.get_ticks_msec() / 1000.0
	set_process(true)

func _process(_delta: float) -> void:
	if not _poi:
		text = "Nearest POI: (no POIPlacer)"
		return

	# Determine reference origin and update speed estimate
	var origin: Vector2 = _get_origin()
	_update_speed(origin)

	# Choose target POI (nearest or within forward sector if radial compass enabled)
	var best_node: Node2D = _select_target_poi(origin)
	if not best_node:
		text = "Nearest POI: (none loaded)"
		return

	var dist_px: float = origin.distance_to(best_node.global_position)
	var dist_km: float = dist_px / PX_PER_KM
	text = _build_summary_text(origin, best_node)

	# Proximity color (green <1km, yellow <3km, red otherwise)
	var col: Color = Color(1, 0.3, 0.3)
	if dist_km < 1.0:
		col = Color(0.2, 1.0, 0.2)
	elif dist_km < 3.0:
		col = Color(1.0, 0.85, 0.2)
	add_theme_color_override("font_color", col)


func _get_origin() -> Vector2:
	var use_cam: bool = use_camera_center
	# Auto switch to camera when the player is in a vehicle
	if use_auto_camera_when_in_vehicle and _player:
		if _player.is_in_vehicle:
			use_cam = true
	if use_cam:
		var cam: Camera2D = get_viewport().get_camera_2d()
		if cam:
			return cam.get_screen_center_position()
		return Vector2.ZERO
	if _player:
		return _player.global_position
	return Vector2.ZERO



func _update_speed(current_origin: Vector2) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	var dt: float = max(0.0001, now - _last_update_time)
	var inst_speed: float = _last_origin.distance_to(current_origin) / dt
	# Smooth speed (EMA)
	_speed_px_s = lerp(inst_speed, _speed_px_s, 0.85)
	_last_origin = current_origin
	_last_update_time = now


func _select_target_poi(origin: Vector2) -> Node2D:
	var nodes: Array[Node2D] = _poi.get_loaded_pois()
	var best: Node2D = null
	var best_d: float = INF
	if use_radial_compass:
		# Forward vector from player/camera facing
		var forward: Vector2 = Vector2.RIGHT
		if _player:
			# If driving, try to use vehicle rotation for a stable forward
			var use_rot: float = _player.rotation
			if _player.is_in_vehicle and _player.current_vehicle is Node2D:
				use_rot = (_player.current_vehicle as Node2D).rotation
			forward = Vector2.RIGHT.rotated(use_rot)
		var half_angle: float = deg_to_rad(float(compass_sector_deg) * 0.5)
		for n in nodes:
			if not (n and is_instance_valid(n)):
				continue
			var to: Vector2 = (n.global_position - origin)
			var d: float = to.length()
			if d <= 0.01:
				continue
			var ang: float = abs(_angle_diff(forward.angle(), to.angle()))
			if ang <= half_angle and d < best_d:
				best = n
				best_d = d
		# Fallback to nearest if none in sector
		if best:
			return best
	# Nearest overall
	for n in nodes:
		if n and is_instance_valid(n):
			var d: float = origin.distance_to(n.global_position)
			if d < best_d:
				best = n
				best_d = d
	return best


func _build_summary_text(origin: Vector2, highlight: Node2D) -> String:
	var nodes: Array[Node2D] = _poi.get_loaded_pois()
	var best_by_type: Dictionary = {}
	for node in nodes:
		if not (node and is_instance_valid(node)):
			continue
		var category: String = _classify_poi(node)
		var dist: float = origin.distance_to(node.global_position)
		if not best_by_type.has(category):
			best_by_type[category] = {"node": node, "distance": dist}
		else:
			var entry: Dictionary = best_by_type[category]
			if dist < float(entry["distance"]):
				entry["node"] = node
				entry["distance"] = dist

	var ordered_types: Array[String] = ["Settlement", "Gas Station"]
	var lines: Array[String] = []
	for category in ordered_types:
		if best_by_type.has(category):
			lines.append(_format_summary_line(category, best_by_type[category], origin, highlight))
	for category in best_by_type.keys():
		if ordered_types.has(category):
			continue
		lines.append(_format_summary_line(category, best_by_type[category], origin, highlight))
	if lines.is_empty():
		return "Nearest POI: (none loaded)"
	return "\n".join(lines)


func _format_summary_line(category: String, data: Dictionary, origin: Vector2, highlight: Node2D) -> String:
	var node: Node2D = data["node"]
	var dist_px: float = data["distance"]
	var dist_km: float = dist_px / PX_PER_KM
	var direction: String = _cardinal((node.global_position - origin).normalized())
	var eta: String = _eta_text(dist_px)
	var prefix: String = "*" if highlight and node == highlight else " "
	return "%s%s: %s  %.2f km  %s  %s" % [prefix, category, node.name, dist_km, direction, eta]


func _classify_poi(node: Node2D) -> String:
	var path: String = ""
	if node.scene_file_path != "":
		path = node.scene_file_path.to_lower()
	var name_lower: String = node.name.to_lower()
	if path.find("settlement") != -1 or name_lower.find("settlement") != -1:
		return "Settlement"
	if path.find("gas_station") != -1 or name_lower.find("gas station") != -1 or name_lower.find("gas") != -1:
		return "Gas Station"
	return "POI"


func _angle_diff(a: float, b: float) -> float:
	# Minimal signed angle difference between a and b, in radians
	var diff: float = fposmod((b - a) + PI, TAU) - PI
	return diff


func _eta_text(dist_px: float) -> String:
	# Estimate based on smoothed speed
	if _speed_px_s <= 1.0:
		return "ETA: --"
	var seconds: float = dist_px / _speed_px_s
	if seconds < 60.0:
		return "ETA: %ds" % int(round(seconds))
	var minutes: int = int(floor(seconds / 60.0))
	var secs: int = int(round(seconds - minutes * 60))
	return "ETA: %dm%02ds" % [minutes, secs]


func _cardinal(v: Vector2) -> String:
	if v.length() < 0.001:
		return "here"
	var a := atan2(v.y, v.x)
	var deg := rad_to_deg(a)
	# Map to 8-way
	var idx := int(round((deg + 180.0) / 45.0)) % 8
	# Corrected mapping so 90° -> "S" and -90° -> "N"
	var names := ["W", "NW", "N", "NE", "E", "SE", "S", "SW"]
	return names[idx]
