extends Label

var velocity := Vector2(0, -50)
var lifetime := 0.6

func _process(delta):
	position += velocity * delta
	modulate.a -= delta / lifetime
	
	if modulate.a <= 0:
		queue_free()
