extends Control
class_name CleaningEventLayer

signal cleaning_finished_successfully

@export var dirt_spot_scene: PackedScene
@export var dirt_spot_count: int = 6

@onready var green_overlay: ColorRect = $GreenOverlay
@onready var dirt_spots: Node2D = $DirtSpots
@onready var fish_icon: TextureRect = $FishCornerIcon
@onready var sponge_icon: TextureRect = $SpongeIcon
@onready var auto_cleaner_fish_icon: TextureRect = $AutoCleanerFishIcon

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

# Limpiado automático 
const CLEANER_FISH_ID := "chupete_jr"

var auto_clean_enabled: bool = false
var auto_clean_interval: float = 999.0
var auto_clean_scrubs_per_cycle: int = 0
var auto_clean_level: int = 0
var auto_clean_move_speed: float = 140.0 # velocidad de desplazamiento del pez limpiador
var auto_clean_target: DirtSpot = null
var auto_clean_arrive_distance: float = 18.0
var auto_clean_is_scrubbing_target: bool = false
var auto_clean_scrub_cooldown: float = 0.0
var auto_clean_spawn_position: Vector2 = Vector2(80, 500)
var cleaner_source_fish: Node2D = null
var cleaner_source_fish_was_hidden: bool = false

# Transición pez esquina
var fish_corner_visible_position: Vector2 = Vector2.ZERO
var fish_corner_hidden_position: Vector2 = Vector2.ZERO
var fish_corner_exit_animating: bool = false

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
	auto_cleaner_fish_icon.visible = false
	auto_cleaner_fish_icon.global_position = auto_clean_spawn_position

	fish_corner_visible_position = fish_icon.position
	fish_corner_hidden_position = Vector2(
		-fish_icon.size.x - 40.0,
		fish_corner_visible_position.y
	)

	fish_icon.position = fish_corner_hidden_position

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
	
	_refresh_cleaner_visuals()
	
	if not cleaning_ready:
		return
		
	_process_auto_clean(_delta)

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

func _refresh_cleaner_visuals() -> void:
	if cleaning_finished:
		auto_cleaner_fish_icon.visible = false
		return

	if auto_clean_enabled:
		fish_icon.visible = false
		auto_cleaner_fish_icon.visible = true
	else:
		auto_cleaner_fish_icon.visible = false
	
func show_event() -> void:
	visible = true
	cleaning_ready = false
	is_scrubbing = false
	cleaning_finished = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	_update_auto_clean_stats()

	if cleaning_manager != null and cleaning_manager.main != null:
		cleaning_manager.main.pecera_blocker.visible = true

	green_overlay.visible = true
	sponge_icon.visible = false

	# Limpieza automática
	auto_clean_target = null
	auto_clean_is_scrubbing_target = false
	auto_clean_scrub_cooldown = 0.0

	spawn_dirt_spots()

	_refresh_cleaner_visuals()
	_play_fish_corner_enter()

	if auto_clean_enabled:
		_prepare_cleaner_fish_transition()
		auto_clean_target = _get_best_auto_clean_target()

	var color := green_overlay.color
	color.a = 0.0
	green_overlay.color = color

	var tween = create_tween()
	tween.tween_property(green_overlay, "color:a", 0.6, 0.8)

	start_dirt_growth()

func hide_event() -> void:
	clear_dirt_spots()
	green_overlay.visible = false
	fish_icon.visible = false
	sponge_icon.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if cleaner_source_fish != null and is_instance_valid(cleaner_source_fish):
		var final_cleaner_pos: Vector2 = auto_cleaner_fish_icon.global_position + auto_cleaner_fish_icon.size * 0.5
		auto_cleaner_fish_icon.visible = false
		_restore_cleaner_fish_from_transition(final_cleaner_pos)
	else:
		auto_cleaner_fish_icon.visible = false
		
	auto_clean_enabled = false
	auto_clean_target = null
	auto_clean_is_scrubbing_target = false
	auto_clean_scrub_cooldown = 0.0

	if cleaning_manager != null and cleaning_manager.main != null:
		cleaning_manager.main.pecera_blocker.visible = false
		cleaning_manager.main.aquarium_manager.set_fish_visual_hidden_by_id(CLEANER_FISH_ID, false)

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

		for attempt in range(40):
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

func _play_fish_corner_enter() -> void:
	if auto_clean_enabled:
		fish_icon.visible = false
		return

	fish_corner_exit_animating = false
	fish_icon.visible = true
	fish_icon.position = fish_corner_hidden_position

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(fish_icon, "position", fish_corner_visible_position, 0.45)

func _play_fish_corner_exit() -> void:
	if not fish_icon.visible:
		return

	fish_corner_exit_animating = true

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(fish_icon, "position", fish_corner_hidden_position, 0.35)

	await tween.finished

	fish_icon.visible = false
	fish_corner_exit_animating = false

func _prepare_cleaner_fish_transition() -> void:
	cleaner_source_fish = null
	cleaner_source_fish_was_hidden = false

	if not auto_clean_enabled:
		return

	if cleaning_manager == null or cleaning_manager.main == null:
		return

	cleaner_source_fish = cleaning_manager.main.aquarium_manager.get_spawned_fish_by_id(CLEANER_FISH_ID)

	if cleaner_source_fish == null or not is_instance_valid(cleaner_source_fish):
		return

	var fish_start_pos: Vector2 = cleaner_source_fish.global_position
	auto_cleaner_fish_icon.global_position = fish_start_pos - auto_cleaner_fish_icon.size * 0.5

	cleaner_source_fish.visible = false
	cleaner_source_fish_was_hidden = true

func _restore_cleaner_fish_from_transition(final_position: Vector2) -> void:
	if cleaner_source_fish == null or not is_instance_valid(cleaner_source_fish):
		return

	cleaner_source_fish.global_position = final_position

	if cleaning_manager != null and cleaning_manager.main != null:
		cleaner_source_fish.visible = cleaner_source_fish.get("habitat_id") == cleaning_manager.main.habitat_manager.current_habitat
	else:
		cleaner_source_fish.visible = true

	cleaner_source_fish = null
	cleaner_source_fish_was_hidden = false
		
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
	is_scrubbing = false
	sponge_icon.visible = false

	if auto_clean_enabled:
		var final_cleaner_pos: Vector2 = auto_cleaner_fish_icon.global_position + auto_cleaner_fish_icon.size * 0.5
		auto_cleaner_fish_icon.visible = false
		_restore_cleaner_fish_from_transition(final_cleaner_pos)
	else:
		auto_cleaner_fish_icon.visible = false

	await _play_fish_corner_exit()

	var tween = create_tween()
	tween.tween_property(green_overlay, "color:a", 0.0, 0.5)

	await tween.finished

	cleaning_finished_successfully.emit()
	
# ------------- LIMPIEZA AUTOMÁTICA -------------
func _process_auto_clean(delta: float) -> void:
	if not auto_clean_enabled:
		return

	if cleaning_finished:
		return

	if not auto_cleaner_fish_icon.visible:
		return

	if dirt_spots.get_child_count() == 0:
		return

	if auto_clean_target == null or not is_instance_valid(auto_clean_target):
		auto_clean_target = _get_best_auto_clean_target()
		auto_clean_is_scrubbing_target = false

	if auto_clean_target == null:
		return

	if auto_clean_is_scrubbing_target:
		_process_auto_scrub_on_target(delta)
	else:
		_process_auto_move_to_target(delta)

func _process_auto_move_to_target(delta: float) -> void:
	if auto_clean_target == null or not is_instance_valid(auto_clean_target):
		auto_clean_target = null
		return

	var fish_center := auto_cleaner_fish_icon.global_position + auto_cleaner_fish_icon.size * 0.5
	var target_pos := auto_clean_target.global_position
	var to_target := target_pos - fish_center
	var distance := to_target.length()

	if distance <= auto_clean_arrive_distance:
		auto_clean_is_scrubbing_target = true
		auto_clean_scrub_cooldown = 0.0
		return

	var direction := to_target.normalized()
	var move_amount: float = auto_clean_move_speed * delta
	var step: float = min(move_amount, distance)
	var new_center: Vector2 = fish_center + direction * step

	auto_cleaner_fish_icon.global_position = new_center - auto_cleaner_fish_icon.size * 0.5

	# opcional: flip horizontal según dirección
	if direction.x != 0.0:
		auto_cleaner_fish_icon.flip_h = direction.x < 0.0

func _get_best_auto_clean_target_excluding(excluded: DirtSpot) -> DirtSpot:
	var best_spot: DirtSpot = null
	var best_stage: int = -1

	for spot in dirt_spots.get_children():
		if not (spot is DirtSpot):
			continue

		var dirt := spot as DirtSpot

		if dirt == excluded:
			continue

		if dirt.size_stage > best_stage:
			best_stage = dirt.size_stage
			best_spot = dirt

	return best_spot

func _process_auto_scrub_on_target(delta: float) -> void:
	if auto_clean_target == null or not is_instance_valid(auto_clean_target):
		auto_clean_target = null
		auto_clean_is_scrubbing_target = false
		return

	auto_clean_scrub_cooldown += delta

	if auto_clean_scrub_cooldown < auto_clean_interval:
		return

	auto_clean_scrub_cooldown = 0.0

	var total_scrubs := auto_clean_scrubs_per_cycle
	for i in range(total_scrubs):
		if auto_clean_target == null or not is_instance_valid(auto_clean_target):
			break

		var changed: bool = auto_clean_target.apply_scrub()

		if changed:
			_reduce_green_overlay()
			_check_if_clean_finished()

	# si la mancha ya no existe o ya cambió tras limpiar, elegir otra
	if auto_clean_target == null or not is_instance_valid(auto_clean_target):
		auto_clean_target = _get_best_auto_clean_target()
		auto_clean_is_scrubbing_target = false
		return

	# aunque siga existiendo, después de un ciclo puede cambiar de objetivo
	auto_clean_target = _get_best_auto_clean_target_excluding(auto_clean_target)
	if auto_clean_target == null:
		auto_clean_target = _get_best_auto_clean_target()

	auto_clean_is_scrubbing_target = false

func _get_best_auto_clean_target() -> DirtSpot:
	var best_spot: DirtSpot = null
	var best_stage: int = -1

	for spot in dirt_spots.get_children():
		if not (spot is DirtSpot):
			continue

		var dirt := spot as DirtSpot
		if dirt.size_stage > best_stage:
			best_stage = dirt.size_stage
			best_spot = dirt

	return best_spot
	
func _get_cleaner_fish_level() -> int:
	if cleaning_manager == null or cleaning_manager.main == null:
		return 0

	return int(cleaning_manager.main.shop_manager.get_level(CLEANER_FISH_ID))

func _has_cleaner_fish_assistance() -> bool:
	if cleaning_manager == null or cleaning_manager.main == null:
		return false

	var main_ref = cleaning_manager.main
	var is_unlocked: bool = bool(main_ref.unlocked.get(CLEANER_FISH_ID, false))
	var level: int = _get_cleaner_fish_level()
	var is_in_aquarium: bool = main_ref.aquarium_manager.has_fish_in_aquarium(CLEANER_FISH_ID)

	return is_unlocked and level > 0 and is_in_aquarium

func _update_auto_clean_stats() -> void:
	auto_clean_level = _get_cleaner_fish_level()

	if not _has_cleaner_fish_assistance():
		auto_clean_enabled = false
		auto_clean_interval = 999.0
		auto_clean_scrubs_per_cycle = 0
		auto_clean_move_speed = 0.0
		return

	auto_clean_enabled = true
	auto_clean_interval = max(0.55, 2.4 - float(auto_clean_level) * 0.22)
	auto_clean_scrubs_per_cycle = 1 + int(auto_clean_level / 4)
	auto_clean_move_speed = 110.0 + float(auto_clean_level) * 18.0
