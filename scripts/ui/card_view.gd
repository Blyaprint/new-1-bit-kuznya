extends Control
@onready var category_label: Label = $Category
@onready var emblem: TextureRect = $Emblem
@onready var title_label: Label = $ItemName
@onready var quantity_label: Label = $Quantity
@onready var state_label: Label = $State
@onready var durability: ProgressBar = $Durability

func set_card_data(data: Dictionary, on_board: bool, input_ports: Array = [], output_ports: Array = []) -> void:
	category_label.text = str(data.get("category", ""))
	var emblem_file := "emblem_material.svg"
	match str(data.get("category", "")):
		"ИНСТРУМЕНТ": emblem_file = "emblem_tool.svg"
		"ОПЕРАЦИЯ": emblem_file = "emblem_operation.svg"
		"ОБЪЕКТ": emblem_file = "emblem_object.svg"
		"ИЗДЕЛИЕ": emblem_file = "emblem_product.svg"
	emblem.texture = load("res://assets/ui/" + emblem_file)
	title_label.text = str(data.get("title", ""))
	var quantity := int(data.get("quantity", 1))
	quantity_label.text = "×%d" % quantity if quantity > 1 else ""
	state_label.text = "УЗЕЛ СХЕМЫ" if on_board else "В ИНВЕНТАРЕ"
	$InputPort0.visible = on_board and input_ports.size() > 0
	$InputPort0.position.y = 74.0 if input_ports.size() == 1 else 55.0
	$InputLabel0.position.y = 76.0 if input_ports.size() == 1 else 57.0
	$InputLabel0.visible = on_board and input_ports.size() > 0
	$InputPort1.visible = on_board and input_ports.size() > 1
	$InputLabel1.visible = on_board and input_ports.size() > 1
	$OutputPort0.visible = on_board and output_ports.size() > 0
	$OutputLabel0.visible = on_board and output_ports.size() > 0
	if input_ports.size() > 0:
		$InputLabel0.text = str(input_ports[0].label)
	if input_ports.size() > 1:
		$InputLabel1.text = str(input_ports[1].label)
	if output_ports.size() > 0:
		$OutputLabel0.text = str(output_ports[0].label)
	if str(data.get("title", "")) in ["Молот", "Горн"]:
		durability.visible = true
		durability.max_value = float(data.get("max_durability", 6))
		durability.value = float(data.get("durability", 6))
	else:
		durability.visible = false
