extends Button
signal buy_pressed(item_id: String)

@export var plank_normal: Texture2D
@export var plank_locked: Texture2D

@onready var plank_bg: NinePatchRect = $NormalView/PlankBG
@onready var padding: MarginContainer = $NormalView/Padding
@onready var content: HBoxContainer = $NormalView/Padding/Content

@onready var icon_lbl: TextureRect = $NormalView/Padding/Content/IconBox/Icon
@onready var title_lbl: Label = $NormalView/Padding/Content/TextCol/Title
@onready var stat_left: Label = $NormalView/Padding/Content/TextCol/SubRow/StatLeft
@onready var stat_right: Label = $NormalView/Padding/Content/TextCol/SubRow/StatRight
@onready var level_lbl: Label = $NormalView/Padding/Content/Level

var item_id: String
var price: float = 0.0
var unlock_price: float = 0.0
var is_unlocked: bool = false

# Guardamos lo "normal" para restaurar al desbloquear
var _title_normal := ""
var _left_normal := ""
var _right_normal := ""
var _level_normal := ""
var _icon_normal: Texture2D

func _ready() -> void:
	pressed.connect(func(): emit_signal("buy_pressed", item_id))

func setup(
	id: String,
	title: String,
	left: String,
	right: String,
	level: String,
	icon_tex: Texture2D,
	item_price: float,
	item_unlock_price: float
) -> void:
	item_id = id
	price = item_price
	unlock_price = item_unlock_price

	_title_normal = title
	_left_normal = left
	_right_normal = right
	_level_normal = level
	_icon_normal = icon_tex

	# Pinta estado inicial locked (hasta que update_state lo cambie)
	_apply_locked_visual()

func update_state(current_coins: float) -> void:
	if not is_unlocked and current_coins >= unlock_price:
		is_unlocked = true

	if not is_unlocked:
		_apply_locked_visual()
		return

	_apply_unlocked_visual()

	# Una vez desbloqueado: gris si no puedes comprar
	var can_buy := current_coins >= price
	disabled = not can_buy
	content.modulate = Color(1,1,1,1) if can_buy else Color(0.7,0.7,0.7,1)

func _apply_locked_visual() -> void:
	disabled = true

	if plank_locked:
		plank_bg.texture = plank_locked

	# Solo texto de desbloqueo
	icon_lbl.visible = false
	stat_left.visible = false
	stat_right.visible = false
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
	stat_right.visible = true
	level_lbl.visible = true

	icon_lbl.texture = _icon_normal
	title_lbl.text = _title_normal
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stat_left.text = _left_normal
	stat_right.text = _right_normal
	level_lbl.text = _level_normal
