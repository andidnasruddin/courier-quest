extends CanvasLayer
class_name ContractBoardUI

signal closed()

@onready var panel: Panel = $BoardPanel
@onready var list_container: VBoxContainer = $BoardPanel/Margin/VBox/Offers
@onready var title_label: Label = $BoardPanel/Margin/VBox/Title
@onready var close_button: Button = $BoardPanel/Margin/VBox/CloseRow/CloseButton

var _offers: Array[Dictionary] = []
var _player: Node = null

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(close)

func open(settlement: Node2D, offers: Array[Dictionary], player: Node) -> void:
	_offers = offers
	_player = player
	title_label.text = "Contracts at %s" % settlement.name
	_rebuild_list()
	visible = true

func _rebuild_list() -> void:
	for child in list_container.get_children():
		child.queue_free()
	var idx: int = 0
	for offer in _offers:
		var line: HBoxContainer = HBoxContainer.new()
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label: Label = Label.new()
		var km: float = float(offer.get("distance_px", 0.0)) / 10000.0
		var pay: int = int(offer.get("payment", 0))
		var contract: ContractData = offer.get("contract", null)
		var contract_name: String = "Delivery"
		if contract:
			contract_name = contract.contract_name
		var destination_name: String = str(offer.get("dest_name", "Unknown"))
		label.text = "%s -> %s  (%.1f km, %d cr)" % [contract_name, destination_name, km, pay]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var button: Button = Button.new()
		button.text = "Accept"
		button.pressed.connect(_on_accept.bind(idx))
		line.add_child(label)
		line.add_child(button)
		list_container.add_child(line)
		idx += 1

func _on_accept(idx: int) -> void:
	if idx < 0 or idx >= _offers.size():
		return
	ContractManager.accept_offer(_offers[idx], _player)
	close()


func close() -> void:
	visible = false
	closed.emit()
