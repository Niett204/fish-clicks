extends Control

@export var anim_time := 0.18
@export var offset := Vector2(20, 0)
@export var panel_width := 200.0
@export var min_height := 200.0
@export var padding := Vector2(24, 24) # (x,y)

var _tw: Tween
var _hover_panel := false
var _showing := false

var _hide_timer: SceneTreeTimer
var _show_token := 0  # sube cada vez que se muestra (anti hides viejos)

func _ready() -> void:
	z_as_relative = false
	visible = false

	mouse_entered.connect(func():
		_hover_panel = true
		_cancel_hide()
	)

	mouse_exited.connect(func():
		_hover_panel = false
		schedule_hide(0.06)
	)

func show_for_card(
	card: Control,
	title: String,
	owned: int,
	desc: String,
	b1: String,
	b2: String,
	b3: String,
	extra: String
) -> void:
	_show_token += 1
	_cancel_hide()

	$Banner/CardBox/VBox/Header/Title.text = title
	$Banner/CardBox/VBox/Header/Owned.text = "owned: %d" % owned

	$Banner/CardBox/VBox/Desc.text = desc

	$Banner/CardBox/VBox/Bullets/B1.text = "• " + b1
	$Banner/CardBox/VBox/Bullets/B2.text = "• " + b2
	$Banner/CardBox/VBox/Bullets/B3.text = "• " + b3

	visible = true
	_showing = true

	# 1) Forzamos ancho fijo
	$Banner.size.x = panel_width
	$Banner.position = Vector2.ZERO

	# Si CardBox es contenedor del VBox, dale también ancho
	$Banner/CardBox.size.x = panel_width

	# 2) Espera a que el VBox calcule alturas con ese ancho
	await get_tree().process_frame

	var vbox: Control = $Banner/CardBox/VBox
	var h2: float = vbox.get_combined_minimum_size().y + padding.y
	h2 = max(h2, min_height)  # 👈 cuelga más
	size = Vector2(panel_width, h2)

	# 3) Fondo ocupa todo el panel
	$Banner.size = size
	$Banner.position = Vector2.ZERO

	var w := float(size.x)
	var h := float(size.y)

	var x := float(card.global_position.x) - w + float(offset.x)
	var y := float(card.global_position.y) + (float(card.size.y) - h) * 0.5 + 80

	global_position = Vector2(x, y)

	_slide_in()

func schedule_hide(delay := 0.06) -> void:
	_cancel_hide()
	var token := _show_token

	_hide_timer = get_tree().create_timer(delay)
	_hide_timer.timeout.connect(func():
		# ❗ si desde que se programó el hide se ha vuelto a mostrar, ignóralo
		if token != _show_token:
			return
		if _hover_panel:
			return
		if not _showing:
			return

		_slide_out()
		_showing = false
	)

func request_hide() -> void:
	schedule_hide(0.06)

func _cancel_hide() -> void:
	_hide_timer = null  # (no se puede matar, pero el token lo invalida)

func _slide_in() -> void:
	if _tw and _tw.is_running(): _tw.kill()

	# entra desde la izquierda/derecha (como prefieras)
	var start_x := position.x - 15
	position.x = start_x

	_tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tw.tween_property(self, "position:x", start_x + 15, anim_time)

func _slide_out() -> void:
	if _tw and _tw.is_running(): _tw.kill()
	_tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tw.tween_property(self, "position:x", position.x - 15, anim_time)
	_tw.tween_callback(func(): visible = false)
