extends Node2D

var speed := 50.0
var direction := 1

func _process(delta):
	position.x += speed * direction * delta
	
	if position.x < 100:
		direction = 1
	elif position.x > 1100:
		direction = -1
	
	# Girar sprite según dirección
	if direction > 0:
		scale.x = -1
	else:
		scale.x = 1
