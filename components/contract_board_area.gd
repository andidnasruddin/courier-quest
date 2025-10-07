## Contract Board Area
## Add this as an Area2D child inside a Settlement scene. Marks an interactable
## that opens the contract board UI.

class_name ContractBoardArea extends Area2D

@export var settlement_name: String = "Settlement"

func _ready() -> void:
	add_to_group("interactable")
	# Ensure detection by the player's InteractionComponent (mask=2)
	collision_layer = 2
	collision_mask = 0
	# Ensure a simple collision if not present
	if get_child_count() == 0:
		var shape: CollisionShape2D = CollisionShape2D.new()
		var circ: CircleShape2D = CircleShape2D.new()
		circ.radius = 80.0
		shape.shape = circ
		add_child(shape)

func get_interaction_type() -> String:
	return "contract_board"

func get_settlement() -> Node2D:
	return get_parent() as Node2D

func get_settlement_name() -> String:
	return settlement_name

