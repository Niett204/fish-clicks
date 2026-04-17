extends Panel

signal bottle_clicked

var original_pos: Vector2

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	original_pos = position

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_bottle_clicked()

func _on_bottle_clicked() -> void:
	bottle_clicked.emit()
	_play_shake()

func _play_shake() -> void:
	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# pequeña sacudida lateral
	t.tween_property(self, "position", original_pos + Vector2(-4, 0), 0.04)
	t.tween_property(self, "position", original_pos + Vector2(4, 0), 0.04)
	t.tween_property(self, "position", original_pos + Vector2(-2, 0), 0.03)
	t.tween_property(self, "position", original_pos, 0.03)
