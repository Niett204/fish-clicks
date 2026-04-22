extends Area2D
class_name DirtSpot

signal fully_cleaned

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var alga_type: int = 0
var size_stage: int = 0 # 0 = small, 1 = medium, 2 = large
var scrub_progress: int = 0


func setup(texture: Texture2D, p_alga_type: int, p_size_stage: int) -> void:
	alga_type = p_alga_type
	size_stage = p_size_stage
	sprite.texture = texture
	_update_collision_shape()


func set_texture(tex: Texture2D) -> void:
	sprite.texture = tex
	_update_collision_shape()


func set_stage(new_stage: int) -> void:
	size_stage = new_stage
	set_texture(_get_texture_for_stage())


func apply_scrub() -> bool:
	scrub_progress += 1

	if scrub_progress < 2:
		return false

	scrub_progress = 0

	if size_stage == 2:
		set_stage(1)
		return true

	if size_stage == 1:
		set_stage(0)
		return true

	if size_stage == 0:
		fully_cleaned.emit()
		queue_free()
		return true

	return false


func _get_texture_for_stage() -> Texture2D:
	match alga_type:
		0:
			match size_stage:
				0:
					return preload("res://assets/minijuegos/limpieza/algas/alga_1_small.png")
				1:
					return preload("res://assets/minijuegos/limpieza/algas/alga_1_medium.png")
				2:
					return preload("res://assets/minijuegos/limpieza/algas/alga_1_large.png")

		1:
			match size_stage:
				0:
					return preload("res://assets/minijuegos/limpieza/algas/alga_2_small.png")
				1:
					return preload("res://assets/minijuegos/limpieza/algas/alga_2_medium.png")
				2:
					return preload("res://assets/minijuegos/limpieza/algas/alga_2_large.png")

		2:
			match size_stage:
				0:
					return preload("res://assets/minijuegos/limpieza/algas/alga_3_small.png")
				1:
					return preload("res://assets/minijuegos/limpieza/algas/alga_3_medium.png")
				2:
					return preload("res://assets/minijuegos/limpieza/algas/alga_3_large.png")

	return null


func _update_collision_shape() -> void:
	if sprite.texture == null:
		return

	var tex_size := sprite.texture.get_size()
	var shape := RectangleShape2D.new()
	shape.size = tex_size
	collision_shape.shape = shape
