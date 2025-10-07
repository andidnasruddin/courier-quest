## Vehicle Storage Indicator
##
## Displays a prompt when player is near vehicle storage access area.

extends Label

@export var player_path: NodePath
@export var check_distance: float = 100.0

var _player: Player = null
var _vehicles_in_range: Array[Node] = []


func _ready() -> void:
	_player = get_node_or_null(player_path) as Player
	text = ""
	set_process(true)


func _process(_delta: float) -> void:
	if not _player:
		text = ""
		return

	# Find nearby vehicles with inventory access
	_find_nearby_vehicles()

	if _vehicles_in_range.size() > 0:
		text = "[F] Access Vehicle Storage"
		modulate = Color(1, 1, 1, 1)
	else:
		text = ""


func _find_nearby_vehicles() -> void:
	_vehicles_in_range.clear()

	# Get all nodes in "interactable" group
	var interactables: Array[Node] = get_tree().get_nodes_in_group("interactable")

	for node in interactables:
		if not node.has_method("get_interaction_type"):
			continue

		if node.get_interaction_type() == "vehicle_inventory":
			# Check distance
			if node is Node2D and _player:
				var dist: float = _player.global_position.distance_to((node as Node2D).global_position)
				if dist <= check_distance:
					_vehicles_in_range.append(node)
