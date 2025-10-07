## Save System (Autoloaded)
##
## Handles auto-saving game state when the player is near settlements and
## provides manual save/load helpers. Saves to user://save_game.json in JSON.

extends Node
# class_name SaveSystem

const SAVE_PATH: String = "user://save_game.json"

@export var autosave_enabled: bool = false  # Disabled by default - too spammy
@export var autosave_check_interval: float = 2.0
@export var autosave_chunk_radius: int = 1   # 3x3 chunks => Chebyshev distance <= 1
@export var save_cooldown: float = 5.0  # Minimum seconds between saves

var _timer: Timer
var _player: Player = null
var _last_vehicle: VehicleController = null
var _last_saved_time: float = 0.0

# Toast UI
var _toast_layer: CanvasLayer
var _toast_panel: Panel
var _toast_label: Label
var _toast_timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = autosave_check_interval
	_timer.one_shot = false
	_timer.autostart = true
	add_child(_timer)
	_timer.timeout.connect(_on_autosave_tick)

	# Try to find the player and hook signals
	_find_player()

	# Save on contract completion
	var contract_mgr: Node = get_node_or_null("/root/ContractManager")
	if contract_mgr and contract_mgr.has_signal("contract_completed"):
		contract_mgr.contract_completed.connect(_on_contract_completed)

	# Build toast UI
	_init_toast()

	# Attempt to load existing save on start (optional for MVP)
	# Uncomment to auto-load on start:
	# load_game()


func _process(_delta: float) -> void:
	# In case player spawns later
	if _player == null:
		_find_player()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_now"):
		save_game()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("load_save"):
		load_game()
		get_viewport().set_input_as_handled()

func _init_toast() -> void:
	_toast_layer = CanvasLayer.new()
	add_child(_toast_layer)

	_toast_panel = Panel.new()
	_toast_panel.visible = false
	_toast_panel.modulate = Color(1, 1, 1, 0.92)
	_toast_panel.size = Vector2(520, 48)
	_toast_layer.add_child(_toast_panel)

	_toast_label = Label.new()
	_toast_label.text = ""
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_toast_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toast_label.size_flags_vertical = Control.SIZE_FILL
	_toast_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	_toast_panel.add_child(_toast_label)

	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	_toast_layer.add_child(_toast_timer)
	_toast_timer.timeout.connect(func() -> void:
		_toast_panel.visible = false
	)

func _layout_toast() -> void:
	if not _toast_panel:
		return
	var vp: Rect2 = get_viewport().get_visible_rect()
	# Bottom center, with margin from bottom
	var margin: float = 36.0
	var size: Vector2 = _toast_panel.size
	_toast_panel.position = Vector2(vp.position.x + (vp.size.x - size.x) * 0.5, vp.position.y + vp.size.y - size.y - margin)
	# Stretch label to panel
	_toast_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_toast_label.position = Vector2.ZERO
	_toast_label.size = size

func show_toast(message: String, duration: float = 1.5) -> void:
	if not _toast_panel:
		return
	_toast_label.text = message
	_layout_toast()
	_toast_panel.visible = true
	_toast_timer.stop()
	_toast_timer.start(max(0.25, duration))


func _find_player() -> void:
	# Search the scene tree for a Player instance
	var root: Node = get_tree().root
	var p: Player = _find_node_by_type(root, Player) as Player
	if p:
		_player = p
		# Listen for vehicle enter/exit to track last vehicle ref
		if not _player.entered_vehicle.is_connected(_on_player_enter_vehicle):
			_player.entered_vehicle.connect(_on_player_enter_vehicle)
		if not _player.exited_vehicle.is_connected(_on_player_exit_vehicle):
			_player.exited_vehicle.connect(_on_player_exit_vehicle)


func _find_node_by_type(node: Node, type_hint: Variant) -> Node:
	if is_instance_of(node, type_hint):
		return node
	for c: Node in node.get_children():
		var found: Node = _find_node_by_type(c, type_hint)
		if found:
			return found
	return null


func _on_player_enter_vehicle(vehicle: Node) -> void:
	if vehicle is VehicleController:
		_last_vehicle = vehicle as VehicleController


func _on_player_exit_vehicle() -> void:
	# Keep last_vehicle reference for saving even after exiting
	pass


func _on_contract_completed(_offer: Dictionary, _payment: int) -> void:
	# Force an immediate save on contract completion
	save_game()


func _on_autosave_tick() -> void:
	if not autosave_enabled:
		return
	if _player == null:
		return
	if _is_player_near_settlement(_player.global_position):
		save_game()


func _is_player_near_settlement(player_pos: Vector2) -> bool:
	# Use ContractManager's settlement registry and ChunkManager.CHUNK_SIZE
	var contract_mgr: Node = get_node_or_null("/root/ContractManager")
	var chunk_mgr: Node = get_node_or_null("/root/ChunkManager")

	var settlements: Array[Node2D] = []
	if contract_mgr and contract_mgr.has_method("get_settlement_list"):
		settlements = contract_mgr.get_settlement_list()
	if settlements.is_empty():
		return false

	var chunk_size: int = 1024  # Default chunk size
	if chunk_mgr and "CHUNK_SIZE" in chunk_mgr:
		chunk_size = chunk_mgr.CHUNK_SIZE

	var pcs: Vector2i = Vector2i(floori(player_pos.x / chunk_size), floori(player_pos.y / chunk_size))
	for s in settlements:
		if s == null or not is_instance_valid(s):
			continue
		var scs: Vector2i = Vector2i(floori(s.global_position.x / chunk_size), floori(s.global_position.y / chunk_size))
		var dx: int = abs(pcs.x - scs.x)
		var dy: int = abs(pcs.y - scs.y)
		if max(dx, dy) <= autosave_chunk_radius:
			return true
	return false


## Public API: Save
func save_game() -> void:
	# Cooldown check to prevent spam
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - _last_saved_time < save_cooldown:
		print("[SaveSystem] Save skipped - cooldown active (", snappedf(save_cooldown - (current_time - _last_saved_time), 0.1), "s remaining)")
		return

	var save: Dictionary = {}
	save.version = 1

	# Player
	if _player:
		var player_inv_data: Dictionary = _player.inventory.get_save_data() if _player.inventory else {}
		print("[SaveSystem] Saving player inventory with ", player_inv_data.get("items", []).size(), " items")
		save.player = {
			"position": { "x": _player.global_position.x, "y": _player.global_position.y },
			"rotation": _player.rotation,
			"is_in_vehicle": _player.is_in_vehicle,
			"inventory": player_inv_data
		}

	# Vehicle - always search for it in case _last_vehicle is stale
	var vehicle: VehicleController = _find_node_by_type(get_tree().root, VehicleController) as VehicleController
	if vehicle:
		var vehicle_data: Dictionary = vehicle.get_save_data()
		print("[SaveSystem] Saving vehicle inventory with ", vehicle_data.get("inventory", {}).get("items", []).size(), " items")
		save.vehicle = vehicle_data
		_last_vehicle = vehicle  # Update reference

	# Contract state
	var contract_mgr: Node = get_node_or_null("/root/ContractManager")
	if contract_mgr and contract_mgr.has_method("get_save_data"):
		save.contract = contract_mgr.get_save_data()

	# Write JSON
	var fa := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if fa:
		var json := JSON.stringify(save, "\t")
		fa.store_string(json)
		fa.close()
		_last_saved_time = current_time
		print("[SaveSystem] Game saved to ", SAVE_PATH)
		show_toast("Game saved")
	else:
		push_warning("[SaveSystem] Could not open save file for writing: " + SAVE_PATH)
		show_toast("Save failed: cannot write file")


## Public API: Load
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var fa := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not fa:
		return
	var txt: String = fa.get_as_text()
	fa.close()
	var parse: Variant = JSON.parse_string(txt)
	if typeof(parse) != TYPE_DICTIONARY:
		push_warning("[SaveSystem] Invalid save data format")
		show_toast("Load failed: invalid save")
		return
	var data: Dictionary = parse as Dictionary

	# Restore player
	if _player and data.has("player"):
		var pd: Dictionary = data.player
		if pd.has("position"):
			var p: Dictionary = pd.position as Dictionary
			_player.global_position = Vector2(float(p.x), float(p.y))
		if pd.has("rotation"):
			_player.rotation = float(pd.rotation)
		if pd.has("inventory") and _player.inventory:
			print("[SaveSystem] Loading player inventory with ", pd.inventory.get("items", []).size(), " items")
			_player.inventory.load_save_data(pd.inventory)

	# Restore vehicle (apply to last referenced if present, otherwise try find any vehicle)
	if data.has("vehicle"):
		var vd: Dictionary = data.vehicle
		var veh: VehicleController = _last_vehicle
		if veh == null:
			# Try to locate any VehicleController in the scene
			var v: VehicleController = _find_node_by_type(get_tree().root, VehicleController) as VehicleController
			veh = v
		if veh and veh.has_method("load_save_data"):
			print("[SaveSystem] Loading vehicle inventory with ", vd.get("inventory", {}).get("items", []).size(), " items")
			veh.load_save_data(vd)

	# Restore contracts
	var contract_mgr: Node = get_node_or_null("/root/ContractManager")
	if data.has("contract") and contract_mgr and contract_mgr.has_method("load_save_data"):
		contract_mgr.load_save_data(data.contract)

	print("[SaveSystem] Game loaded from ", SAVE_PATH)
	show_toast("Game loaded")
