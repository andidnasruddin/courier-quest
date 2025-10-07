extends CanvasLayer
class_name ContractHUD

@onready var label: Label = $Label

const PX_PER_KM: float = 10000.0

var _player: Node2D
var _last_origin: Vector2 = Vector2.ZERO
var _speed_px_s: float = 0.0
var _last_update_time: float = 0.0

func setup(player: Node2D) -> void:
	_player = player
	_last_origin = player.global_position if player else Vector2.ZERO
	_last_update_time = Time.get_ticks_msec() / 1000.0
	set_process(true)

func _ready() -> void:
	set_process(true)

func _process(_delta: float) -> void:
	_update_text()

func _update_text() -> void:
	# Access ContractManager autoload safely
	var cm: Node = get_node_or_null("/root/ContractManager")
	if not cm:
		label.text = ""
		return

	var offer: Dictionary = cm.get_active_contract()
	if offer.is_empty():
		label.text = ""
		return

	var dest: Node2D = cm.get_active_destination()
	if not dest:
		label.text = "Contract: locating destination..."
		return

	if not _player:
		label.text = "Contract: no player reference"
		return

	# Get current position and update speed tracking
	var origin: Vector2 = _get_origin()
	_update_speed(origin)

	var dist_px: float = origin.distance_to(dest.global_position)
	var dist_km: float = dist_px / PX_PER_KM

	var contract: ContractData = offer.get("contract", null)
	var cargo_name: String = contract.cargo_item.item_name if (contract and contract.cargo_item) else "Cargo"

	# Calculate direction and ETA
	var direction: String = _cardinal((dest.global_position - origin).normalized())
	var eta: String = _eta_text(dist_px)

	# Build display text with direction and ETA
	label.text = "%s → %s  (%.2f km %s)  %s" % [cargo_name, dest.name, dist_km, direction, eta]

	# Color based on distance (green <1km, yellow <3km, white otherwise)
	var col: Color = Color(1, 1, 1, 1)
	if dist_km < 1.0:
		col = Color(0.2, 1.0, 0.2, 1)
	elif dist_km < 3.0:
		col = Color(1.0, 0.85, 0.2, 1)
	label.add_theme_color_override("font_color", col)


func _get_origin() -> Vector2:
	if not _player:
		return Vector2.ZERO
	# Use vehicle position if in vehicle, otherwise player position
	if _player.is_in_vehicle and _player.current_vehicle is Node2D:
		return (_player.current_vehicle as Node2D).global_position
	return _player.global_position


func _update_speed(current_origin: Vector2) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	var dt: float = max(0.0001, now - _last_update_time)
	var inst_speed: float = _last_origin.distance_to(current_origin) / dt
	# Smooth speed with exponential moving average
	_speed_px_s = lerp(inst_speed, _speed_px_s, 0.85)
	_last_origin = current_origin
	_last_update_time = now


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
	var a: float = atan2(v.y, v.x)
	var deg: float = rad_to_deg(a)
	# Map to 8-way cardinal directions
	var idx: int = int(round((deg + 180.0) / 45.0)) % 8
	var names: Array[String] = ["W", "NW", "N", "NE", "E", "SE", "S", "SW"]
	return names[idx]
