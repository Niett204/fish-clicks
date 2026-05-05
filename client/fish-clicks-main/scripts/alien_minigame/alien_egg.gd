extends Area2D

class_name AlienEgg

enum EggState {
	DROPPED,
	MOVING_TO_NEST,
	INCUBATING,
	READY_TO_HATCH,
	HATCHING
}

@onready var spr: Sprite2D = $Sprite2D

var egg_manager: EggManager = null
var state: EggState = EggState.DROPPED

var incubation_total_time: float = 40.0
var incubation_elapsed: float = 0.0

var base_scale: Vector2 = Vector2.ONE
var pulse_time: float = 0.0
var aura_strength: float = 0.0
var ready_jump_cooldown: float = 0.0
var is_doing_ready_jump: bool = false

var spr_base_position: Vector2 = Vector2.ZERO
var ready_hop_active: bool = false
var ready_hop_timer: float = 0.0
var ready_hop_duration: float = 0.32
var ready_hop_height: float = 14.0

var aura_layers: Array[Sprite2D] = []
var aura_offsets: Array[Vector2] = [
	Vector2(-2, 0),
	Vector2(2, 0),
	Vector2(0, -2),
	Vector2(0, 2)
]

func _ready() -> void:
	input_pickable = true
	spr_base_position = spr.position
	base_scale = scale
	setup_aura()

func setup_egg(manager: EggManager) -> void:
	egg_manager = manager

func _process(delta: float) -> void:
	pulse_time += delta

	match state:
		EggState.DROPPED:
			_update_press_me_glow()
		EggState.INCUBATING:
			_process_incubation(delta)
		EggState.READY_TO_HATCH:
			_process_ready_to_hatch(delta)

	_update_aura_visual()

func _input_event(_viewport, event, _shape_idx) -> void:
	if not (event is InputEventMouseButton):
		return
	if not event.pressed:
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	match state:
		EggState.DROPPED:
			if egg_manager != null:
				egg_manager.on_egg_pressed_in_dropped_state(self)

		EggState.READY_TO_HATCH:
			if egg_manager != null:
				egg_manager.on_egg_pressed_ready_to_hatch(self)

func enter_dropped_state() -> void:
	state = EggState.DROPPED
	scale = base_scale
	rotation = 0.0
	aura_strength = 0.25

func enter_moving_to_nest_state() -> void:
	state = EggState.MOVING_TO_NEST
	scale = base_scale
	aura_strength = 0.0

func enter_incubating_state(total_time: float) -> void:
	state = EggState.INCUBATING
	incubation_total_time = total_time
	incubation_elapsed = 0.0
	scale = base_scale
	aura_strength = 0.15

func enter_hatching_state() -> void:
	state = EggState.HATCHING
	aura_strength = 0.0

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "scale", base_scale * Vector2(1.25, 0.72), 0.10)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "rotation", 0.18, 0.10)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	t.chain().tween_property(self, "scale", base_scale * Vector2(0.82, 1.18), 0.10)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.parallel().tween_property(self, "rotation", -0.16, 0.10)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	t.chain().tween_property(self, "scale", base_scale * Vector2(1.35, 0.55), 0.12)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(self, "modulate:a", 0.0, 0.18)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _process_incubation(delta: float) -> void:
	incubation_elapsed += delta
	var ratio := clampf(incubation_elapsed / maxf(incubation_total_time, 0.001), 0.0, 1.0)

	# aura cada vez más fuerte
	aura_strength = lerpf(0.12, 0.55, ratio)

	# wiggle ocasional cuando se acerca la eclosión
	if ratio > 0.20 and randf() < delta * lerpf(0.05, 0.80, ratio):
		_play_soft_wiggle(ratio)

	if ratio > 0.75:
		aura_strength = lerpf(0.35, 0.95, ratio)

	if ratio >= 1.0:
		state = EggState.READY_TO_HATCH
		aura_strength = 0.70
		if egg_manager != null:
			egg_manager.on_egg_ready_to_hatch(self)

func _process_ready_to_hatch(delta: float) -> void:
	aura_strength = 1.0
	ready_jump_cooldown -= delta

	if ready_hop_active:
		_process_ready_hop(delta)
		return

	var pulse := 1.0 + sin(Time.get_ticks_msec() / 160.0) * 0.035
	scale = base_scale * pulse
	spr.position = spr_base_position

	if ready_jump_cooldown <= 0.0:
		ready_jump_cooldown = randf_range(0.75, 1.35)
		_start_ready_hop()

func _start_ready_hop() -> void:
	ready_hop_active = true
	ready_hop_timer = 0.0


func _process_ready_hop(delta: float) -> void:
	ready_hop_timer += delta

	var t := clampf(ready_hop_timer / ready_hop_duration, 0.0, 1.0)
	var jump_y := -sin(t * PI) * ready_hop_height

	var hop_offset := Vector2(0.0, jump_y)
	spr.position = spr_base_position + hop_offset

	for aura in aura_layers:
		if aura != null and is_instance_valid(aura):
			aura.position += hop_offset

	var squash := sin(t * PI)
	scale = base_scale * Vector2(
		1.0 + squash * 0.04,
		1.0 - squash * 0.03
	)

	if t >= 1.0:
		ready_hop_active = false
		spr.position = spr_base_position
		scale = base_scale

func _play_soft_wiggle(ratio: float) -> void:
	if state != EggState.INCUBATING:
		return

	var rot := lerpf(0.05, 0.12, ratio)

	var t := create_tween()
	t.tween_property(self, "rotation", rot, 0.08)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "rotation", -rot * 0.85, 0.10)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, "rotation", 0.0, 0.08)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func setup_aura() -> void:
	if not aura_layers.is_empty():
		return

	for offset in aura_offsets:
		var aura := Sprite2D.new()
		aura.texture = spr.texture
		aura.centered = spr.centered
		aura.position = offset
		aura.z_as_relative = true
		aura.z_index = -1
		aura.visible = false
		aura.scale = spr.scale * 1.01
		aura.modulate = Color(0.18, 0.95, 0.35, 0.0)

		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		aura.material = mat

		add_child(aura)
		aura_layers.append(aura)

func _update_press_me_glow() -> void:
	var pulse := 1.0 + sin(Time.get_ticks_msec() / 180.0) * 0.06
	scale = base_scale * pulse

func _update_aura_visual() -> void:
	for i in range(aura_layers.size()):
		var aura := aura_layers[i]
		if aura == null or not is_instance_valid(aura):
			continue

		aura.texture = spr.texture

		if aura_strength <= 0.01:
			aura.visible = false
			continue

		aura.visible = true

		var pulse := 1.01 + sin((Time.get_ticks_msec() / 170.0) + i) * 0.025
		var alpha := aura_strength * (0.55 + sin((Time.get_ticks_msec() / 220.0) + i) * 0.08)
		var base_offset := aura_offsets[i]
		var extra := sin((Time.get_ticks_msec() / 160.0) + i) * 0.35

		aura.scale = spr.scale * pulse
		aura.modulate = Color(0.18, 0.95, 0.35, alpha)
		aura.position = spr.position + base_offset.normalized() * (3.2 + extra)

func get_save_state() -> Dictionary:
	return {
		"state": int(state),
		"position_x": global_position.x,
		"position_y": global_position.y,
		"rotation": rotation,
		"incubation_total_time": incubation_total_time,
		"incubation_elapsed": incubation_elapsed
	}

func apply_save_state(data: Dictionary) -> void:
	state = int(data.get("state", EggState.DROPPED))
	global_position = Vector2(
		float(data.get("position_x", global_position.x)),
		float(data.get("position_y", global_position.y))
	)
	rotation = float(data.get("rotation", 0.0))
	incubation_total_time = float(data.get("incubation_total_time", 40.0))
	incubation_elapsed = float(data.get("incubation_elapsed", 0.0))

	match state:
		EggState.DROPPED:
			enter_dropped_state()
		EggState.MOVING_TO_NEST:
			enter_dropped_state()
		EggState.INCUBATING:
			state = EggState.INCUBATING
			aura_strength = 0.15
		EggState.READY_TO_HATCH:
			state = EggState.READY_TO_HATCH
			aura_strength = 0.85
		EggState.HATCHING:
			enter_dropped_state()

func refresh_visual_state() -> void:
	match state:
		EggState.DROPPED:
			aura_strength = 0.0
			_set_aura_visible(false)

		EggState.MOVING_TO_NEST:
			aura_strength = 0.0
			_set_aura_visible(false)

		EggState.INCUBATING:
			aura_strength = 0.45
			_set_aura_visible(true)

		EggState.READY_TO_HATCH:
			aura_strength = 1.0
			_set_aura_visible(true)

		EggState.HATCHING:
			aura_strength = 1.0
			_set_aura_visible(true)

func _set_aura_visible(value: bool) -> void:
	for aura in aura_layers:
		if aura != null and is_instance_valid(aura):
			aura.visible = value
