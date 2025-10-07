## Resource definition for delivery contracts
##
## Defines contract parameters including cargo, payment, destination, and time limits.
## Tier determines difficulty and unlock requirements.
##
## @tutorial: docs/PHASE_1_CORE_DELIVERY_LOOP.md

class_name ContractData extends Resource

## Contract tier (determines unlock requirement and difficulty)
enum Tier {
	NOVICE = 1,		## Unlocked at 0+ reputation
	EXPERIENCED = 2,	## Unlocked at 100+ reputation
	EXPERT = 3		## Unlocked at 300+ reputation
}

## Display name of contract
@export var contract_name: String = "Delivery Contract"

## Contract difficulty tier
@export var tier: Tier = Tier.NOVICE

## Item to be delivered
@export var cargo_item: ItemData

## Number of cargo items to deliver
@export var cargo_quantity: int = 1

## Payment per kilometer traveled
@export var payment_per_km: float = 10.0

## Distance range for this contract (min, max) in pixels
@export var distance_range: Vector2 = Vector2(50000, 150000)  # 5-15 km

## Time limit in real-time minutes
@export var time_limit_minutes: float = 20.0

## Destination settlement name (assigned procedurally)
@export var destination_settlement: String = ""

## Is cargo fragile (takes damage if vehicle damaged)
@export var fragile: bool = false

## High risk contract (attracts more enemies in Phase 3)
@export var high_risk: bool = false


## Get tier as string for UI display
func get_tier_name() -> String:
	match tier:
		Tier.NOVICE:
			return "Novice"
		Tier.EXPERIENCED:
			return "Experienced"
		Tier.EXPERT:
			return "Expert"
		_:
			return "Unknown"


## Get reputation requirement to unlock this tier
func get_reputation_requirement() -> int:
	match tier:
		Tier.NOVICE:
			return 0
		Tier.EXPERIENCED:
			return 100
		Tier.EXPERT:
			return 300
		_:
			return 0


## Calculate payment for a given distance traveled
func calculate_payment(distance_pixels: float) -> int:
	var distance_km: float = distance_pixels / 10000.0
	return int(distance_km * payment_per_km)


## Get failure penalty (percentage of cargo value to pay back)
func get_failure_penalty_percent() -> float:
	match tier:
		Tier.NOVICE:
			return 0.5  # 50%
		Tier.EXPERIENCED:
			return 0.75  # 75%
		Tier.EXPERT:
			return 1.0  # 100%
		_:
			return 0.5


## Get reputation loss for failing this contract
func get_reputation_penalty() -> int:
	match tier:
		Tier.NOVICE:
			return -5
		Tier.EXPERIENCED:
			return -15
		Tier.EXPERT:
			return -30
		_:
			return -5
