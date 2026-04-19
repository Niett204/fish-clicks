extends Node2D

const AlienAttackUtilsScript = preload("res://scripts/alien_minigame/alien_attack_utils.gd")
const AlienBossPatternsScript = preload("res://scripts/alien_minigame/alien_boss_patterns.gd")
const AlienGunPatternsScript = preload("res://scripts/alien_minigame/alien_gun_patterns.gd")

const RETURN_SCENE_PATH := "res://scenes/main.tscn"

@export var player_radius: float = 12.0
@export var laser_scene: PackedScene
@export var floating_gun_scene: PackedScene
@export var glitch_zone_scene: PackedScene
@export var worm_scene: PackedScene
@export var max_health: int = 5
@export var invulnerability_duration: float = 1.0
@export var shell_full_texture: Texture2D
@export var shell_empty_texture: Texture2D
@export var survival_time_seconds: float = 50.0

@onready var summons: Node2D = $Background/BattleLayer/Summons
@onready var arena_inner: ColorRect = $Background/BattleLayer/Arena/ArenaBorder/ArenaInner
@onready var player: Area2D = $Background/BattleLayer/Player
@onready var attacks: Node2D = $Background/BattleLayer/Attacks
@onready var alien: Node2D = $Background/BattleLayer/Alien
@onready var lives_row: HBoxContainer = $Background/UI/LivesRow
@onready var timer_label: Label = $Background/UI/TimerLabel
@onready var bg_fish_1: Sprite2D = $Background/Pez
@onready var bg_fish_2: Sprite2D = $Background/Pez2
@onready var bg_fish_3: Sprite2D = $Background/Pez3
@onready var bg_fish_4: Sprite2D = $Background/Pez4
@onready var anger_symbol: TextureRect = $Enfado
@onready var battle_camera: Camera2D = $Background/BattleLayer/Camera2D
@onready var alien_sprite: Sprite2D = $Background/BattleLayer/Alien/Sprite2D

enum BossPhase {
	PHASE_1,
	PHASE_2,
	PHASE_3
}

var current_phase: int = BossPhase.PHASE_1
var arena_rect_global: Rect2

var current_health: int = 0
var is_invulnerable: bool = false
var is_dead: bool = false
var has_won: bool = false
var life_icons: Array[TextureRect] = []
var remaining_time: float = 0.0
var is_finishing: bool = false

var attack_utils: AlienAttackUtils
var boss_patterns: AlienBossPatterns
var gun_patterns: AlienGunPatterns

var attack_sequence_index: int = 0
var phase_2_started: bool = false
var phase_3_started: bool = false
var is_phase_transitioning: bool = false
var base_alien_scale: Vector2 = Vector2.ONE
var base_alien_rotation: float = 0.0
var is_attack_running: bool = false
var pending_phase: int = -1
var worm_instance: Area2D = null
var worm_phase_active: bool = false

var recent_attacks: Array[int] = []
const MAX_RECENT_ATTACKS: int = 3
var phase_3_zone_loop_started: bool = false
var active_glitch_zones: Array[Area2D] = []
var background_fish_sprites: Array[Sprite2D] = []
var background_fish_idle_time: float = 0.0
var background_fish_idle_data: Array[Dictionary] = []
var is_timer_paused: bool = false
var worm_phase_3_escape_started: bool = false
const WORM_ESCAPE_BEFORE_PHASE_3_SECONDS: float = 3.0

func _ready() -> void:
	attack_utils = AlienAttackUtilsScript.new()
	add_child(attack_utils)
	attack_utils.setup(self)

	boss_patterns = AlienBossPatternsScript.new()
	add_child(boss_patterns)
	boss_patterns.setup(self, attack_utils)

	gun_patterns = AlienGunPatternsScript.new()
	add_child(gun_patterns)
	gun_patterns.setup(self, attack_utils)

	await get_tree().process_frame
	update_arena_rect()
	center_player_in_arena()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	if alien.has_method("set_idle_pose"):
		alien.set_idle_pose()

	base_alien_scale = alien.scale
	base_alien_rotation = alien.rotation

	setup_health_system()
	setup_survival_timer()
	
	if anger_symbol != null:
		anger_symbol.visible = false
		anger_symbol.modulate.a = 0.0
		anger_symbol.scale = Vector2.ONE
	
	background_fish_sprites = [bg_fish_1, bg_fish_2, bg_fish_3, bg_fish_4]
	setup_background_display_fish()
	
	if alien != null and alien.has_method("set_antenna_phase_visual"):
		alien.set_antenna_phase_visual(1)

	if player.has_signal("area_entered"):
		player.area_entered.connect(_on_player_area_entered)

	spawn_idle_worm()
	start_attack_loop()


func setup_background_display_fish() -> void:
	var fish_data: Array = GlobalData.consume_pending_minigame_display_fish_data()

	if background_fish_sprites.is_empty():
		return

	background_fish_idle_data.clear()

	if fish_data.is_empty():
		for sprite in background_fish_sprites:
			if sprite != null:
				background_fish_idle_data.append({
					"base_position": sprite.position,
					"base_rotation": sprite.rotation,
					"base_scale": sprite.scale,
					"is_capsule": false
				})
		return

	for i in range(background_fish_sprites.size()):
		var fish_sprite := background_fish_sprites[i]

		if fish_sprite == null:
			continue

		if i >= fish_data.size():
			fish_sprite.visible = false
			continue

		var entry: Dictionary = fish_data[i]
		var texture_path := str(entry.get("texture_path", ""))
		var is_capsule := bool(entry.get("is_capsule", false))

		if texture_path == "":
			fish_sprite.visible = false
			continue

		var tex := load(texture_path) as Texture2D
		if tex == null:
			fish_sprite.visible = false
			continue

		fish_sprite.texture = tex
		fish_sprite.visible = true

		background_fish_idle_data.append({
			"base_position": fish_sprite.position,
			"base_rotation": fish_sprite.rotation,
			"base_scale": fish_sprite.scale,
			"is_capsule": is_capsule
		})
		

func setup_health_system() -> void:
	current_health = max_health
	life_icons.clear()

	for child in lives_row.get_children():
		if child is TextureRect:
			life_icons.append(child)

	update_lives_ui()


func setup_survival_timer() -> void:
	remaining_time = survival_time_seconds
	update_timer_ui()


func update_lives_ui() -> void:
	for i in range(life_icons.size()):
		if i < current_health:
			life_icons[i].texture = shell_full_texture
			life_icons[i].modulate = Color(1, 1, 1, 1)
		else:
			life_icons[i].texture = shell_empty_texture if shell_empty_texture != null else shell_full_texture
			life_icons[i].modulate = Color(1, 1, 1, 0.25)


func update_timer_ui() -> void:
	var total_seconds: int = int(ceil(max(remaining_time, 0.0)))
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	var time_text := "%02d:%02d" % [minutes, seconds]

	if timer_label:
		timer_label.text = time_text


func update_phase() -> void:
	if is_phase_transitioning or is_timer_paused:
		return

	var progress: float = 1.0 - (remaining_time / survival_time_seconds)

	var new_phase: int = BossPhase.PHASE_1
	if progress >= 2.0 / 3.0:
		new_phase = BossPhase.PHASE_3
	elif progress >= 1.0 / 3.0:
		new_phase = BossPhase.PHASE_2

	if new_phase != current_phase:
		pending_phase = new_phase
		

func set_phase(new_phase: int) -> void:
	if current_phase == new_phase:
		return

	pending_phase = new_phase


func _run_phase_transition(new_phase: int) -> void:
	match new_phase:
		BossPhase.PHASE_1:
			if alien != null and alien.has_method("set_antenna_phase_visual"):
				alien.set_antenna_phase_visual(1)

		BossPhase.PHASE_2:
			await play_phase_2_transition()
			start_phase_2()

		BossPhase.PHASE_3:
			await play_phase_transition(3)
			start_phase_3()


func play_phase_transition(phase_number: int) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 9999
	add_child(layer)

	var darken := ColorRect.new()
	darken.color = Color(0, 0, 0, 0.0)
	darken.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(darken)

	if battle_camera == null or not is_instance_valid(battle_camera):
		if is_instance_valid(layer):
			layer.queue_free()
		return

	if alien != null and alien.has_method("set_antenna_phase_visual"):
		alien.set_antenna_phase_visual(phase_number)

	var original_zoom: Vector2 = battle_camera.zoom
	var original_pos: Vector2 = battle_camera.position
	var original_alien_rot: float = alien.rotation
	var original_alien_scale: Vector2 = alien.scale

	var zoom_in := Vector2(2.15, 2.15)
	var lifted_pos := original_pos + Vector2(0.0, -150.0)

	if anger_symbol != null:
		anger_symbol.visible = false
		anger_symbol.modulate.a = 0.0
		anger_symbol.scale = Vector2(0.4, 0.4)

	# 1) Zoom in
	var t1 := create_tween()
	t1.set_parallel(true)
	t1.tween_property(battle_camera, "zoom", zoom_in, 0.34)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t1.tween_property(battle_camera, "position", lifted_pos, 0.34)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t1.tween_property(darken, "color:a", 0.26, 0.32)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await t1.finished

	await get_tree().create_timer(0.10).timeout

	# 2) Símbolo enfado
	if anger_symbol != null:
		anger_symbol.visible = true
		anger_symbol.modulate.a = 0.0
		anger_symbol.scale = Vector2(0.35, 0.35)

		var t2 := create_tween()
		t2.set_parallel(true)
		t2.tween_property(anger_symbol, "modulate:a", 1.0, 0.12)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t2.tween_property(anger_symbol, "scale", Vector2(1.30, 0.82), 0.14)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await t2.finished

		var t2b := create_tween()
		t2b.tween_property(anger_symbol, "scale", Vector2(0.92, 1.10), 0.10)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await t2b.finished

		var t2c := create_tween()
		t2c.tween_property(anger_symbol, "scale", Vector2(1.0, 1.0), 0.10)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await t2c.finished

	# 3) Antenas parpadean blanco + glitches al lado del alien
	await play_phase_3_glitch_burst()

	# 4) Mini pausa dramática
	await get_tree().create_timer(0.12).timeout

	# 5) Volver a normal
	var t4 := create_tween()
	t4.set_parallel(true)
	t4.tween_property(battle_camera, "zoom", original_zoom, 0.34)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t4.tween_property(battle_camera, "position", original_pos, 0.34)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t4.tween_property(darken, "color:a", 0.0, 0.30)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	if anger_symbol != null:
		t4.tween_property(anger_symbol, "modulate:a", 0.0, 0.14)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t4.tween_property(anger_symbol, "scale", Vector2(0.82, 0.82), 0.14)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await t4.finished

	battle_camera.zoom = original_zoom
	battle_camera.position = original_pos

	if alien != null and is_instance_valid(alien):
		alien.rotation = original_alien_rot
		alien.scale = original_alien_scale

	if anger_symbol != null:
		anger_symbol.visible = false
		anger_symbol.modulate.a = 0.0
		anger_symbol.scale = Vector2.ONE

	if is_instance_valid(layer):
		layer.queue_free()

func play_phase_2_transition() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 9999
	add_child(layer)

	var darken := ColorRect.new()
	darken.color = Color(0, 0, 0, 0.0)
	darken.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(darken)

	if battle_camera == null or not is_instance_valid(battle_camera):
		if is_instance_valid(layer):
			layer.queue_free()
		return

	if alien != null and alien.has_method("set_antenna_phase_visual"):
		alien.set_antenna_phase_visual(2)

	var original_zoom: Vector2 = battle_camera.zoom
	var original_pos: Vector2 = battle_camera.position
	var original_alien_rot: float = alien.rotation
	var original_alien_scale: Vector2 = alien.scale

	var zoom_in := Vector2(2.0, 2.0)
	var lifted_pos := original_pos + Vector2(0.0, -150.0)

	if anger_symbol != null:
		anger_symbol.visible = false
		anger_symbol.modulate.a = 0.0
		anger_symbol.scale = Vector2(0.4, 0.4)

	# 1) Zoom in + enfado del alien
	var t1 := create_tween()
	t1.set_parallel(true)
	t1.tween_property(battle_camera, "zoom", zoom_in, 0.32)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t1.tween_property(battle_camera, "position", lifted_pos, 0.32)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t1.tween_property(darken, "color:a", 0.22, 0.30)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await t1.finished

	await get_tree().create_timer(0.10).timeout

	if anger_symbol != null:
		anger_symbol.visible = true
		anger_symbol.modulate.a = 0.0
		anger_symbol.scale = Vector2(0.35, 0.35)

		var t2 := create_tween()
		t2.set_parallel(true)
		t2.tween_property(anger_symbol, "modulate:a", 1.0, 0.12)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t2.tween_property(anger_symbol, "scale", Vector2(1.28, 0.82), 0.14)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await t2.finished

		var t2b := create_tween()
		t2b.tween_property(anger_symbol, "scale", Vector2(0.92, 1.10), 0.10)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await t2b.finished

		var t2c := create_tween()
		t2c.tween_property(anger_symbol, "scale", Vector2(1.0, 1.0), 0.10)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await t2c.finished

	# 2) El gusano hace saltitos de "yo te ayudo"
	await play_worm_help_bounce()

	# 3) El alien hace pose de ataque/liberación
	await play_alien_worm_release_pose()

	await get_tree().create_timer(0.12).timeout

	# 4) Zoom out
	var t4 := create_tween()
	t4.set_parallel(true)
	t4.tween_property(battle_camera, "zoom", original_zoom, 0.34)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t4.tween_property(battle_camera, "position", original_pos, 0.34)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t4.tween_property(darken, "color:a", 0.0, 0.30)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	if anger_symbol != null:
		t4.tween_property(anger_symbol, "modulate:a", 0.0, 0.14)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t4.tween_property(anger_symbol, "scale", Vector2(0.82, 0.82), 0.14)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await t4.finished

	battle_camera.zoom = original_zoom
	battle_camera.position = original_pos

	if alien != null and is_instance_valid(alien):
		alien.rotation = original_alien_rot
		alien.scale = original_alien_scale

	if anger_symbol != null:
		anger_symbol.visible = false
		anger_symbol.modulate.a = 0.0
		anger_symbol.scale = Vector2.ONE

	if is_instance_valid(layer):
		layer.queue_free()


func play_phase_3_glitch_burst() -> void:
	if alien == null or not is_instance_valid(alien):
		return

	var base_pos: Vector2 = alien_sprite.global_position if alien_sprite != null else alien.global_position

	var offsets := [
		Vector2(-95, -35),
		Vector2(95, -30),
		Vector2(-110, 40),
		Vector2(110, 35),
		Vector2(0, -85),
		Vector2(0, 80)
	]

	var sizes := [
		Vector2(70, 42),
		Vector2(70, 42),
		Vector2(62, 62),
		Vector2(62, 62),
		Vector2(84, 34),
		Vector2(84, 34)
	]

	var flash_count: int = 4

	for i in range(flash_count):
		if alien != null and alien.has_method("set_antenna_color"):
			alien.set_antenna_color(Color(1, 1, 1, 1))

		for j in range(offsets.size()):
			var jitter := Vector2(
				randf_range(-6.0, 6.0),
				randf_range(-6.0, 6.0)
			)
			spawn_phase_3_transition_glitch(
				base_pos + offsets[j] + jitter,
				sizes[j],
				0.16
			)

		await get_tree().create_timer(0.07).timeout

		if alien != null and alien.has_method("set_antenna_phase_visual"):
			alien.set_antenna_phase_visual(3)

		await get_tree().create_timer(0.06).timeout
		

func spawn_phase_3_transition_glitch(pos: Vector2, size: Vector2, lifetime: float = 0.22) -> void:
	if glitch_zone_scene == null:
		return

	var parent_node: Node = alien.get_parent() if alien != null else summons
	if parent_node == null:
		parent_node = summons

	var glitch = glitch_zone_scene.instantiate()
	parent_node.add_child(glitch)

	if glitch is Node2D:
		glitch.global_position = pos

	if glitch.has_method("play_visual_burst"):
		glitch.play_visual_burst(self, size, lifetime)
		

func start_phase_2() -> void:
	worm_phase_3_escape_started = false

	if worm_instance != null and is_instance_valid(worm_instance):
		if worm_instance.has_method("activate"):
			worm_instance.activate()

	worm_phase_active = true


func play_worm_help_bounce() -> void:
	if worm_instance == null or not is_instance_valid(worm_instance):
		return

	var original_pos: Vector2 = worm_instance.global_position
	var original_rot: float = worm_instance.rotation
	var original_scale: Vector2 = worm_instance.scale

	for i in range(3):
		var t_up := create_tween()
		t_up.set_parallel(true)
		t_up.tween_property(worm_instance, "global_position", original_pos + Vector2(0.0, -22.0), 0.10)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t_up.tween_property(worm_instance, "rotation", -0.08, 0.10)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t_up.tween_property(worm_instance, "scale", original_scale * 1.06, 0.10)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await t_up.finished

		var t_down := create_tween()
		t_down.set_parallel(true)
		t_down.tween_property(worm_instance, "global_position", original_pos, 0.12)\
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		t_down.tween_property(worm_instance, "rotation", 0.06, 0.12)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t_down.tween_property(worm_instance, "scale", original_scale, 0.12)\
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		await t_down.finished

		await get_tree().create_timer(0.04).timeout

	if worm_instance != null and is_instance_valid(worm_instance):
		worm_instance.global_position = original_pos
		worm_instance.rotation = original_rot
		worm_instance.scale = original_scale


func play_alien_worm_release_pose() -> void:
	if alien == null or not is_instance_valid(alien):
		return

	if alien.has_method("set_worm_release_pose"):
		alien.set_worm_release_pose()

	await get_tree().create_timer(0.20).timeout

	if alien.has_method("set_idle_pose"):
		alien.set_idle_pose()
		

func start_phase_3() -> void:
	worm_instance = null
	worm_phase_active = false
	worm_phase_3_escape_started = false

	if not phase_3_zone_loop_started:
		phase_3_zone_loop_started = true
		call_deferred("start_phase_3_zone_loop")
		
		
func start_phase_3_zone_loop() -> void:
	while current_phase == BossPhase.PHASE_3 and not is_dead and not has_won:
		await spawn_random_glitch_zone()
		await get_tree().create_timer(3.8).timeout
		

func spawn_random_glitch_zone() -> void:
	if glitch_zone_scene == null:
		return

	cleanup_dead_glitch_zones()

	if not active_glitch_zones.is_empty():
		return

	await flash_alien_antennas_before_glitch_warning()
	await get_tree().create_timer(0.6).timeout

	var zone = glitch_zone_scene.instantiate()
	summons.add_child(zone)

	var arena_pos := arena_rect_global.position
	var arena_size := arena_rect_global.size
	var arena_center := arena_rect_global.get_center()

	var zone_size: Vector2
	var zone_pos: Vector2
	var margin: float = 6.0

	var pattern := randi() % 6

	match pattern:
		0:
			zone_size = Vector2(arena_size.x * 0.44, arena_size.y * 0.92)
			zone_pos = Vector2(
				arena_pos.x + zone_size.x * 0.5 + margin,
				arena_center.y
			)

		1:
			zone_size = Vector2(arena_size.x * 0.44, arena_size.y * 0.92)
			zone_pos = Vector2(
				arena_pos.x + arena_size.x - zone_size.x * 0.5 - margin,
				arena_center.y
			)

		2:
			zone_size = Vector2(arena_size.x * 0.44, arena_size.y * 0.44)
			zone_pos = Vector2(
				arena_pos.x + zone_size.x * 0.5 + margin,
				arena_pos.y + zone_size.y * 0.5 + margin
			)

		3:
			zone_size = Vector2(arena_size.x * 0.44, arena_size.y * 0.44)
			zone_pos = Vector2(
				arena_pos.x + arena_size.x - zone_size.x * 0.5 - margin,
				arena_pos.y + zone_size.y * 0.5 + margin
			)

		4:
			zone_size = Vector2(arena_size.x * 0.44, arena_size.y * 0.44)
			zone_pos = Vector2(
				arena_pos.x + zone_size.x * 0.5 + margin,
				arena_pos.y + arena_size.y - zone_size.y * 0.5 - margin
			)

		_:
			zone_size = Vector2(arena_size.x * 0.44, arena_size.y * 0.44)
			zone_pos = Vector2(
				arena_pos.x + arena_size.x - zone_size.x * 0.5 - margin,
				arena_pos.y + arena_size.y - zone_size.y * 0.5 - margin
			)

	zone.global_position = zone_pos

	if zone.has_method("setup"):
		zone.setup(self, zone_size)

	active_glitch_zones.append(zone)
	cleanup_dead_glitch_zones()
	

func clear_glitch_zones() -> void:
	for zone in active_glitch_zones:
		if zone != null and is_instance_valid(zone):
			zone.queue_free()

	active_glitch_zones.clear()
	phase_3_zone_loop_started = false


func cleanup_dead_glitch_zones() -> void:
	var valid_zones: Array[Area2D] = []

	for zone in active_glitch_zones:
		if zone != null and is_instance_valid(zone):
			valid_zones.append(zone)

	active_glitch_zones = valid_zones
	

func set_alien_antenna_color(color: Color) -> void:
	if alien != null and alien.has_method("set_antenna_color"):
		alien.set_antenna_color(color)


func flash_alien_antennas_before_glitch_warning() -> void:
	if alien == null or not is_instance_valid(alien):
		return

	var blink_total_time: float = 0.4
	var blink_step: float = 0.08
	var elapsed: float = 0.0
	var visible_white: bool = false

	while elapsed < blink_total_time:
		visible_white = not visible_white

		if visible_white:
			if alien.has_method("set_antenna_color"):
				alien.set_antenna_color(Color(1, 1, 1, 1))
		else:
			if alien.has_method("set_antenna_phase_visual"):
				alien.set_antenna_phase_visual(current_phase + 1)

		await get_tree().create_timer(blink_step).timeout
		elapsed += blink_step

	if alien != null and alien.has_method("set_antenna_phase_visual"):
		alien.set_antenna_phase_visual(current_phase + 1)
		

func _on_player_area_entered(area: Area2D) -> void:
	if is_dead or is_invulnerable or has_won or is_phase_transitioning:
		return

	if area == null or not is_instance_valid(area):
		return

	if area.is_in_group("enemy_attack"):
		take_damage(1)

		if not area.is_in_group("persistent_hazard"):
			if is_instance_valid(area):
				area.queue_free()


func take_damage(amount: int = 1) -> void:
	if is_dead or is_invulnerable or has_won or is_phase_transitioning:
		return

	is_invulnerable = true
	current_health = max(current_health - amount, 0)
	update_lives_ui()

	await play_player_hit_feedback()

	if current_health <= 0:
		die()
		return

	call_deferred("play_invulnerability_blink")


func get_player_visual_node() -> CanvasItem:
	for child in player.get_children():
		if child is CanvasItem:
			return child
	return null


func play_player_hit_feedback() -> void:
	var player_sprite := get_player_visual_node()
	if player_sprite == null:
		return

	var original_modulate: Color = player_sprite.modulate
	var original_scale: Vector2 = player.scale

	player_sprite.modulate = Color(1.0, 0.4, 0.4, 1.0)

	var t := create_tween()
	t.tween_property(player, "scale", original_scale * 1.25, 0.08)
	t.tween_property(player, "scale", original_scale, 0.10)

	await get_tree().create_timer(0.18).timeout

	if is_instance_valid(player_sprite):
		player_sprite.modulate = original_modulate


func play_invulnerability_blink() -> void:
	var player_visual := get_player_visual_node()
	if player_visual == null:
		await get_tree().create_timer(invulnerability_duration).timeout
		is_invulnerable = false
		return

	var blink_count: int = 6
	var step_time: float = invulnerability_duration / float(blink_count * 2)

	for i in range(blink_count):
		if not is_instance_valid(player_visual):
			break

		player_visual.modulate.a = 0.35
		await get_tree().create_timer(step_time).timeout

		if not is_instance_valid(player_visual):
			break

		player_visual.modulate.a = 1.0
		await get_tree().create_timer(step_time).timeout

	if is_instance_valid(player_visual):
		player_visual.modulate.a = 1.0

	is_invulnerable = false


func die() -> void:
	if is_dead or has_won or is_finishing:
		return

	is_dead = true
	set_process(false)
	remove_phase_2_worm()
	clear_glitch_zones()

	await finish_minigame_and_return(false)


func win() -> void:
	if has_won or is_dead or is_finishing:
		return

	has_won = true
	set_process(false)
	remove_phase_2_worm()
	clear_glitch_zones()

	await finish_minigame_and_return(true)


func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _process(delta: float) -> void:
	if is_dead or has_won:
		return
	
	update_background_fish_idle(delta)
	
	update_arena_rect()
	handle_player_mouse_movement()

	if not is_timer_paused:
		remaining_time = max(remaining_time - delta, 0.0)
		update_timer_ui()
		update_pre_phase_3_worm_escape()
		update_phase()

		if remaining_time <= 0.0:
			win()
			
			
func update_background_fish_idle(delta: float) -> void:
	if background_fish_sprites.is_empty():
		return

	background_fish_idle_time += delta

	for i in range(min(background_fish_sprites.size(), background_fish_idle_data.size())):
		var sprite := background_fish_sprites[i]
		if sprite == null or not is_instance_valid(sprite) or not sprite.visible:
			continue

		var idle_data: Dictionary = background_fish_idle_data[i]
		var base_position: Vector2 = idle_data.get("base_position", sprite.position)
		var base_rotation: float = idle_data.get("base_rotation", sprite.rotation)
		var base_scale: Vector2 = idle_data.get("base_scale", sprite.scale)
		var is_capsule: bool = bool(idle_data.get("is_capsule", false))

		var phase := float(i) * 1.37

		if is_capsule:
			# Más rígido: cápsula casi estática
			var y_offset := sin(background_fish_idle_time * 1.1 + phase) * 1.5
			var rot_offset := sin(background_fish_idle_time * 0.9 + phase) * 0.015

			sprite.position = base_position + Vector2(0.0, y_offset)
			sprite.rotation = base_rotation + rot_offset
			sprite.scale = base_scale
		else:
			# Pez: flotación suave y un pelín más orgánico
			var y_offset := sin(background_fish_idle_time * 1.6 + phase) * 2.5
			var rot_offset := sin(background_fish_idle_time * 1.2 + phase) * 0.045
			var scale_offset := sin(background_fish_idle_time * 1.8 + phase) * 0.025

			sprite.position = base_position + Vector2(0.0, y_offset)
			sprite.rotation = base_rotation + rot_offset
			sprite.scale = base_scale * (1.0 + scale_offset)


func play_return_transition() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 9999
	add_child(layer)

	var fade_rect := ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fade_rect)

	var t := create_tween()
	t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(fade_rect, "color:a", 1.0, 0.45)

	await t.finished


func finish_minigame_and_return(player_won: bool) -> void:
	if is_finishing:
		return

	is_finishing = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	GlobalData.set_pending_alien_result({
		"won": player_won,
		"timestamp": Time.get_unix_time_from_system()
	})

	await play_return_transition()
	get_tree().change_scene_to_file(RETURN_SCENE_PATH)


func update_arena_rect() -> void:
	arena_rect_global = arena_inner.get_global_rect()


func center_player_in_arena() -> void:
	player.global_position = arena_rect_global.get_center()


func handle_player_mouse_movement() -> void:
	if is_phase_transitioning:
		return

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()

	var clamped_x: float = clamp(
		mouse_pos.x,
		arena_rect_global.position.x + player_radius,
		arena_rect_global.position.x + arena_rect_global.size.x - player_radius
	)

	var clamped_y: float = clamp(
		mouse_pos.y,
		arena_rect_global.position.y + player_radius,
		arena_rect_global.position.y + arena_rect_global.size.y - player_radius
	)

	player.global_position = Vector2(clamped_x, clamped_y)

func get_fight_progress() -> float:
	return 1.0 - (remaining_time / survival_time_seconds)

func get_attack_delay() -> float:
	var progress: float = get_fight_progress()

	match current_phase:
		BossPhase.PHASE_1:
			return lerp(1.15, 0.80, progress * 1.5)
		BossPhase.PHASE_2:
			return lerp(0.90, 0.68, clamp((progress - 0.33) * 1.5, 0.0, 1.0))
		BossPhase.PHASE_3:
			return lerp(0.95, 0.72, clamp((progress - 0.66) * 3.0, 0.0, 1.0))

	return 0.75


func should_hold_attacks_for_phase_transition() -> bool:
	if is_phase_transitioning or is_dead or has_won:
		return true

	var transition_buffer: float = 0.8

	match current_phase:
		BossPhase.PHASE_1:
			return remaining_time <= survival_time_seconds * (2.0 / 3.0) + transition_buffer
		BossPhase.PHASE_2:
			return remaining_time <= survival_time_seconds * (1.0 / 3.0) + transition_buffer
		BossPhase.PHASE_3:
			return false

	return false


func start_attack_loop() -> void:
	while true:
		if is_dead or has_won:
			return

		if pending_phase != -1 and pending_phase != current_phase and not is_attack_running:
			var phase_to_apply := pending_phase
			pending_phase = -1
			await run_phase_transition_after_attack(phase_to_apply)
			continue

		if should_hold_attacks_for_phase_transition():
			await get_tree().create_timer(0.05).timeout
			continue

		await get_tree().create_timer(get_attack_delay()).timeout

		if is_dead or has_won:
			return

		if is_phase_transitioning:
			continue

		if pending_phase != -1 and pending_phase != current_phase:
			var phase_to_apply := pending_phase
			pending_phase = -1
			await run_phase_transition_after_attack(phase_to_apply)
			continue

		if should_hold_attacks_for_phase_transition():
			continue

		await perform_next_attack()
		

func perform_next_attack() -> void:
	is_attack_running = true

	match current_phase:
		BossPhase.PHASE_1:
			await perform_phase_1_attack()
		BossPhase.PHASE_2:
			await perform_phase_2_attack()
		BossPhase.PHASE_3:
			await perform_phase_3_attack()

	is_attack_running = false

	if is_dead or has_won:
		return

	if pending_phase != -1 and pending_phase != current_phase:
		var phase_to_apply := pending_phase
		pending_phase = -1
		await run_phase_transition_after_attack(phase_to_apply)
		

func prepare_phase_3_transition() -> void:
	if worm_instance == null or not is_instance_valid(worm_instance):
		worm_instance = null
		worm_phase_active = false
		return

	if not worm_phase_3_escape_started and worm_instance.has_method("escape_to_side"):
		worm_instance.escape_to_side()

	await get_tree().create_timer(0.45).timeout

	if worm_instance != null and is_instance_valid(worm_instance):
		worm_instance.queue_free()

	worm_instance = null
	worm_phase_active = false
	

func update_pre_phase_3_worm_escape() -> void:
	if current_phase != BossPhase.PHASE_2:
		return

	if worm_phase_3_escape_started:
		return

	if worm_instance == null or not is_instance_valid(worm_instance):
		return

	var phase_3_threshold_time: float = survival_time_seconds * (1.0 / 3.0)

	if remaining_time <= phase_3_threshold_time + WORM_ESCAPE_BEFORE_PHASE_3_SECONDS:
		worm_phase_3_escape_started = true

		if worm_instance.has_method("escape_to_side"):
			worm_instance.escape_to_side()


func wait_until_attacks_clear(timeout: float = 2.0) -> void:
	var elapsed: float = 0.0
	var step: float = 0.05

	while elapsed < timeout:
		if attacks == null or not is_instance_valid(attacks):
			return

		if attacks.get_child_count() == 0:
			return

		await get_tree().create_timer(step).timeout
		elapsed += step


func run_phase_transition_after_attack(new_phase: int) -> void:
	if is_phase_transitioning or is_dead or has_won:
		return

	is_phase_transitioning = true
	is_timer_paused = true

	if new_phase == BossPhase.PHASE_3:
		await prepare_phase_3_transition()

	await wait_until_attacks_clear(2.0)

	current_phase = new_phase
	await _run_phase_transition(new_phase)

	is_timer_paused = false
	is_phase_transitioning = false
	

func spawn_idle_worm() -> void:
	if worm_scene == null:
		return

	if worm_instance != null and is_instance_valid(worm_instance):
		return

	var worm := worm_scene.instantiate()
	summons.add_child(worm)
	worm.scale = Vector2(0.05, 0.05)

	if worm.has_method("setup"):
		worm.setup(player, self, alien)

	worm_instance = worm
	worm_phase_active = false


func remove_phase_2_worm() -> void:
	if worm_instance != null and is_instance_valid(worm_instance):
		worm_instance.queue_free()

	worm_instance = null
	worm_phase_active = false
	

func perform_phase_1_attack() -> void:
	var progress: float = get_fight_progress()

	#var simple_pool: Array[int] = [29]
	var simple_pool: Array[int] = [4, 6, 24, 25]
	var medium_pool: Array[int] = [28, 30]

	var pool: Array[int] = simple_pool.duplicate()
	if progress > 0.25:
		pool.append_array(medium_pool)

	await execute_attack_by_id(pick_attack_from_pool(pool))


func perform_phase_2_attack() -> void:
	var progress: float = get_fight_progress()

	var medium_pool: Array[int] = [4, 6, 8, 10, 14, 15, 16, 17, 24, 25, 27, 28, 30]
	var hard_pool: Array[int] = [2, 13, 18, 19, 21]

	var pool: Array[int] = medium_pool.duplicate()
	if progress > 0.50:
		pool.append_array(hard_pool)

	await execute_attack_by_id(pick_attack_from_pool(pool))


func perform_phase_3_attack() -> void:
	var progress: float = get_fight_progress()

	var base_pool: Array[int] = [2, 8, 13, 14, 15, 16, 18, 27, 29, 30]
	var extreme_pool: Array[int] = [19, 20, 21, 22, 26]

	var pool: Array[int] = base_pool.duplicate()

	# Solo mete las peores cuando ya vas bastante avanzado
	if progress > 0.88:
		pool.append_array(extreme_pool)

	await execute_attack_by_id(pick_attack_from_pool(pool))

func pick_attack_from_pool(pool: Array[int]) -> int:
	var valid_pool: Array[int] = []

	for attack_id in pool:
		if not recent_attacks.has(attack_id):
			valid_pool.append(attack_id)

	if valid_pool.is_empty():
		valid_pool = pool.duplicate()

	var chosen: int = valid_pool[randi() % valid_pool.size()]
	register_recent_attack(chosen)
	return chosen


func register_recent_attack(attack_id: int) -> void:
	recent_attacks.append(attack_id)
	while recent_attacks.size() > MAX_RECENT_ATTACKS:
		recent_attacks.remove_at(0)

func execute_attack_by_id(next_attack: int) -> void:
	match next_attack:
		# =========================================================
		# BOSS PURO
		# =========================================================
		0:
			await boss_patterns.combo_side_pincer_then_snipe()
		1:
			await boss_patterns.combo_lateral_checkmate()
		2:
			await boss_patterns.alien_fire_double_spiral()
		3:
			await boss_patterns.alien_fire_tracking_sweep()
		4:
			await boss_patterns.alien_fire_broken_columns()
		5:
			await boss_patterns.alien_fire_spiral_then_burst()
		6:
			await boss_patterns.alien_fire_open_close_curtain()
		7:
			await boss_patterns.alien_fire_broken_ring_then_snipe()
		8:
			await boss_patterns.alien_fire_counter_rotating_spirals()
		9:
			await boss_patterns.alien_fire_solar_crown()

		# Nuevos boss puro
		28:
			await boss_patterns.alien_fire_side_swap_fan()
		29:
			await boss_patterns.alien_fire_snake_wall()

		# =========================================================
		# BOSS + GUNS / LATERALES
		# =========================================================
		10:
			await boss_patterns.combo_side_cross_grid()
		11:
			await boss_patterns.combo_boss_fan_plus_left_right_guns()
		12:
			await boss_patterns.combo_boss_aimed_plus_side_guns()
		13:
			await boss_patterns.combo_boss_burst_plus_corners()
		14:
			await boss_patterns.combo_side_trap_and_center_burst()
		15:
			await boss_patterns.combo_pincer_attack()
		16:
			await boss_patterns.combo_descending_pincer()
		17:
			await boss_patterns.combo_side_machinegun_and_rain()
		24:
			await boss_patterns.combo_side_walls()
		27:
			await boss_patterns.combo_tracking_angle_guns_staggered_stream()
		30:
			await boss_patterns.combo_side_lane_grid()

		# =========================================================
		# CORNERS / ESPECIALES
		# =========================================================
		18:
			await boss_patterns.combo_corner_collapse()
		19:
			await boss_patterns.alien_fire_supernova_bloom()
		20:
			await boss_patterns.combo_crown_judgement()
		21:
			await boss_patterns.alien_fire_binary_eclipse()
		22:
			await boss_patterns.combo_celestial_throne()
		23:
			await boss_patterns.alien_fire_end_of_days()
		25:
			await boss_patterns.alien_fire_grid_fall()
		26:
			await boss_patterns.floating_gun_grid_interlaced()
