## Contract Manager (Autoload)
##
## Generates delivery contract offers at settlements and tracks the active contract.
## MVP: straight-line distance, 3-5 offers, Novice tier, cargo added to player inventory.

extends Node

signal offers_generated(settlement: Node, offers: Array[Dictionary])
signal contract_accepted(offer: Dictionary)
signal contract_completed(offer: Dictionary, payment: int)

const PX_PER_KM: float = 10000.0

var settlements: Array[Node2D] = []
var active_contract: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _cargo_items: Array[ItemData] = []

@export var min_offers: int = 3
@export var max_offers: int = 5
@export var delivery_radius_px: float = 140.0

func _ready() -> void:
	_rng.randomize()
	# Load cargo item variations for offers
	var paths: Array[String] = [
		"res://resources/items/examples/package_small.tres",
		"res://resources/items/examples/package_letter.tres",
		"res://resources/items/examples/package_medium.tres",
		"res://resources/items/examples/package_long.tres",
		"res://resources/items/examples/package_large_crate.tres",
		"res://resources/items/examples/delivery_package.tres"
	]
	for path in paths:
		var res: Resource = load(path)
		if res is ItemData:
			_cargo_items.append(res)

func register_settlement(s: Node2D) -> void:
	if not settlements.has(s):
		settlements.append(s)

func unregister_settlement(s: Node2D) -> void:
	settlements.erase(s)

func get_settlement_list() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for settlement in settlements:
		if settlement and is_instance_valid(settlement):
			result.append(settlement)
	return result

## Generate 3-5 offers from `origin_settlement` to other settlements in range.
## Returns an array of dictionaries with keys: contract, destination, dest_name, distance_px
func generate_offers(origin_settlement: Node2D, base_contract: ContractData) -> Array[Dictionary]:
	if not is_instance_valid(origin_settlement):
		return []
	var others: Array[Node2D] = []
	for settlement in get_settlement_list():
		if settlement != origin_settlement:
			others.append(settlement)
	if others.is_empty():
		return []

	var offers: Array[Dictionary] = []
	var count: int = clamp(_rng.randi_range(min_offers, max_offers), 1, 8)

	for _i in range(count):
		var dest: Node2D = others[_rng.randi_range(0, others.size() - 1)]
		var dist_px: float = origin_settlement.global_position.distance_to(dest.global_position)
		# If outside template distance range, re-roll a few times
		var attempts: int = 0
		while ((dist_px < base_contract.distance_range.x or dist_px > base_contract.distance_range.y) and attempts < 8 and others.size() > 1):
			dest = others[_rng.randi_range(0, others.size() - 1)]
			dist_px = origin_settlement.global_position.distance_to(dest.global_position)
			attempts += 1

		var contract_clone: ContractData = ContractData.new()
		contract_clone.contract_name = base_contract.contract_name
		contract_clone.tier = base_contract.tier
		var cargo: ItemData = base_contract.cargo_item
		if _cargo_items.size() > 0:
			cargo = _cargo_items[_rng.randi_range(0, _cargo_items.size() - 1)]
		contract_clone.cargo_item = cargo
		contract_clone.cargo_quantity = base_contract.cargo_quantity
		contract_clone.payment_per_km = base_contract.payment_per_km
		contract_clone.distance_range = base_contract.distance_range
		contract_clone.time_limit_minutes = base_contract.time_limit_minutes
		contract_clone.destination_settlement = dest.name
		contract_clone.fragile = base_contract.fragile
		contract_clone.high_risk = base_contract.high_risk

		var offer: Dictionary = {
			"contract": contract_clone,
			"destination": dest,
			"dest_name": dest.name,
			"distance_px": dist_px,
			"payment": int((dist_px / PX_PER_KM) * contract_clone.payment_per_km)
		}
		offers.append(offer)

	offers_generated.emit(origin_settlement, offers)
	return offers

## Accept an offer: set active contract and add cargo to player's inventory
func accept_offer(offer: Dictionary, player: Node) -> void:
	if offer.is_empty():
		return
	active_contract = offer
	if player and player.has_node("Inventory"):
		var inv: Inventory = player.get_node("Inventory")
		var data: ContractData = offer.get("contract", null)
		if inv and data and data.cargo_item:
			inv.add_item(data.cargo_item, data.cargo_quantity)
	contract_accepted.emit(offer)

func get_active_contract() -> Dictionary:
	return active_contract

func get_active_destination() -> Node2D:
	if active_contract.is_empty():
		return null
	var dest_name: String = str(active_contract.get("dest_name", ""))
	if dest_name == "":
		return null
	for s in settlements:
		if s and is_instance_valid(s) and s.name == dest_name:
			return s
	return null

## Call regularly from player to check for completion
func try_complete(player: Node2D) -> void:
	if active_contract.is_empty():
		return
	var dest: Node2D = get_active_destination()
	if not dest:
		return
	if player.global_position.distance_to(dest.global_position) <= delivery_radius_px:
		var payment: int = int(active_contract.get("payment", 0))
		# Remove cargo if possible
		if player and player.has_node("Inventory"):
			var inv: Inventory = player.get_node("Inventory")
			var data: ContractData = active_contract.get("contract", null)
			if inv and data and data.cargo_item:
				# Try to remove cargo_quantity from the first matching stack/item
				var remaining: int = data.cargo_quantity
				for item in inv.data.get_all_items():
					if item and item.data == data.cargo_item:
						var take: int = min(item.stack_count, remaining)
						inv.remove_item(item, take)
						remaining -= take
						if remaining <= 0:
							break
		# Emit and clear active
		contract_completed.emit(active_contract, payment)
		active_contract = {}

## === SAVE / LOAD ===

func get_save_data() -> Dictionary:
	# Serialize minimal active contract info necessary to restore
	if active_contract.is_empty():
		return { "active": false }
	var c: ContractData = active_contract.get("contract", null)
	var dest_name: String = str(active_contract.get("dest_name", ""))
	var payment: int = int(active_contract.get("payment", 0))
	var cargo_path: String = ""
	if c and c.cargo_item:
		cargo_path = str(c.cargo_item.resource_path)
	return {
		"active": true,
		"contract": {
			"contract_name": c.contract_name if c else "",
			"cargo_item_path": cargo_path,
			"cargo_quantity": c.cargo_quantity if c else 0,
			"payment_per_km": c.payment_per_km if c else 0.0,
			"distance_min": (c.distance_range.x if c else 0.0),
			"distance_max": (c.distance_range.y if c else 0.0),
			"time_limit_minutes": (c.time_limit_minutes if c else 0.0),
			"fragile": (c.fragile if c else false),
			"high_risk": (c.high_risk if c else false)
		},
		"dest_name": dest_name,
		"payment": payment
	}

func load_save_data(data: Dictionary) -> void:
	active_contract = {}
	if data.is_empty() or not data.get("active", false):
		return
	var cdata: Dictionary = data.get("contract", {})
	var contract := ContractData.new()
	contract.contract_name = str(cdata.get("contract_name", ""))
	var cargo_path: String = str(cdata.get("cargo_item_path", ""))
	if cargo_path != "":
		var res: Resource = load(cargo_path)
		if res is ItemData:
			contract.cargo_item = res as ItemData
	contract.cargo_quantity = int(cdata.get("cargo_quantity", 0))
	contract.payment_per_km = float(cdata.get("payment_per_km", 0.0))
	contract.distance_range = Vector2(float(cdata.get("distance_min", 0.0)), float(cdata.get("distance_max", 0.0)))
	contract.time_limit_minutes = float(cdata.get("time_limit_minutes", 0.0))
	contract.fragile = bool(cdata.get("fragile", false))
	contract.high_risk = bool(cdata.get("high_risk", false))

	var dest_name: String = str(data.get("dest_name", ""))
	var payment: int = int(data.get("payment", 0))
	active_contract = {
		"contract": contract,
		"destination": get_active_destination(),
		"dest_name": dest_name,
		"distance_px": 0.0,
		"payment": payment
	}
