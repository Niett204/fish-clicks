extends Control
class_name CleaningEventLayer

@export var dirt_spot_scene: PackedScene
@export var dirt_spot_count: int = 6

@onready var green_overlay: ColorRect = $GreenOverlay
@onready var dirt_spots: Node2D = $DirtSpots
@onready var fish_icon: TextureRect = $FishCornerIcon

var dirt_textures: Array[Texture2D] = [
	preload("res://assets/minijuegos/limpieza/algas/alga_1_small.png"),
	preload("res://assets/minijuegos/limpieza/algas/alga_1_medium.png"),
	preload("res://assets/minijuegos/limpieza/algas/alga_1_large.png"),
	preload("res://assets/minijuegos/limpieza/algas/alga_2_small.png"),
	preload("res://assets/minijuegos/limpieza/algas/alga_2_medium.png"),
	preload("res://assets/minijuegos/limpieza/algas/alga_2_large.png"),
	preload("res://assets/minijuegos/limpieza/algas/alga_3_small.png"),
	preload("res://assets/minijuegos/limpieza/algas/alga_3_medium.png"),
	preload("res://assets/minijuegos/limpieza/algas/alga_3_large.png")
]

func _ready() -> void:
	visible = false
	green_overlay.visible = false
	fish_icon.visible = false


func show_event() -> void:
	visible = true
	green_overlay.visible = true
	fish_icon.visible = true
	spawn_dirt_spots()


func hide_event() -> void:
	clear_dirt_spots()
	green_overlay.visible = false
	fish_icon.visible = false
	visible = false

func spawn_dirt_spots() -> void:
	clear_dirt_spots()

	if dirt_spot_scene == null:
		print("No hay dirt_spot_scene asignada")
		return

	if dirt_textures.is_empty():
		print("No hay texturas de suciedad cargadas")
		return

	var min_x := 90.0
	var max_x := 1060.0
	var min_y := 90.0
	var max_y := 590.0

	var count := dirt_spot_count
	var min_distance := 140.0
	var used_positions: Array[Vector2] = []

	for i in range(count):
		var spot: DirtSpot = dirt_spot_scene.instantiate()
		dirt_spots.add_child(spot)

		var random_texture := dirt_textures[randi() % dirt_textures.size()]
		spot.setup(random_texture)

		var chosen_position := Vector2.ZERO
		var found_valid_position := false

		for attempt in range(20):
			var candidate := Vector2(
				randf_range(min_x, max_x),
				randf_range(min_y, max_y)
			)

			var too_close := false
			for used_pos in used_positions:
				if candidate.distance_to(used_pos) < min_distance:
					too_close = true
					break

			if not too_close:
				chosen_position = candidate
				found_valid_position = true
				break

		if not found_valid_position:
			chosen_position = Vector2(
				randf_range(min_x, max_x),
				randf_range(min_y, max_y)
			)

		used_positions.append(chosen_position)

		spot.position = chosen_position
		spot.rotation = randf_range(-0.25, 0.25)

		var random_scale := randf_range(0.08, 0.16)
		spot.scale = Vector2(random_scale, random_scale)

		print("Mancha ", i, " en ", spot.position)

func clear_dirt_spots() -> void:
	for child in dirt_spots.get_children():
		child.queue_free()
