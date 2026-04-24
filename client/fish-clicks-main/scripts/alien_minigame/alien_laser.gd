extends Area2D

@export var speed: float = 350.0

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	add_to_group("enemy_attack")

func _process(delta: float) -> void:
	global_position += direction * speed * delta
	rotation = direction.angle() - PI / 2.0

	var screen_rect: Rect2 = get_viewport_rect()
	if not screen_rect.has_point(global_position):
		queue_free()

func setup(origin: Vector2, dir: Vector2, custom_speed: float = -1.0) -> void:
	top_level = true
	global_position = origin
	direction = dir

	z_as_relative = false
	z_index = 30

	if custom_speed > 0.0:
		speed = custom_speed

	rotation = direction.angle() - PI / 2.0
	scale = Vector2(0.035, 0.035)
