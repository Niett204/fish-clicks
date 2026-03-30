extends Control

signal pressed_item(fish_id: String)

@onready var bag_texture: TextureRect = $BagTexture
@onready var fish_icon: TextureRect = $FishIcon
@onready var amount_label: Label = $AmountLabel
@onready var name_label: Label = $NameArea/NameRow/NameLabel
@onready var shiny_icon: TextureRect = $NameArea/NameRow/ShinyIcon

var my_fish_id: String = ""
var _base_position := Vector2.ZERO
var _is_hovered := false
var _is_pressed := false
var _anim_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
		
	_base_position = position

	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)

	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)

	custom_minimum_size = Vector2(98, 122)

	bag_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fish_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if shiny_icon:
		shiny_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	await get_tree().process_frame
	pivot_offset = size / 2.0

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_pressed = true
			_update_visual_state()

			if my_fish_id != "":
				pressed_item.emit(my_fish_id)
		else:
			_is_pressed = false
			_update_visual_state()

func _on_mouse_entered() -> void:
	_is_hovered = true
	_update_visual_state()

func _on_mouse_exited() -> void:
	_is_hovered = false
	_is_pressed = false
	_update_visual_state()

func _update_visual_state() -> void:
	if _anim_tween:
		_anim_tween.kill()

	var target_scale := Vector2.ONE
	var target_modulate := Color(1, 1, 1, 1)

	if _is_pressed:
		target_scale = Vector2(0.96, 0.96)
		target_modulate = Color(0.88, 0.88, 0.88, 1)
	elif _is_hovered:
		target_scale = Vector2(1.06, 1.06)
		target_modulate = Color(1.05, 1.05, 1.05, 1)

	_anim_tween = create_tween()
	_anim_tween.set_trans(Tween.TRANS_BACK)
	_anim_tween.set_ease(Tween.EASE_OUT)
	_anim_tween.parallel().tween_property(self, "scale", target_scale, 0.12)
	_anim_tween.parallel().tween_property(self, "modulate", target_modulate, 0.12)

func setup(
	icon: Texture2D,
	amount: int,
	bag_tex: Texture2D,
	fish_id: String,
	fish_name: String,
	is_shiny: bool = false
) -> void:
	my_fish_id = fish_id
	bag_texture.texture = bag_tex
	fish_icon.texture = icon
	amount_label.text = "x%d" % amount
	name_label.text = fish_name

	if shiny_icon:
		shiny_icon.visible = is_shiny
