extends Button

@export var plank_normal: Texture2D
@export var plank_locked: Texture2D

@onready var plank_bg: NinePatchRect = $NormalView/PlankBG
@onready var padding: MarginContainer = $NormalView/Padding
@onready var content: HBoxContainer = $NormalView/Padding/Content
@onready var normal_view: Control = $NormalView
@onready var locked_view: Control = $LockedView
@onready var locked_price_lbl: Label = $LockedView/CenterContainer/HBoxContainer/LockedLabel
@onready var icon_lbl: TextureRect = $NormalView/Padding/Content/IconBox/Icon
@onready var title_lbl: Label = $NormalView/Padding/Content/TextCol/Title
@onready var stat_left: Label = $NormalView/Padding/Content/TextCol/HBoxContainer/StatLeft
@onready var level_lbl: Label = $NormalView/Padding/Content/Level

@onready var plank_normal_bg = $NormalView/PlankBG
@onready var plank_locked_bg = $LockedView/BG

var _block_info_hover: bool = false

signal unlock_pressed(item_id: String)
signal buy_pressed(item_id: String)

@export var info_panel_path: NodePath
@onready var info_panel: Control = get_node_or_null(info_panel_path)

@export var extra_title := ""
@export var extra_desc := ""
@export var extra_b1 := ""
@export var extra_b2 := ""
@export var extra_b3 := ""
@export var extra_footer := ""

var is_unlocked: bool = false
var unlock_price: int = 0
var price: int = 0
var item_id: String = ""

var _title_normal := ""
var _left_normal := ""
var _right_normal := ""
var _level_normal := ""
var _icon_normal: Texture2D

var _hovered := false
var _pressed := false
var _can_afford := true
var hover_rotation := 2.0
var pressed_rotation := 5.0
var click_rotation := 5.0
var tween: Tween


func _ready() -> void:
	z_index = 10
	normal_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	locked_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	locked_price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	mouse_entered.connect(func():
		_hovered = true
		_apply_plank_tint()
		if not _pressed:
			_animate_rotation(hover_rotation, 0.15)
	)

	mouse_exited.connect(func():
		_hovered = false
		_pressed = false
		_apply_plank_tint()
		_animate_rotation(0.0, 0.15)

		if info_panel and info_panel.has_method("force_hide"):
			info_panel.force_hide()
	)

	button_down.connect(func():
		_pressed = true
		_apply_plank_tint()
		_animate_rotation(pressed_rotation, 0.08)
	)

	button_up.connect(func():
		_pressed = false
		_apply_plank_tint()
		_animate_rotation(hover_rotation if _hovered else 0.0, 0.12)
	)

	pressed.connect(_on_card_pressed)

	_apply_view()
	_apply_plank_tint()

	mouse_entered.connect(_on_enter_info)
	mouse_exited.connect(_on_exit_info)


func _on_enter_info() -> void:
	if not is_unlocked:
		return

	var main = get_tree().get_first_node_in_group("main")
	if main and _block_info_hover:
		return

	if info_panel == null:
		print("INFO: info_panel_path no asignado o mal: ", info_panel_path)
		return

	var owned := level_lbl.text if level_lbl else "0"

	info_panel.show_for_card(
		self,
		extra_title,
		owned,
		extra_desc,
		extra_b1,
		extra_b2,
		extra_b3
	)


func _on_exit_info() -> void:
	_hovered = false
	if info_panel and info_panel.has_method("force_hide"):
		info_panel.force_hide()


func _on_card_pressed() -> void:
	if is_unlocked:
		buy_pressed.emit(item_id)
	else:
		unlock_pressed.emit(item_id)


func _apply_plank_tint() -> void:
	var c := Color(1, 1, 1, 1) if _can_afford else Color(0.55, 0.55, 0.55, 1)

	if _pressed:
		c = c * Color(0.85, 0.85, 0.85, 1)
	elif _hovered:
		c = c * Color(0.93, 0.93, 0.93, 1)

	if plank_normal_bg:
		plank_normal_bg.modulate = c
	if plank_locked_bg:
		plank_locked_bg.modulate = c


func setup(
	_id: String,
	title: String,
	left: String,
	right: String,
	level: String,
	icon_texture: Texture2D,
	_price: int,
	_unlock_price: int
) -> void:
	item_id = _id
	price = _price
	unlock_price = _unlock_price
	is_unlocked = (unlock_price == 0)

	_title_normal = title
	_left_normal = left
	_right_normal = right
	_level_normal = level
	_icon_normal = icon_texture

	title_lbl.text = _title_normal
	stat_left.text = _left_normal
	level_lbl.text = _level_normal
	icon_lbl.texture = _icon_normal

	_apply_view()


func set_unlocked(v: bool) -> void:
	is_unlocked = v
	_apply_view()

	if not is_unlocked and info_panel:
		info_panel.schedule_hide(0.0)


func update_state(coins: float) -> void:
	var needed := price if is_unlocked else unlock_price
	_can_afford = coins >= needed
	_apply_plank_tint()

var locked_text: String = ""
func set_locked_text(text: String) -> void:
	locked_text = text
	if not is_unlocked:
		_apply_locked_visual()
		

func _apply_locked_visual() -> void:
	disabled = false

	if plank_locked_bg and plank_locked:
		plank_locked_bg.texture = plank_locked

	locked_price_lbl.text = locked_text


func _apply_unlocked_visual() -> void:
	disabled = false

	if plank_normal:
		plank_bg.texture = plank_normal

	icon_lbl.visible = true
	stat_left.visible = true
	level_lbl.visible = true

	icon_lbl.texture = _icon_normal
	title_lbl.text = _title_normal
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stat_left.text = _left_normal
	level_lbl.text = _level_normal

func set_dynamic(new_price: float, new_left: String, new_right: String, new_level: String) -> void:
	price = int(new_price)
	_left_normal = new_left
	_right_normal = new_right
	_level_normal = new_level

	if is_unlocked:
		stat_left.text = _left_normal
		level_lbl.text = _level_normal

	refresh_info_panel_if_hovered()


func _apply_view() -> void:
	normal_view.visible = is_unlocked
	locked_view.visible = !is_unlocked

	if is_unlocked:
		_apply_unlocked_visual()
	else:
		_apply_locked_visual()

	_apply_plank_tint()


func _animate_rotation(target: float, duration: float) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "rotation_degrees", target, duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)


func _wiggle_click() -> void:
	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_property(self, "rotation_degrees", click_rotation, 0.08)
	tween.tween_property(self, "rotation_degrees", -click_rotation, 0.08)
	tween.tween_property(self, "rotation_degrees", 0.0, 0.10)


func _reset_rotation_smooth() -> void:
	_animate_rotation(0.0, 0.15)


func refresh_info_panel_if_hovered() -> void:
	if not is_unlocked:
		if info_panel:
			info_panel.schedule_hide(0.0)
		return

	if not is_hovered():
		return
		
	if info_panel == null:
		return

	var owned := level_lbl.text if level_lbl else "0"

	info_panel.show_for_card(
		self,
		extra_title,
		owned,
		extra_desc,
		extra_b1,
		extra_b2,
		extra_b3
	)
