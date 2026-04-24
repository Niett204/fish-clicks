extends Area2D
class_name AlienWorm

@export var move_speed: float = 100.0
@export var steer_strength: float = 5.5
@export var idle_follow_speed: float = 8.0
@export var idle_offset: Vector2 = Vector2(720.0, 310.0)

@export var idle_float_amplitude: float = 4.0
@export var idle_float_speed: float = 1.8
@export var idle_rotation_amplitude: float = 0.05
@export var idle_rotation_speed: float = 1.4
@export var idle_squash_amplitude: float = 0.025
@export var idle_squash_speed: float = 2.0

var target: Node2D = null
var main_ref: Node2D = null
var host_alien: Node2D = null
var velocity: Vector2 = Vector2.ZERO

var is_active: bool = false
var is_releasing: bool = false
var release_target: Vector2 = Vector2.ZERO
var is_escaping: bool = false
var escape_direction: Vector2 = Vector2.ZERO
var walk_time: float = 0.0
var idle_time: float = 0.0
var base_scale: Vector2 = Vector2.ONE

func setup(target_ref: Node2D, owner_main: Node2D, alien_ref: Node2D) -> void:
	target = target_ref
	main_ref = owner_main
	host_alien = alien_ref

	add_to_group("enemy_attack")
	add_to_group("persistent_hazard")

	monitoring = false
	monitorable = false

	base_scale = scale

	if host_alien != null and is_instance_valid(host_alien):
		global_position = host_alien.global_position + idle_offset

func activate() -> void:
	if main_ref == null or not is_instance_valid(main_ref):
		is_active = true
		monitoring = true
		monitorable = true
		velocity = Vector2.ZERO
		return

	is_releasing = true
	is_active = false
	monitoring = false
	monitorable = false
	velocity = Vector2.ZERO

	var rect: Rect2 = main_ref.arena_rect_global
	release_target = Vector2(
		clamp(global_position.x, rect.position.x + 40.0, rect.position.x + rect.size.x - 40.0),
		clamp(global_position.y + 50.0, rect.position.y + 40.0, rect.position.y + rect.size.y - 40.0)
	)

func deactivate() -> void:
	is_active = false
	is_releasing = false
	monitoring = false
	monitorable = false
	velocity = Vector2.ZERO

func _process(delta: float) -> void:
	if main_ref == null or not is_instance_valid(main_ref):
		return

	if is_escaping:
		var speed := 150.0
		global_position += escape_direction * speed * delta

		if escape_direction.x > 0:
			scale.x = -abs(base_scale.x)
		else:
			scale.x = abs(base_scale.x)

		_update_walk_visual(delta)

		var viewport_rect := main_ref.get_viewport_rect()
		if global_position.x < -120.0 or global_position.x > viewport_rect.size.x + 120.0:
			queue_free()

		return

	if is_releasing:
		global_position = global_position.lerp(release_target, 6.0 * delta)

		if global_position.distance_to(release_target) < 6.0:
			global_position = release_target
			is_releasing = false
			is_active = true
			monitoring = true
			monitorable = true

		_update_walk_visual(delta)
		return

	if not is_active:
		_follow_idle_anchor(delta)
		return

	if target == null or not is_instance_valid(target):
		return

	var to_target: Vector2 = target.global_position - global_position
	if to_target.length() > 0.001:
		var desired_velocity: Vector2 = to_target.normalized() * move_speed
		velocity = velocity.lerp(desired_velocity, steer_strength * delta)

	global_position += velocity * delta

	var rect: Rect2 = main_ref.arena_rect_global
	global_position.x = clamp(global_position.x, rect.position.x + 18.0, rect.position.x + rect.size.x - 18.0)
	global_position.y = clamp(global_position.y, rect.position.y + 18.0, rect.position.y + rect.size.y - 18.0)

	if velocity.x > 0.0:
		scale.x = -abs(base_scale.x)
	elif velocity.x < 0.0:
		scale.x = abs(base_scale.x)

	_update_walk_visual(delta)

func _follow_idle_anchor(delta: float) -> void:
	if host_alien == null or not is_instance_valid(host_alien):
		return

	idle_time += delta

	var anchor_pos: Vector2 = host_alien.global_position + idle_offset

	# Seguimiento base (sin retraso excesivo)
	global_position = global_position.lerp(anchor_pos, idle_follow_speed * delta)

	scale.x = abs(base_scale.x)

	# MÁS VIDA AQUÍ ↓
	var rot_offset := sin(idle_time * 2.0) * 0.06
	var squash := sin(idle_time * 2.6) * 0.035
	var x_wiggle := sin(idle_time * 1.8) * 2.0

	rotation = rot_offset
	scale.x = abs(base_scale.x) * (1.0 + squash)
	scale.y = base_scale.y * (1.0 - squash * 0.6)

func _update_walk_visual(delta: float) -> void:
	walk_time += delta

	var moving_amount: float = clamp(velocity.length() / max(move_speed, 1.0), 0.0, 1.0)

	rotation = sin(walk_time * 10.0) * 0.06 * max(moving_amount, 0.35)
	scale.y = base_scale.y * (1.0 + sin(walk_time * 14.0) * 0.03 * max(moving_amount, 0.35))

func escape_to_side() -> void:
	is_active = false
	is_releasing = false
	is_escaping = true

	monitoring = false
	monitorable = false
	velocity = Vector2.ZERO

	if main_ref != null and is_instance_valid(main_ref):
		var viewport_rect := main_ref.get_viewport_rect()

		var dist_left: float = global_position.x
		var dist_right: float = viewport_rect.size.x - global_position.x

		if dist_left <= dist_right:
			escape_direction = Vector2.LEFT
		else:
			escape_direction = Vector2.RIGHT
	else:
		escape_direction = Vector2.RIGHT
