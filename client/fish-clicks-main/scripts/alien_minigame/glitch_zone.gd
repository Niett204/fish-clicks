extends Area2D
class_name GlitchZone

@export var warning_time: float = 0.9
@export var active_time: float = 2.6
@export var blink_interval: float = 0.10
@export var damage_tick_interval: float = 0.35

@export var square_glitch_textures: Array[Texture2D] = []
@export var rectangular_glitch_textures: Array[Texture2D] = []
@export var glitch_sprite_count: int = 1
@export var min_glitch_scale: float = 0.18
@export var max_glitch_scale: float = 0.42

@onready var visual_root: Node2D = $VisualRoot
@onready var warning_rect: ColorRect = $WarningRect
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var main_ref: Node2D = null
var zone_size: Vector2 = Vector2.ZERO
var player_inside: bool = false
var is_active_zone: bool = false
var glitch_sprite: Sprite2D = null
var idle_glitch_time: float = 0.0
var idle_glitch_base_scale: Vector2 = Vector2.ONE
var idle_glitch_base_rotation: float = 0.0
var glitch_jitter_timer: float = 0.0
var glitch_flicker_timer: float = 0.0
var glitch_hold_offset: Vector2 = Vector2.ZERO
var glitch_hold_scale: Vector2 = Vector2.ONE
var glitch_hold_rotation: float = 0.0

func setup(main_owner: Node2D, size: Vector2) -> void:
	main_ref = main_owner
	zone_size = size

	top_level = true
	z_as_relative = false
	z_index = 20

	warning_rect.z_as_relative = false
	warning_rect.z_index = 20

	visual_root.z_as_relative = false
	visual_root.z_index = 21
	
	var shape := RectangleShape2D.new()
	shape.size = size
	collision_shape.shape = shape

	warning_rect.size = size
	warning_rect.position = -size * 0.5
	warning_rect.color = Color(1.0, 0.2, 0.2, 0.20)
	warning_rect.visible = false
	warning_rect.scale = Vector2.ONE
	warning_rect.rotation = 0.0
	warning_rect.modulate = Color(1, 1, 1, 1)

	visual_root.scale = Vector2.ONE
	visual_root.position = Vector2.ZERO
	visual_root.rotation = 0.0
	visual_root.modulate = Color(1, 1, 1, 1)

	monitoring = true
	monitorable = true
	collision_shape.disabled = true

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	if not area_exited.is_connected(_on_area_exited):
		area_exited.connect(_on_area_exited)

	call_deferred("_run_zone_sequence")


func _on_area_entered(area: Area2D) -> void:
	if area == null or not is_instance_valid(area):
		return

	if not is_active_zone:
		return

	if main_ref != null and area == main_ref.player:
		player_inside = true


func _on_area_exited(area: Area2D) -> void:
	if area == null or not is_instance_valid(area):
		return

	if not is_active_zone:
		return

	if main_ref != null and area == main_ref.player:
		player_inside = false


func _run_zone_sequence() -> void:
	# WARNING
	var elapsed: float = 0.0
	var visible_state: bool = true

	while elapsed < warning_time:
		visible_state = not visible_state
		warning_rect.visible = visible_state
		await get_tree().create_timer(blink_interval).timeout
		elapsed += blink_interval

	# ACTIVE
	player_inside = false
	warning_rect.visible = false
	collision_shape.disabled = false
	is_active_zone = true

	# Si el jugador ya estaba dentro cuando se activó la zona,
	# lo detectamos aquí manualmente
	if main_ref != null and is_instance_valid(main_ref) and main_ref.player != null:
		var player_pos: Vector2 = main_ref.player.global_position
		var half_size: Vector2 = zone_size * 0.5

		if (
			player_pos.x >= global_position.x - half_size.x
			and player_pos.x <= global_position.x + half_size.x
			and player_pos.y >= global_position.y - half_size.y
			and player_pos.y <= global_position.y + half_size.y
		):
			player_inside = true

	_generate_glitch_visuals()
	await _play_glitch_spawn_effect()

	var active_elapsed: float = 0.0
	var tick_elapsed: float = 0.0
	var pulse_time: float = 0.0

	while active_elapsed < active_time:
		await get_tree().create_timer(0.05).timeout
		active_elapsed += 0.05
		tick_elapsed += 0.05
		pulse_time += 0.05

		_update_active_glitch_visual(0.05)

		if player_inside and tick_elapsed >= damage_tick_interval:
			tick_elapsed = 0.0
			if main_ref != null and is_instance_valid(main_ref):
				main_ref.take_damage(1)

	collision_shape.disabled = true
	is_active_zone = false
	player_inside = false

	await _play_glitch_despawn_effect()
	queue_free()

func _generate_glitch_visuals() -> void:
	for child in visual_root.get_children():
		child.queue_free()

	glitch_sprite = null

	var aspect_ratio: float = zone_size.x / max(zone_size.y, 1.0)
	var use_square: bool = abs(aspect_ratio - 1.0) <= 0.22

	var chosen_pool: Array[Texture2D] = square_glitch_textures if use_square else rectangular_glitch_textures

	# Fallback por si el pool elegido está vacío
	if chosen_pool.is_empty():
		chosen_pool = square_glitch_textures if not square_glitch_textures.is_empty() else rectangular_glitch_textures

	if chosen_pool.is_empty():
		return

	var tex: Texture2D = chosen_pool[randi() % chosen_pool.size()]
	if tex == null:
		return

	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = true

	var tex_size: Vector2 = tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return

	var overscale: float = 1.25

	var scale_x: float = (zone_size.x / tex_size.x) * overscale
	var scale_y: float = (zone_size.y / tex_size.y) * overscale

	sprite.scale = Vector2(scale_x, scale_y)
	sprite.position = Vector2.ZERO
	sprite.rotation = randf_range(-0.03, 0.03)

	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = mat

	visual_root.add_child(sprite)

	glitch_sprite = sprite
	idle_glitch_base_scale = sprite.scale
	idle_glitch_base_rotation = sprite.rotation
	idle_glitch_time = randf() * 10.0
	glitch_jitter_timer = 0.0
	glitch_flicker_timer = 0.0
	glitch_hold_offset = Vector2.ZERO
	glitch_hold_scale = Vector2.ONE
	glitch_hold_rotation = 0.0
	
func _play_glitch_spawn_effect() -> void:
	if visual_root == null or not is_instance_valid(visual_root):
		return

	warning_rect.visible = false
	warning_rect.scale = Vector2.ONE
	warning_rect.rotation = 0.0
	warning_rect.position = -zone_size * 0.5

	visual_root.visible = true
	visual_root.scale = Vector2(0.58, 1.42)
	visual_root.rotation = randf_range(-0.12, 0.12)
	visual_root.modulate = Color(1, 1, 1, 0.0)
	visual_root.position = Vector2(
		randf_range(-26.0, 26.0),
		randf_range(-12.0, 12.0)
	)

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(visual_root, "scale", Vector2(1.16, 0.86), 0.08)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(visual_root, "position", Vector2.ZERO, 0.12)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(visual_root, "rotation", 0.0, 0.10)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(visual_root, "modulate:a", 1.0, 0.06)\
		.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(0.03).timeout

	for i in range(6):
		if not is_instance_valid(visual_root):
			break

		visual_root.visible = not visual_root.visible

		if visual_root.visible:
			visual_root.position = Vector2(
				randf_range(-20.0, 20.0),
				randf_range(-8.0, 8.0)
			)
			visual_root.scale = Vector2(
				randf_range(0.90, 1.22),
				randf_range(0.82, 1.20)
			)
			visual_root.rotation = randf_range(-0.08, 0.08)

		await get_tree().create_timer(0.022).timeout

	if is_instance_valid(visual_root):
		visual_root.visible = true

	for i in range(5):
		if not is_instance_valid(visual_root):
			break

		visual_root.position = Vector2(
			randf_range(-14.0, 14.0),
			randf_range(-4.0, 4.0)
		)

		await get_tree().create_timer(0.018).timeout

	if is_instance_valid(visual_root):
		var t_end := create_tween()
		t_end.set_parallel(true)
		t_end.tween_property(visual_root, "scale", Vector2(0.94, 1.06), 0.05)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t_end.tween_property(visual_root, "position", Vector2.ZERO, 0.06)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		await t_end.finished

		var t_settle := create_tween()
		t_settle.set_parallel(true)
		t_settle.tween_property(visual_root, "scale", Vector2.ONE, 0.08)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t_settle.tween_property(visual_root, "rotation", 0.0, 0.08)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		await t_settle.finished

	if is_instance_valid(visual_root):
		visual_root.position = Vector2.ZERO
		visual_root.scale = Vector2.ONE
		visual_root.rotation = 0.0
		visual_root.modulate.a = 1.0
		
func _play_glitch_despawn_effect() -> void:
	warning_rect.visible = false

	if visual_root == null or not is_instance_valid(visual_root):
		return

	for i in range(5):
		visual_root.visible = not visual_root.visible
		visual_root.position = Vector2(
			randf_range(-18.0, 18.0),
			randf_range(-8.0, 8.0)
		)
		visual_root.rotation = randf_range(-0.08, 0.08)

		await get_tree().create_timer(0.025).timeout

	visual_root.visible = true

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(visual_root, "scale", Vector2(1.35, 0.45), 0.08)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(visual_root, "modulate:a", 0.0, 0.10)\
		.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	t.tween_property(visual_root, "position", Vector2(
		randf_range(-24.0, 24.0),
		randf_range(-10.0, 10.0)
	), 0.08)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(visual_root, "rotation", randf_range(-0.14, 0.14), 0.08)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await t.finished

	if is_instance_valid(visual_root):
		visual_root.visible = false
		visual_root.scale = Vector2.ONE
		visual_root.rotation = 0.0
		visual_root.position = Vector2.ZERO
		visual_root.modulate = Color(1, 1, 1, 1)
		
func _update_active_glitch_visual(delta: float) -> void:
	if not is_active_zone:
		return

	if glitch_sprite == null or not is_instance_valid(glitch_sprite):
		return

	idle_glitch_time += delta
	glitch_jitter_timer -= delta
	glitch_flicker_timer -= delta

	# Cada poco, pega un "salto digital" y lo mantiene un instante
	if glitch_jitter_timer <= 0.0:
		glitch_jitter_timer = randf_range(0.035, 0.09)

		glitch_hold_offset = Vector2(
			randf_range(-10.0, 10.0),
			randf_range(-4.0, 4.0)
		)

		glitch_hold_scale = Vector2(
			randf_range(0.94, 1.08),
			randf_range(0.92, 1.10)
		)

		glitch_hold_rotation = randf_range(-0.03, 0.03)

	# Flicker irregular de visibilidad, pero corto para que no desaparezca demasiado
	if glitch_flicker_timer <= 0.0:
		glitch_flicker_timer = randf_range(0.04, 0.12)

		if randf() < 0.22:
			glitch_sprite.visible = false
		else:
			glitch_sprite.visible = true

	if not glitch_sprite.visible:
		return

	# Base casi estable, con pequeños tirones, no una animación suave
	glitch_sprite.position = glitch_hold_offset
	glitch_sprite.scale = Vector2(
		idle_glitch_base_scale.x * glitch_hold_scale.x,
		idle_glitch_base_scale.y * glitch_hold_scale.y
	)
	glitch_sprite.rotation = idle_glitch_base_rotation + glitch_hold_rotation

	# A veces pega una deformación extra muy corta, tipo fallo digital
	if randf() < 0.10:
		glitch_sprite.scale *= Vector2(
			randf_range(0.96, 1.04),
			randf_range(0.88, 1.12)
		)

	if randf() < 0.08:
		glitch_sprite.position += Vector2(
			randf_range(-14.0, 14.0),
			0.0
		)
	
	if visual_root != null and is_instance_valid(visual_root):
		if randf() < 0.12:
			visual_root.position = Vector2(
				randf_range(-3.0, 3.0),
				randf_range(-1.5, 1.5)
			)
		else:
			visual_root.position = Vector2.ZERO


func play_visual_burst(main_owner: Node2D, size: Vector2, lifetime: float = 0.32) -> void:
	main_ref = main_owner
	zone_size = size

	var saved_global_pos: Vector2 = global_position

	top_level = true
	global_position = saved_global_pos
	z_as_relative = false
	z_index = 30

	warning_rect.visible = false
	warning_rect.modulate = Color(1, 1, 1, 1)
	warning_rect.scale = Vector2.ONE
	warning_rect.rotation = 0.0

	visual_root.z_as_relative = false
	visual_root.z_index = 31
	visual_root.scale = Vector2.ONE
	visual_root.position = Vector2.ZERO
	visual_root.rotation = 0.0
	visual_root.modulate = Color(1, 1, 1, 1)

	monitoring = false
	monitorable = false
	collision_shape.disabled = true
	is_active_zone = false
	player_inside = false

	var shape := RectangleShape2D.new()
	shape.size = size
	collision_shape.shape = shape

	warning_rect.size = size
	warning_rect.position = -size * 0.5

	_generate_glitch_visuals()
	call_deferred("_run_visual_burst_only", lifetime)
	

func _run_visual_burst_only(lifetime: float) -> void:
	await _play_glitch_spawn_effect()

	var elapsed: float = 0.0
	while elapsed < lifetime:
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05
		_update_active_glitch_visual(0.05)

	await _play_glitch_despawn_effect()
	queue_free()
