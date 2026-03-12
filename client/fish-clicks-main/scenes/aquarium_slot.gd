extends Control

signal pressed_slot(slot_index: int, fish_id: String)

@onready var slot_bg: TextureRect = $SlotBg
@onready var fish_icon: TextureRect = $MarginContainer/FishIcon

var my_slot_index: int = -1
var my_fish_id: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	slot_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fish_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup(fish_texture: Texture2D = null, slot_index: int = -1, fish_id: String = "") -> void:
	my_slot_index = slot_index
	my_fish_id = fish_id
	fish_icon.texture = fish_texture
	fish_icon.visible = fish_texture != null

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("slot rect:", get_global_rect(), " slot:", my_slot_index, " fish:", my_fish_id)
		if my_fish_id != "":
			pressed_slot.emit(my_slot_index, my_fish_id)
