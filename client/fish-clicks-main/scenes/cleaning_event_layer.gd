extends Control
class_name CleaningEventLayer

signal cleaning_finished_successfully

@export var dirt_spot_scene: PackedScene
@export var dirt_spot_count: int = 6

@onready var green_overlay: ColorRect = $GreenOverlay
@onready var dirt_spots: Node2D = $DirtSpots
@onready var fish_icon: TextureRect = $FishCornerIcon
@onready var sponge_icon: TextureRect = $SpongeIcon

@export var growth_delay_between_stages: float = 0.8 # tiempo entre small → medium → large
@export var growth_stagger_max: float = 0.4 # cuánto se desincronizan entre sí las manchas
@export var dirt_spot_min_distance: float = 250.0 # distancia entre manchas
@export var dirt_base_radius: float = 80.0

# Frotado 
@export var scrub_radius: float = 90.0
@export var scrub_interval: float = 0.3
var last_mouse_pos: Vector2 = Vector2.ZERO
@export var min_scrub_movement: float = 20.0 # píxeles mínimos para considerar frotado
var scrub_movement_accum: float = 0.0

# Movimiento de frotado de la esponja
var scrub_anim_time: float = 0.0
@export var scrub_shake_intensity: float = 5.0
@export var scrub_rotation_intensity: float = 0.1
@export var scrub_speed: float = 10.0

var cleaning_manager: CleaningManager = null
var scrub_timer: float = 0.0
var is_scrubbing: bool = false
var sponge_offset: Vector2 = Vector2(-40, -40) # para que la esponja no tape el puntero
var cleaning_ready: bool = false # Será false mientras el minijuego esté en transición de aparecer
var cleaning_finished: bool = false # flag temporal de esta ejecución del minijuego

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
	sponge_icon.visible = false

func _process(_delta: float) -> void:
	if not visible:
		return

	var mouse_pos := get_global_mouse_position()

	# --- MOVIMIENTO ESPONJA ---
	if sponge_icon.visible:
		var target_pos := mouse_pos + sponge_offset
		
		if is_scrubbing:
			scrub_anim_time += _delta * scrub_speed
			
			var shake := Vector2(
				sin(scrub_anim_time) * scrub_shake_intensity,
				cos(scrub_anim_time * 1.3) * scrub_shake_intensity * 0.5
			)

			sponge_icon.global_position = target_pos + shake
			sponge_icon.rotation = sin(scrub_anim_time * 1.5) * scrub_rotation_intensity
		else:
			scrub_anim_time = 0.0
			sponge_icon.global_position = target_pos
			sponge_icon.rotation = lerp(sponge_icon.rotation, 0.0, 0.2)

	if not cleaning_ready:
		return

	# --- LÓGICA DE SCRUB REAL ---
	var movement := mouse_pos.distance_to(last_mouse_pos)

	if is_scrubbing:
		scrub_movement_accum += movement

		if scrub_movement_accum >= min_scrub_movement:
			scrub_timer += _delta

			if scrub_timer >= scrub_interval:
				scrub_timer = 0.0
				_apply_scrub_to_nearby_spots()
				scrub_movement_accum = 0.0  # reset tras aplicar
	else:
		scrub_timer = 0.0
		scrub_movement_accum = 0.0

	last_mouse_pos = mouse_pos

func setup_cleaning_layer(cleaning_manager_ref: CleaningManager) -> void:
	cleaning_manager = cleaning_manager_ref
	
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if not cleaning_ready:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_scrubbing = event.pressed

func show_event() -> void:
	visible = true
	cleaning_ready = false
	is_scrubbing = false
	cleaning_finished = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	if cleaning_manager != null and cleaning_manager.main != null:
		cleaning_manager.main.pecera_blocker.visible = true

	fish_icon.visible = true
	green_overlay.visible = true
	sponge_icon.visible = false

	var color := green_overlay.color
	color.a = 0.0
	green_overlay.color = color

	var tween = create_tween()
	tween.tween_property(green_overlay, "color:a", 0.6, 0.8)

	spawn_dirt_spots()
	start_dirt_growth()


func hide_event() -> void:
	clear_dirt_spots()
	green_overlay.visible = false
	fish_icon.visible = false
	sponge_icon.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if cleaning_manager != null and cleaning_manager.main != null:
		cleaning_manager.main.pecera_blocker.visible = false

	visible = false
	cleaning_finished = false

	is_scrubbing = false
	cleaning_ready = false
	scrub_timer = 0.0

func spawn_dirt_spots() -> void:
	clear_dirt_spots()

	if dirt_spot_scene == null:
		print("No hay dirt_spot_scene asignada")
		return

	if dirt_textures.is_empty():
		print("No hay texturas de suciedad cargadas")
		return

	var min_x := 120.0
	var max_x := 1000.0
	var min_y := 120.0
	var max_y := 560.0

	var count := dirt_spot_count
	var used_spots: Array = [] # [{pos, radius}]

	for i in range(count):
		var spot: DirtSpot = dirt_spot_scene.instantiate()
		dirt_spots.add_child(spot)

		if not spot.fully_cleaned.is_connected(_on_dirt_spot_fully_cleaned):
			spot.fully_cleaned.connect(_on_dirt_spot_fully_cleaned)

		var small_textures: Array[Texture2D] = [
			preload("res://assets/minijuegos/limpieza/algas/alga_1_small.png"),
			preload("res://assets/minijuegos/limpieza/algas/alga_2_small.png"),
			preload("res://assets/minijuegos/limpieza/algas/alga_3_small.png")
		]

		var alga_type: int = randi() % 3

		var r := randf()
		var max_stage: int
		if r < 0.2:
			max_stage = 0
		elif r < 0.7:
			max_stage = 1
		else:
			max_stage = 2

		spot.set_meta("max_stage", max_stage)

		var random_texture: Texture2D = small_textures[alga_type]
		spot.setup(random_texture, alga_type, 0)

		# Escala y radio ANTES de calcular posición
		var random_scale: float = randf_range(0.12, 0.20)
		spot.scale = Vector2(random_scale, random_scale)

		var growth_multiplier: float = 1.0
		match max_stage:
			0:
				growth_multiplier = 1.0
			1:
				growth_multiplier = 1.4
			2:
				growth_multiplier = 1.8

		var spot_radius: float = dirt_base_radius * random_scale * growth_multiplier

		var chosen_position := Vector2.ZERO
		var found_valid_position := false

		for attempt in range(20):
			var candidate := Vector2(
				randf_range(min_x, max_x),
				randf_range(min_y, max_y)
			)

			var too_close := false
			for used in used_spots:
				var dist: float = candidate.distance_to(used["pos"])
				var min_dist: float = used["radius"] + spot_radius + 90.0

				if dist < min_dist:
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

		used_spots.append({
			"pos": chosen_position,
			"radius": spot_radius
		})

		spot.position = chosen_position
		spot.rotation = randf_range(-0.25, 0.25)

func clear_dirt_spots() -> void:
	for child in dirt_spots.get_children():
		child.queue_free()

func start_dirt_growth() -> void:
	await get_tree().create_timer(growth_delay_between_stages).timeout
	await grow_to_medium()

	await get_tree().create_timer(growth_delay_between_stages).timeout
	await grow_to_large()

	cleaning_ready = true
	sponge_icon.visible = true

func grow_to_medium() -> void:
	for spot in dirt_spots.get_children():
		await get_tree().create_timer(randf_range(0.0, growth_stagger_max)).timeout

		if spot is DirtSpot:
			var max_stage: int = int(spot.get_meta("max_stage"))

			if max_stage >= 1:
				(spot as DirtSpot).set_stage(1)

func grow_to_large() -> void:
	for spot in dirt_spots.get_children():
		await get_tree().create_timer(randf_range(0.0, growth_stagger_max)).timeout

		if spot is DirtSpot:
			var max_stage: int = int(spot.get_meta("max_stage"))

			if max_stage >= 2:
				(spot as DirtSpot).set_stage(2)
		
func _apply_scrub_to_nearby_spots() -> void:
	var sponge_center := sponge_icon.global_position + sponge_icon.size * 0.5

	for spot in dirt_spots.get_children():
		if not (spot is DirtSpot):
			continue
		
		var dirt_spot := spot as DirtSpot

		var dist := sponge_center.distance_to(dirt_spot.global_position)
		if dist <= scrub_radius:
			var changed: bool = dirt_spot.apply_scrub()

			if changed:
				_reduce_green_overlay()
				_check_if_clean_finished()
				
func _reduce_green_overlay() -> void:
	var color := green_overlay.color
	color.a = max(color.a - 0.03, 0.0)
	green_overlay.color = color

func _on_dirt_spot_fully_cleaned() -> void:
	if cleaning_manager != null:
		cleaning_manager.register_dirt_spot_cleaned()
		
# Para comprobar si ya podemos cerrar el minijuego
func _check_if_clean_finished() -> void:
	if cleaning_finished:
		return

	await get_tree().process_frame

	if cleaning_finished:
		return

	if dirt_spots.get_child_count() == 0:
		cleaning_finished = true
		_on_cleaning_finished()

# Para la penalización de doblones
func has_dirt_remaining() -> bool:
	return dirt_spots.get_child_count() > 0

func _on_cleaning_finished() -> void:
	print("Minijuego completado")

	is_scrubbing = false
	sponge_icon.visible = false

	var tween = create_tween()
	tween.tween_property(green_overlay, "color:a", 0.0, 0.5)

	await tween.finished

	cleaning_finished_successfully.emit()
