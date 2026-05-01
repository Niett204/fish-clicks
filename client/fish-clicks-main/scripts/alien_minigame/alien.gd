extends Node2D

signal clicked

@onready var area_2d: Area2D = $Area2D
@onready var click_hint = $ClickHint
@onready var abduct_point: Marker2D = $AbductPoint
@onready var beam: Sprite2D = $Beam

var clickable: bool = false

func _ready() -> void:
	area_2d.input_pickable = true
	area_2d.input_event.connect(_on_area_input_event)
	click_hint.visible = false
	beam.visible = false
	beam.modulate.a = 0.0

func set_waiting_for_click(enabled: bool) -> void:
	clickable = enabled
	click_hint.visible = enabled

func get_abduct_target_position() -> Vector2:
	return abduct_point.global_position

func show_beam() -> void:
	beam.visible = true
	beam.modulate.a = 0.0
	beam.scale = Vector2(0.1, 0.3)

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(beam, "modulate:a", 1.0, 0.2)
	t.tween_property(beam, "scale", Vector2(0.48, .2), 0.2)

func hide_beam() -> void:
	var t := create_tween()
	t.tween_property(beam, "modulate:a", 0.0, 0.2)
	await t.finished
	beam.visible = false

func _on_area_input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if not clickable:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
