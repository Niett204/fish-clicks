extends Control

signal popup_finished

@onready var panel: PanelContainer = $PanelContainer
@onready var label_title: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer2/VBoxContainer/LabelTitle
@onready var label_desc: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer2/VBoxContainer/LabelDesc
@onready var icon: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/Icon
@onready var btn_close: TextureButton = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer2/TextureButton

var _tween: Tween
var _is_closing := false

func _ready() -> void:
	modulate.a = 0.0
	scale = Vector2(0.92, 0.92)

	mouse_filter = Control.MOUSE_FILTER_PASS

	btn_close.modulate = Color("#c47a3a")
	btn_close.pressed.connect(_on_close_pressed)

func setup_popup(title: String, desc: String, tex: Texture2D = null) -> void:
	label_title.text = title
	label_desc.text = desc

	if tex != null:
		icon.texture = tex

func show_popup(duration: float = 2.5) -> void:
	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_BACK)
	_tween.set_ease(Tween.EASE_OUT)

	_tween.tween_property(self, "modulate:a", 1.0, 0.18)
	_tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.22)

	_tween.tween_interval(duration)

	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, 0.22)
	_tween.parallel().tween_property(self, "position:y", position.y - 12.0, 0.22)

	_tween.finished.connect(_finish_popup)

func _on_close_pressed() -> void:
	if _is_closing:
		return

	_is_closing = true

	if _tween:
		_tween.kill()

	var t = create_tween()
	t.set_trans(Tween.TRANS_QUAD)
	t.set_ease(Tween.EASE_IN)

	t.tween_property(self, "modulate:a", 0.0, 0.2)
	t.parallel().tween_property(self, "scale", Vector2(0.9, 0.9), 0.2)

	t.finished.connect(_finish_popup)

func _finish_popup() -> void:
	popup_finished.emit()
	queue_free()
