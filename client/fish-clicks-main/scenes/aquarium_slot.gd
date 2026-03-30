extends Control

signal pressed_slot(slot_index: int, fish_id: String)

@onready var slot_bg: TextureRect = $SlotBg
@onready var fish_icon: TextureRect = $MarginContainer/FishIcon
@onready var sparkle_layer: Control = $SparkleLayer

var my_slot_index: int = -1
var my_fish_id: String = ""
var _pulse_t := 0.0
var _is_pulsing := false
var _is_hovered := false
var _is_drag_hovered := false
var _is_shiny := false
var _sparkle_timer := 0.0
var max_alpha := randf_range(0.75, 1.0)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	slot_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fish_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	_is_hovered = true
	_update_visual_state()

func _on_mouse_exited() -> void:
	_is_hovered = false
	_is_drag_hovered = false
	_update_visual_state()

func set_hover_drop_feedback(active: bool) -> void:
	_is_drag_hovered = active
	_update_visual_state()

func _update_visual_state() -> void:
	var target_scale := Vector2.ONE
	var target_modulate := Color(1, 1, 1, 1)

	if _is_drag_hovered:
		target_scale = Vector2(1.08, 1.08)
		target_modulate = Color(1.08, 1.08, 1.08, 1)
	elif _is_hovered:
		target_scale = Vector2(1.04, 1.04)
		target_modulate = Color(1.04, 1.04, 1.04, 1)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", target_scale, 0.08)
	tween.parallel().tween_property(self, "modulate", target_modulate, 0.08)

func _process(delta: float) -> void:
	if _is_pulsing:
		_pulse_t += delta * 4.0
		var a := 0.18 + (sin(_pulse_t) * 0.5 + 0.5) * 0.12
		slot_bg.modulate.a = a

	if _is_shiny:
		_sparkle_timer -= delta
		if _sparkle_timer <= 0.0:
			var sparkle_count := randi_range(2, 3)
			for i in range(sparkle_count):
				spawn_sparkle(randf_range(0.0, 0.22))

			_sparkle_timer = randf_range(2, 3)

func start_shiny_effect() -> void:
	_is_shiny = true
	_sparkle_timer = randf_range(0.1, 0.6)
	
func stop_shiny_effect() -> void:
	_is_shiny = false

	for c in sparkle_layer.get_children():
		c.queue_free()

func spawn_sparkle(delay: float = 0.0) -> void:
	var star := TextureRect.new()
	star.texture = preload("res://assets/misc/brillito.png")
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star.size = Vector2.ONE * randf_range(8.0, 14.0)
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star.z_index = 20

	sparkle_layer.add_child(star)

	star.position = Vector2(
		randf_range(6.0, max(6.0, fish_icon.size.x - 24.0)),
		randf_range(6.0, max(6.0, fish_icon.size.y - 24.0))
	)

	star.scale = Vector2.ZERO
	star.rotation = randf_range(-0.25, 0.25)
	star.modulate = Color(1, 1, 1, 0)

	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_OUT)

	if delay > 0.0:
		t.tween_interval(delay)

	t.parallel().tween_property(star, "scale", Vector2.ONE, 0.35)
	t.parallel().tween_property(star, "modulate:a", 1.0, 0.35)

	t.chain().tween_interval(0.8)

	t.parallel().tween_property(star, "scale", Vector2(0.3, 0.3), 0.4)
	t.parallel().tween_property(star, "modulate:a", 0.0, 0.4)

	t.finished.connect(star.queue_free)
	
func start_highlight() -> void:
	_is_pulsing = true
	slot_bg.visible = true

func stop_highlight() -> void:
	_is_pulsing = false
	slot_bg.visible = true
	slot_bg.modulate.a = 1.0
	_is_drag_hovered = false
	_update_visual_state()

func setup(fish_texture: Texture2D = null, slot_index: int = -1, fish_id: String = "") -> void:
	my_slot_index = slot_index
	my_fish_id = fish_id
	fish_icon.texture = fish_texture
	fish_icon.visible = fish_texture != null

	if fish_id.ends_with("_shiny"):
		fish_icon.self_modulate = Color(1.1, 1.1, 1.1)
		start_shiny_effect()
	else:
		fish_icon.self_modulate = Color(1, 1, 1, 1)
		stop_shiny_effect()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("slot rect:", get_global_rect(), " slot:", my_slot_index, " fish:", my_fish_id)
		if my_fish_id != "":
			pressed_slot.emit(my_slot_index, my_fish_id)
