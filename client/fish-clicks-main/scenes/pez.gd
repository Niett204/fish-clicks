extends Node2D

enum FishState { WANDER, SCARED }
var state: FishState = FishState.WANDER

@export var speed := 70.0
@export var steer := 7.0
@export var target_reached_dist := 20.0

# IMPORTANTE: este rect en coordenadas GLOBALES (mundo)
@export var swim_area: Node2D
var swim_rect: Rect2

var target: Vector2
var vel: Vector2 = Vector2.ZERO
var state_timer := 0.0

@onready var spr: Sprite2D = $Sprite2D

func _ready():
	randomize()
	_update_swim_rect()
	_pick_new_target()

func _process(delta):
	match state:
		FishState.WANDER:
			_wander_step(delta)

		FishState.SCARED:
			_scared_step(delta)

func _wander_step(delta: float) -> void:
	# si salimos por lo que sea, “reenganchamos” dentro
	global_position = _clamp_to_rect(global_position, swim_rect)

	var desired = (target - global_position)
	if desired.length() < target_reached_dist:
		_pick_new_target()
		return

	desired = desired.normalized() * speed
	vel = vel.lerp(desired, 1.0 - exp(-steer * delta))  # steering suave
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
	if vel.x == 0: return
	spr.flip_h = vel.x > 0

func _clamp_to_rect(p: Vector2, r: Rect2) -> Vector2:
	return Vector2(
		clamp(p.x, r.position.x, r.position.x + r.size.x),
		clamp(p.y, r.position.y, r.position.y + r.size.y)
	)

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
