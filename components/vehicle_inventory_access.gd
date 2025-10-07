## Vehicle Inventory Access Area
##
## Allows player to interact with vehicle inventory when nearby.
## Attach to Area2D with "interactable" group.

extends Area2D

func _ready() -> void:
	# Add to interactable group so player can detect it
	add_to_group("interactable")


func get_interaction_type() -> String:
	return "vehicle_inventory"


func get_vehicle() -> Node:
	# Return parent vehicle node
	return get_parent()
