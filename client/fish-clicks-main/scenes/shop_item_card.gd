extends Button

@export var plank_normal: Texture2D
@export var plank_locked: Texture2D

@onready var plank_bg: NinePatchRect = $NormalView/PlankBG
@onready var padding: MarginContainer = $NormalView/Padding
@onready var content: HBoxContainer = $NormalView/Padding/Content
@onready var normal_view: Control = $NormalView
@onready var locked_view: Control = $LockedView
@onready var locked_price_lbl: Label = $LockedView/CenterContainer/LockedLabel
@onready var icon_lbl: TextureRect = $NormalView/Padding/Content/IconBox/Icon
@onready var title_lbl: Label = $NormalView/Padding/Content/TextCol/Title
@onready var stat_left: Label = $NormalView/Padding/Content/TextCol/StatLeft
@onready var level_lbl: Label = $NormalView/Padding/Content/Level

@onready var plank_normal_bg = $NormalView/PlankBG        # ajusta nombre/path
@onready var plank_locked_bg = $LockedView/BG    # si tienes fondo locked

signal unlock_pressed(item_id: String)
signal buy_pressed(item_id: String)

var is_unlocked: bool = false
var unlock_price: int = 0
var price: int = 0
var item_id: String = ""

# Guardamos lo "normal" para restaurar al desbloquear
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
	)

	button_down.connect(func():
		_pressed = true
		_apply_plank_tint()
		_animate_rotation(pressed_rotation, 0.08)  # mientras mantienes
	)

	button_up.connect(func():
		_pressed = false
		_apply_plank_tint()
		# vuelve a hover si sigues encima, si no a 0
		_animate_rotation(hover_rotation if _hovered else 0.0, 0.12)
	)

	pressed.connect(_on_card_pressed)

	_apply_view()
	_apply_plank_tint()

func _on_card_pressed() -> void:
	if is_unlocked:
		buy_pressed.emit(item_id)
	else:
		unlock_pressed.emit(item_id)

func _apply_plank_tint() -> void:
	# Base según si puedes comprar
	var c := Color(1, 1, 1, 1) if _can_afford else Color(0.55, 0.55, 0.55, 1)

	# Encima de eso, hover/click (solo si puedes, o si quieres también cuando no puedes)
	if _pressed:
		c = c * Color(0.85, 0.85, 0.85, 1)
	elif _hovered:
		c = c * Color(0.93, 0.93, 0.93, 1)

	# Aplica al fondo visible
	if plank_normal_bg:
		plank_normal_bg.modulate = c
	if plank_locked_bg:
		plank_locked_bg.modulate = c

func _on_pressed() -> void:
	if is_unlocked:
		buy_pressed.emit(item_id)
	else:
		unlock_pressed.emit(item_id)

func setup(_id: String, title: String, left: String, right: String, level: String,
	icon: Texture2D, _price: int, _unlock_price: int) -> void:

	item_id = _id
	price = _price
	unlock_price = _unlock_price
	is_unlocked = (unlock_price == 0)

	_title_normal = title
	_left_normal  = left
	_right_normal = right
	_level_normal = level
	_icon_normal  = icon

	# Pinta los datos normales (para que no se quede con "Doblon" por defecto)
	title_lbl.text = _title_normal
	stat_left.text = _left_normal
	level_lbl.text = _level_normal
	icon_lbl.texture = _icon_normal

	_apply_view()

func set_unlocked(v: bool) -> void:
	is_unlocked = v
	_apply_view()

func update_state(coins: float) -> void:
	var needed := price if is_unlocked else unlock_price
	_can_afford = coins >= needed
	_apply_plank_tint()

func _apply_locked_visual() -> void:
	disabled = false  # para que puedas clicar y emitir unlock_pressed

	if plank_locked:
		plank_bg.texture = plank_locked

	# Solo texto de desbloqueo
	icon_lbl.visible = false
	stat_left.visible = false
	level_lbl.visible = false

	title_lbl.text = "Desbloquea con " + str(int(unlock_price)) + " doblones"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _apply_unlocked_visual() -> void:
	# Ojo: aquí NO decidimos si se puede comprar (eso lo hace update_state)
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

func set_dynamic(new_price: float, new_left: String, new_right: String,
	new_level: String ) -> void:
	price = new_price
	_left_normal = new_left
	_right_normal = new_right
	_level_normal = new_level

	# Si ya está desbloqueada, actualiza lo visible al momento
	if is_unlocked:
		stat_left.text = _left_normal
		level_lbl.text = _level_normal
		

func _apply_view() -> void:
	normal_view.visible = is_unlocked
	locked_view.visible = !is_unlocked

	if is_unlocked:
		_apply_unlocked_visual()
	else:
		_apply_locked_visual()
		locked_price_lbl.text = "Desbloquear: %d" % unlock_price

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
