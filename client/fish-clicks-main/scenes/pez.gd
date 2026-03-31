extends Node2D

enum FishState { WANDER, SCARED }
var state: FishState = FishState.WANDER

@onready var spawn_bubbles: CPUParticles2D = $SpawnBubbles
@onready var splash_particles: CPUParticles2D = $SplashParticles
@onready var shiny_particles: CPUParticles2D = $ShinyParticles
@onready var bubble_player: AudioStreamPlayer2D = $BubblePlayer
@onready var splash_player: AudioStreamPlayer2D = $SplashPlayer

@export var speed := 70.0
@export var steer := 4.5
@export var target_reached_dist := 20.0

# IMPORTANTE: este rect en coordenadas GLOBALES (mundo)
@export var swim_area: Node2D
var swim_rect: Rect2

var target: Vector2
var vel: Vector2 = Vector2.ZERO
var state_timer := 0.0

var fish_id: String = ""
var habitat_id: String = ""
var slot_index: int = -1
var is_spawning: bool = false
var spawn_blend_time: float = 0.0
var spawn_blend_duration: float = 0.7
var spawn_exit_dir: Vector2 = Vector2.ZERO
var spawn_bubble_base_offset: float = 8.0
var spawn_bubble_side_phase: float = 0.0
var spawn_splash_played: bool = false
var shiny_sparkle_timer: float = 0.0

@onready var spr: Sprite2D = $Sprite2D

func _ready():
	randomize()
	_update_swim_rect()
	_pick_new_target()
	_setup_shiny_particles()
	shiny_sparkle_timer = randf_range(1.8, 4.0)

func _process(delta):
	if _is_current_fish_shiny() and not is_spawning:
		shiny_sparkle_timer -= delta
		if shiny_sparkle_timer <= 0.0:
			_emit_shiny_sparkle_cluster()
			shiny_sparkle_timer = randf_range(2.2, 4.8)

	if is_spawning:
		return
	
	match state:
		FishState.WANDER:
			_wander_step(delta)

		FishState.SCARED:
			_scared_step(delta)

func _emit_single_shiny_sparkle() -> void:
	if not _is_current_fish_shiny() or shiny_particles == null or spr == null:
		return

	var tex_size: Vector2 = Vector2(32.0, 32.0)
	if spr.texture:
		tex_size = spr.texture.get_size()

	var visual_scale: Vector2 = _get_visual_scale()

	var width: float = tex_size.x * visual_scale.x
	var height: float = tex_size.y * visual_scale.y

	var local_x: float = randf_range(-width * 0.38, width * 0.38)
	var local_y: float = randf_range(-height * 0.32, height * 0.32)

	shiny_particles.position = Vector2(local_x, local_y)
	shiny_particles.amount = randi_range(1, 2)
	shiny_particles.restart()
	shiny_particles.emitting = true
	
func _emit_shiny_sparkle_cluster() -> void:
	if not _is_current_fish_shiny():
		return

	var burst_count: int = randi_range(2, 3)

	for i in range(burst_count):
		_emit_single_shiny_sparkle()

		if i < burst_count - 1:
			await get_tree().create_timer(randf_range(0.14, 0.24)).timeout
	
func _wander_step(delta: float) -> void:
	global_position = _clamp_to_rect(global_position, swim_rect)

	var desired: Vector2 = target - global_position
	if desired.length() < target_reached_dist:
		_pick_new_target()
		desired = target - global_position

	if desired.length() <= 0.001:
		return

	var target_dir: Vector2 = desired.normalized()

	# durante un ratito tras el spawn, mezclamos la salida del spawn
	# con la dirección normal del wander
	if spawn_blend_time > 0.0:
		var blend_t: float = 1.0 - (spawn_blend_time / spawn_blend_duration)
		var blended_dir: Vector2 = spawn_exit_dir.lerp(target_dir, blend_t).normalized()
		desired = blended_dir * speed
		spawn_blend_time = maxf(0.0, spawn_blend_time - delta)
	else:
		desired = target_dir * speed

	vel = vel.lerp(desired, 1.0 - exp(-steer * delta))
	global_position += vel * delta

	_update_flip()

func _pick_new_target() -> void:
	target = Vector2(
		randf_range(swim_rect.position.x, swim_rect.position.x + swim_rect.size.x),
		randf_range(swim_rect.position.y, swim_rect.position.y + swim_rect.size.y)
	)

func scare_from(point: Vector2) -> void:
	var dir = (global_position - point).normalized()
	vel = dir * speed * 3.0
	state = FishState.SCARED
	state_timer = 0.7

	if bubble_player:
		bubble_player.stop()
		bubble_player.play()

func _scared_step(delta: float) -> void:
	state_timer -= delta

	var next_pos = global_position + vel * delta

	# Rebote con los límites
	var minx = swim_rect.position.x
	var maxx = swim_rect.position.x + swim_rect.size.x
	var miny = swim_rect.position.y
	var maxy = swim_rect.position.y + swim_rect.size.y

	if next_pos.x < minx or next_pos.x > maxx:
		vel.x *= -1
	if next_pos.y < miny or next_pos.y > maxy:
		vel.y *= -1

	global_position += vel * delta
	vel = vel.move_toward(Vector2.ZERO, 250 * delta) # frena

	_update_flip()

	if state_timer <= 0:
		state = FishState.WANDER
		_pick_new_target()

func _update_flip() -> void:
	if vel.length() <= 0.001:
		return

	spr.flip_h = vel.x > 0

	if spawn_bubbles:
		spawn_bubbles.position.x = -8 if spr.flip_h else 8

	var target_rot: float = clamp(vel.y / maxf(speed, 0.001) * 0.22, -0.22, 0.22)
	rotation = lerp_angle(rotation, target_rot, 0.08)

func _clamp_to_rect(p: Vector2, r: Rect2) -> Vector2:
	return Vector2(
		clamp(p.x, r.position.x, r.position.x + r.size.x),
		clamp(p.y, r.position.y, r.position.y + r.size.y)
	)

func _get_water_surface_y() -> float:
	return swim_rect.position.y - 60.0

func _update_swim_rect() -> void:
	# IMPORTANTE: usamos el CollisionShape2D, porque puede tener offset propio
	var cs := swim_area.get_node("CollisionShape2D") as CollisionShape2D
	var rs := cs.shape as RectangleShape2D
	if rs == null:
		push_error("SwimArea CollisionShape2D no tiene RectangleShape2D")
		return

	# Centro global real del rect
	var center := cs.global_position

	# Tamaño teniendo en cuenta el scale (por si escalaste el SwimArea)
	var size := rs.size * cs.global_scale

	var top_left := center - size * 0.5
	swim_rect = Rect2(top_left, size)

func setup_fish_instance(
	new_fish_id: String,
	new_habitat_id: String,
	new_slot_index: int
) -> void:
	fish_id = new_fish_id
	habitat_id = new_habitat_id
	slot_index = new_slot_index

	_apply_shiny_visuals()

func _is_current_fish_shiny() -> bool:
	return fish_id.ends_with("_shiny")

func _apply_shiny_visuals() -> void:
	if spr == null:
		return

	if _is_current_fish_shiny():
		spr.modulate = Color(1.10, 1.05, 0.92, 1.0)
		spr.self_modulate = Color.WHITE
	else:
		spr.modulate = Color.WHITE
		spr.self_modulate = Color.WHITE

	if shiny_particles:
		shiny_particles.emitting = false

func _setup_shiny_particles() -> void:
	if shiny_particles == null:
		return

	shiny_particles.emitting = false
	shiny_particles.amount = 2
	shiny_particles.lifetime = 2
	shiny_particles.one_shot = true
	shiny_particles.explosiveness = 1.0
	shiny_particles.randomness = 0.15
	shiny_particles.speed_scale = 1.0
	shiny_particles.direction = Vector2(0, -1)
	shiny_particles.spread = 220.0
	shiny_particles.gravity = Vector2.ZERO
	shiny_particles.initial_velocity_min = 8.0
	shiny_particles.initial_velocity_max = 18.0
	shiny_particles.scale_amount_min = 0.004
	shiny_particles.scale_amount_max = 0.012
	shiny_particles.position = Vector2.ZERO

	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.0))
	scale_curve.add_point(Vector2(0.12, 0.20))
	scale_curve.add_point(Vector2(0.45, 1.0))
	scale_curve.add_point(Vector2(1.0, 0.0))
	shiny_particles.scale_amount_curve = scale_curve

func set_fish_texture(texture_to_use: Texture2D) -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D")
	if sprite == null:
		push_error("No se encontró Sprite2D en el pez")
		return

	sprite.texture = texture_to_use
	_apply_shiny_visuals()
	
func play_spawn_arc(target_pos: Vector2) -> void:
	
	is_spawning = true
	spawn_splash_played = false
	_update_swim_rect()

	if spawn_bubbles:
		spawn_bubbles.emitting = false
		spawn_bubbles.amount = 10
		spawn_bubbles.initial_velocity_min = 10.0
		spawn_bubbles.initial_velocity_max = 18.0
		spawn_bubbles.scale_amount_min = 0.004
		spawn_bubbles.scale_amount_max = 0.010
		spawn_bubbles.spread = 24.0
		spawn_bubbles.direction = Vector2(0, -1)
		spawn_bubbles.gravity = Vector2(0, -6)
		spawn_bubbles.restart()
		spawn_bubbles.emitting = true

	var spawn_margin_top: float = 95.0
	var top_y: float = swim_rect.position.y - spawn_margin_top
	var spawn_x: float = clampf(
		target_pos.x + randf_range(-120.0, 120.0),
		swim_rect.position.x + 24.0,
		swim_rect.position.x + swim_rect.size.x - 24.0
	)

	var start_pos: Vector2 = Vector2(spawn_x, top_y)

	var curve_side: float = randf_range(-1.0, 1.0)
	if abs(curve_side) < 0.2:
		curve_side = 1.0 if randf() < 0.5 else -1.0

	var control_pos_1: Vector2 = Vector2(
		start_pos.x + curve_side * randf_range(100.0, 180.0),
		lerp(start_pos.y, target_pos.y, 0.18)
	)

	var control_pos_2: Vector2 = Vector2(
		target_pos.x - curve_side * randf_range(110.0, 190.0),
		lerp(start_pos.y, target_pos.y, 0.78)
	)

	var preview_end_dir: Vector2 = (target_pos - control_pos_2).normalized()
	if preview_end_dir.length() <= 0.001:
		preview_end_dir = Vector2.DOWN

	var curve_end_pos: Vector2 = _clamp_to_rect(
		target_pos + preview_end_dir * randf_range(14.0, 28.0),
		swim_rect
	)

	global_position = start_pos
	spr.scale = Vector2(0.03, 0.03)
	modulate.a = 0.0
	rotation = 0.0

	var duration: float = randf_range(1.40, 1.65)

	var water_surface_y: float = _get_water_surface_y()
	var previous_pos: Vector2 = start_pos
	var last_dir: Vector2 = Vector2.DOWN

	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)

	tween.tween_method(
	func(t: float) -> void:
		var pos: Vector2 = _cubic_bezier(start_pos, control_pos_1, control_pos_2, curve_end_pos, t)
		global_position = pos

		var next_t: float = minf(t + 0.015, 1.0)
		var next_pos: Vector2 = _cubic_bezier(start_pos, control_pos_1, control_pos_2, curve_end_pos, next_t)
		var dir: Vector2 = (next_pos - pos).normalized()

		if dir.length() > 0.001:
			@warning_ignore("confusable_capture_reassignment")
			last_dir = dir
			spr.flip_h = dir.x > 0
			var target_rot: float = clamp(dir.y * 0.32, -0.32, 0.32)
			rotation = lerp_angle(rotation, target_rot, 0.22)

		if not spawn_splash_played:
			var crossed_surface: bool = previous_pos.y < water_surface_y and pos.y >= water_surface_y
			if crossed_surface:
				var cross_t: float = inverse_lerp(previous_pos.y, pos.y, water_surface_y)
				var splash_x: float = lerpf(previous_pos.x, pos.x, cross_t)
				var splash_pos: Vector2 = Vector2(splash_x, water_surface_y - 2.0)

				_play_water_splash_at(splash_pos, last_dir)
				spawn_splash_played = true

		@warning_ignore("confusable_capture_reassignment")
		previous_pos = pos

		if spawn_bubbles:
			spawn_bubbles.initial_velocity_min = lerpf(10.0, 20.0, t)
			spawn_bubbles.initial_velocity_max = lerpf(18.0, 30.0, t)
			spawn_bubbles.scale_amount_min = lerpf(0.010, 0.004, t)
			spawn_bubbles.scale_amount_max = lerpf(0.018, 0.008, t),
		0.0,
		1.0,
		duration
	)

	var fx: Tween = create_tween()
	fx.set_parallel(true)
	fx.tween_property(spr, "scale", _get_visual_scale(), 0.30)
	fx.tween_property(self, "modulate:a", 1.0, 0.22)

	await tween.finished
	
	global_position = curve_end_pos
	spr.scale = _get_visual_scale()
	rotation = clamp(rotation * 0.35, -0.08, 0.08)

	var exit_dir: Vector2 = last_dir.normalized()
	if abs(exit_dir.x) < 0.15:
		exit_dir.x = 0.15 * signf(randf_range(-1.0, 1.0) if exit_dir.x == 0.0 else exit_dir.x)

	exit_dir.y *= 0.10
	exit_dir = exit_dir.normalized()

	vel = exit_dir * speed * 1.15
	rotation = clamp(exit_dir.y * 0.18, -0.18, 0.18)

	target = _get_forward_target(exit_dir)
	spawn_exit_dir = exit_dir
	spawn_blend_time = spawn_blend_duration

	if spawn_bubbles:
		await get_tree().create_timer(0.16).timeout
		spawn_bubbles.emitting = false

	is_spawning = false

func _get_forward_target(dir: Vector2) -> Vector2:
	var horizontal_dir: Vector2 = dir.normalized()

	if abs(horizontal_dir.x) < 0.2:
		horizontal_dir.x = 0.2 * signf(randf_range(-1.0, 1.0) if horizontal_dir.x == 0.0 else horizontal_dir.x)

	horizontal_dir.y *= 0.25
	horizontal_dir = horizontal_dir.normalized()

	var forward_dist: float = randf_range(80.0, 150.0)
	var side_offset: float = randf_range(-20.0, 20.0)

	var side: Vector2 = Vector2(-horizontal_dir.y, horizontal_dir.x)
	var candidate: Vector2 = global_position + horizontal_dir * forward_dist + side * side_offset

	return _clamp_to_rect(candidate, swim_rect)
	
func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u: float = 1.0 - t
	return (
		u * u * u * p0 +
		3.0 * u * u * t * p1 +
		3.0 * u * t * t * p2 +
		t * t * t * p3
	)

func _play_water_splash_at(impact_pos: Vector2, impact_dir: Vector2) -> void:

	# Sonido entrada 
	if splash_player:
		splash_player.global_position = impact_pos
		splash_player.stop()
		splash_player.play()
		
	if splash_particles == null:
		return

	var dir: Vector2 = impact_dir.normalized()
	if dir.length() <= 0.001:
		dir = Vector2.DOWN

	var vertical_strength: float = clampf(abs(dir.y), 0.35, 1.0)

	# un pelín por encima de la superficie visual
	splash_particles.global_position = impact_pos + Vector2(0, -4.0)

	splash_particles.emitting = false

	# menos "explosión", más salpicadura corta y abierta
	splash_particles.amount = int(lerpf(6.0, 10.0, vertical_strength))
	splash_particles.lifetime = 0.55
	splash_particles.one_shot = true
	splash_particles.explosiveness = 0.55
	splash_particles.randomness = 0.18

	splash_particles.initial_velocity_min = lerpf(10.0, 16.0, vertical_strength)
	splash_particles.initial_velocity_max = lerpf(18.0, 26.0, vertical_strength)

	splash_particles.scale_amount_min = 0.010
	splash_particles.scale_amount_max = 0.018

	# más lateral y menos "bomba"
	splash_particles.direction = Vector2(0, -1)
	splash_particles.spread = 70.0
	splash_particles.gravity = Vector2(0, 36.0)

	splash_particles.restart()
	splash_particles.emitting = true

func _get_visual_scale() -> Vector2:
	return Vector2(0.125, 0.125) * (1.06 if _is_current_fish_shiny() else 1.0)
