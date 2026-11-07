extends Control
@onready var category_label: Label = $Category
@onready var title_label: Label = $ItemName
@onready var quantity_label: Label = $Quantity
@onready var state_label: Label = $State
@onready var durability: ProgressBar = $Durability

func set_card_data(data: Dictionary, on_board: bool) -> void:
	category_label.text = str(data.get("category", ""))
	title_label.text = str(data.get("title", ""))
	var quantity := int(data.get("quantity", 1))
	quantity_label.text = "×%d" % quantity if quantity > 1 else ""
	state_label.text = "УЗЕЛ СХЕМЫ" if on_board else "В ИНВЕНТАРЕ"
	if str(data.get("title", "")) in ["Молот", "Горн"]:
		durability.visible = true
		durability.max_value = float(data.get("max_durability", 6))
		durability.value = float(data.get("durability", 6))
	else:
		durability.visible = false
