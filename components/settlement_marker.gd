## Settlement Marker
## Attach to settlement root to register with ContractManager for destinations.

extends Node2D

func _ready() -> void:
	# Register with ContractManager autoload if present
	var cm: Node = get_node_or_null("/root/ContractManager")
	if cm and cm.has_method("register_settlement"):
		cm.register_settlement(self)
