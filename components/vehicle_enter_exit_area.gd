## Vehicle Enter/Exit Area
##
## Marks the spot where players can enter/exit a vehicle.
## Must be a child of a VehicleController.

class_name VehicleEnterExitArea extends Area2D


## Get the parent vehicle controller
func get_vehicle() -> Node:
	return get_parent()


## Get interaction type for InteractionComponent
func get_interaction_type() -> String:
	return "vehicle"


## Called when player interacts (presses F)
func interact() -> void:
	# Entering is handled by player script
	pass
