extends Control

signal pressed_item(fish_id: String)

@onready var bag_texture: TextureRect = $BagTexture
@onready var fish_icon: TextureRect = $FishIcon
@onready var amount_label: Label = $AmountLabel
@onready var name_label: Label = $NameLabel

var my_fish_id: String = ""

func _ready() -> void:
	custom_minimum_size = Vector2(98, 122)

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	bag_texture.mouse_filter = Control.MOUSE_FILTER_STOP
	fish_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	bag_texture.gui_input.connect(_on_bag_gui_input)

func setup(icon: Texture2D, amount: int, bag_tex: Texture2D, fish_id: String, fish_name: String) -> void:
	my_fish_id = fish_id
	bag_texture.texture = bag_tex
	fish_icon.texture = icon
	amount_label.text = "x%d" % amount
	name_label.text = fish_name

func _on_bag_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if my_fish_id != "":
			pressed_item.emit(my_fish_id)
