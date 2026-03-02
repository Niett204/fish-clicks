extends Control

@export var anim_time := 0.18
@export var offset := Vector2(20, 0)

var _tw: Tween
var _hover_panel := false
var _showing := false

var _hide_timer: SceneTreeTimer
var _show_token := 0  # sube cada vez que se muestra (anti hides viejos)

func _ready() -> void:
	set_as_top_level(true)
	z_index = 100
	visible = false

	mouse_entered.connect(func():
		_hover_panel = true
		_cancel_hide()
	)

	mouse_exited.connect(func():
		_hover_panel = false
		schedule_hide(0.06)
	)

func show_for_card(card: Control, title: String, desc: String, stats: String) -> void:
	_show_token += 1
	_cancel_hide()

	$CardBox/VBox/Title.text = title
	$CardBox/VBox/Desc.text = desc
	$CardBox/VBox/Stats.text = stats

	visible = true
	_showing = true

	# asegúrate de que size esté calculado
	await get_tree().process_frame

	var x := card.global_position.x - size.x - offset.x
	var y := card.global_position.y + (card.size.y - size.y) * 0.5
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
