## Interaction Component
##
## Detects nearby interactable objects and handles interaction input.
## Uses Area2D to detect objects with "interactable" group.
##
## @tutorial: docs/PHASE_1_CORE_DELIVERY_LOOP.md

class_name InteractionComponent extends Area2D

signal interactable_found(interactable: Node)
signal interactable_lost(interactable: Node)
signal interaction_triggered(interactable: Node)

## Detection radius for nearby interactables
@export var interaction_radius: float = 30.0

## Currently detected interactable objects
var _nearby_interactables: Array[Node] = []

## The closest interactable (priority for interaction)
var _closest_interactable: Node = null


func _ready() -> void:
	# Set up collision layer/mask
	collision_layer = 0  # Don't collide with anything
	collision_mask = 2  # Detect interactables on layer 2

	# Create collision shape
	var shape := CircleShape2D.new()
	shape.radius = interaction_radius

	var collision_shape := CollisionShape2D.new()
	collision_shape.shape = shape
	add_child(collision_shape)

	# Connect area signals
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	# Check for interaction input
	if Input.is_action_just_pressed("interact"):
		_trigger_interaction()

	# Update closest interactable
	_update_closest_interactable()


## Handle area entering detection radius
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("interactable"):
		_add_interactable(area)


## Handle area leaving detection radius
func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("interactable"):
		_remove_interactable(area)


## Handle body entering detection radius
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("interactable"):
		_add_interactable(body)


## Handle body leaving detection radius
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("interactable"):
		_remove_interactable(body)


## Add interactable to nearby list
func _add_interactable(interactable: Node) -> void:
	if not _nearby_interactables.has(interactable):
		_nearby_interactables.append(interactable)
		interactable_found.emit(interactable)


## Remove interactable from nearby list
func _remove_interactable(interactable: Node) -> void:
	if _nearby_interactables.has(interactable):
		_nearby_interactables.erase(interactable)
		interactable_lost.emit(interactable)

		if _closest_interactable == interactable:
			_closest_interactable = null


## Update which interactable is closest
func _update_closest_interactable() -> void:
	if _nearby_interactables.is_empty():
		_closest_interactable = null
		return

	var closest_distance: float = INF
	var closest: Node = null

	for interactable in _nearby_interactables:
		if not is_instance_valid(interactable) or not interactable is Node2D:
			continue

		var distance: float = global_position.distance_to(interactable.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = interactable

	_closest_interactable = closest


## Trigger interaction with closest interactable
func _trigger_interaction() -> void:
	if not _closest_interactable:
		return

	# Call interact method if it exists
	if _closest_interactable.has_method("interact"):
		_closest_interactable.interact()

	interaction_triggered.emit(_closest_interactable)


## Get closest interactable object
func get_closest_interactable() -> Node:
	return _closest_interactable


## Check if any interactables are nearby
func has_interactables() -> bool:
	return not _nearby_interactables.is_empty()


## Get all nearby interactables
func get_nearby_interactables() -> Array[Node]:
	return _nearby_interactables.duplicate()
