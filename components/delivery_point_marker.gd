## Delivery Point Marker
##
## Attach to any POI (settlement, gas station, etc.) to register it as a valid
## delivery destination with ContractManager.

extends Node2D

func _ready() -> void:
	# Wait for parent's _ready to complete so parent.name is set
	await get_tree().process_frame

	# Register parent node with ContractManager autoload if present
	var parent_poi: Node2D = get_parent() as Node2D
	if not parent_poi:
		return

	var cm: Node = get_node_or_null("/root/ContractManager")
	if cm and cm.has_method("register_settlement"):
		cm.register_settlement(parent_poi)


func _exit_tree() -> void:
	# Unregister when removed from tree
	var parent_poi: Node2D = get_parent() as Node2D
	if not parent_poi:
		return

	var cm: Node = get_node_or_null("/root/ContractManager")
	if cm and cm.has_method("unregister_settlement"):
		cm.unregister_settlement(parent_poi)
