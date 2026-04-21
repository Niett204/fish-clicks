extends Area2D
class_name DirtSpot

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func setup(texture: Texture2D) -> void:
	sprite.texture = texture
	_update_collision_shape()


func _update_collision_shape() -> void:
	if sprite.texture == null:
		return

	var size := sprite.texture.get_size()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision_shape.shape = shape
	
func set_texture(tex: Texture2D) -> void:
	$Sprite2D.texture = tex
