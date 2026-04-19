extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = $Muzzle

const AIM_OFFSET := -PI / 2.0

func get_muzzle_position() -> Vector2:
	return muzzle.global_position

func aim_towards(target: Vector2) -> void:
	var dir: Vector2 = (target - global_position).normalized()
	rotation = dir.angle() + AIM_OFFSET

func aim_direction(dir: Vector2) -> void:
	rotation = dir.normalized().angle() + AIM_OFFSET

func appear() -> void:
	scale = Vector2(0.08, 0.08)
	modulate.a = 0.0

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "scale", Vector2(0.10, 0.10), 0.2)
	t.tween_property(self, "modulate:a", 1.0, 0.2)

func disappear() -> void:
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "scale", Vector2(0.08, 0.08), 0.18)
	t.tween_property(self, "modulate:a", 0.0, 0.18)
	await t.finished
	queue_free()
