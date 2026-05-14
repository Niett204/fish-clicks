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
@export var survival_time_seconds: float = 90.0
@export var intro_lines: Array[String] = [
	"Has llegado lejos para ser una criatura tan inferior.",
	"Ahora entretenme un poco antes de perder."
]
@export var intro_text_speed: float = 0.025
@export var intro_hold_time: float = 1.0
@export var defeat_shell_texture: Texture2D

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

const AUSPICIO_TIME_REDUCTION_PER_LEVEL := 2.0
const AUSPICIO_VOICE_1 := preload("res://assets/audio/alien/auspi_1.wav")
const AUSPICIO_VOICE_2 := preload("res://assets/audio/alien/auspi_2.wav")
const SFX_GLITCH := preload("res://assets/audio/alien/glitch.wav")
const SFX_WIN_EXPLOSION := preload("res://assets/audio/alien/win_explosion.wav")
const MUSIC_ALIEN_MINIGAME := preload("res://assets/audio/alien/boss_alien.wav")
const MIN_SURVIVAL_TIME_SECONDS := 10.0

enum BossPhase {
	PHASE_1,
	PHASE_2,
	PHASE_3
}

var current_phase: int = BossPhase.PHASE_1
var intro_voice_player: AudioStreamPlayer
var global_sfx_player: AudioStreamPlayer
var battle_music_player: AudioStreamPlayer

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
var intro_played: bool = false
var enchant_font := preload("res://assets/fuentes/minecraft-enchantment.ttf")
var boss_name_font := preload("res://assets/fuentes/extragalactic.regular.ttf")
var alien_green := Color("5bb010")
var bubble_bg := Color(0.03, 0.05, 0.05, 0.90)
var intro_camera_original_zoom: Vector2 = Vector2.ONE
var intro_camera_original_pos: Vector2 = Vector2.ZERO
var intro_camera_initial_zoom: Vector2 = Vector2(3.2, 3.2)
var is_winning_sequence: bool = false
var damage_taken_count: int = 0

func _ready() -> void:
	battle_music_player = AudioStreamPlayer.new()
	battle_music_player.bus = "Musica"
	add_child(battle_music_player)

	battle_music_player.stream = MUSIC_ALIEN_MINIGAME
	battle_music_player.play()

	intro_voice_player = AudioStreamPlayer.new()
	intro_voice_player.bus = "Efectos"
	add_child(intro_voice_player)
	
	global_sfx_player = AudioStreamPlayer.new()
	global_sfx_player.bus= "Efectos"
	add_child(global_sfx_player)

	attack_utils = AlienAttackUtilsScript.new()
	add_child(attack_utils)
	attack_utils.setup(self)

	boss_patterns = AlienBossPatternsScript.new()
	add_child(boss_patterns)
	boss_patterns.setup(self, attack_utils)

	gun_patterns = AlienGunPatternsScript.new()
	add_child(gun_patterns)
	gun_patterns.setup(self, attack_utils)

	update_arena_rect()
	center_player_in_arena()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	if alien.has_method("set_idle_pose"):
		alien.set_idle_pose()

	base_alien_scale = alien.scale
	base_alien_rotation = alien.rotation

	setup_health_system()
	apply_auspezio_survival_time_buff()
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

	# Guardamos la vista normal
	intro_camera_original_zoom = battle_camera.zoom
	intro_camera_original_pos = battle_camera.position

	# Forzamos la cámara cerrada ANTES del primer frame visible
	battle_camera.zoom = intro_camera_initial_zoom
	battle_camera.position = player.global_position

	is_timer_paused = true

	# Esperamos un frame ya con la cámara cerrada aplicada
	await get_tree().process_frame

	await play_intro_camera_focus()
	await play_boss_intro()
	is_timer_paused = false

	start_attack_loop()


func apply_auspezio_survival_time_buff() -> void:
	var auspezio_level: int = GlobalData.consume_pending_auspezio_level()

	if auspezio_level <= 0:
		return

	var reduction: float = float(auspezio_level) * AUSPICIO_TIME_REDUCTION_PER_LEVEL
	survival_time_seconds = max(MIN_SURVIVAL_TIME_SECONDS, survival_time_seconds - reduction)


func play_intro_camera_focus() -> void:
	if battle_camera == null or not is_instance_valid(battle_camera):
		return

	if player == null or not is_instance_valid(player):
		return

	center_player_in_arena()
	update_arena_rect()

	var layer := CanvasLayer.new()
	layer.layer = 9998
	add_child(layer)

	var darken := ColorRect.new()
	darken.color = Color(0, 0, 0, 0.22)
	darken.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(darken)

	# Reafirma el plano cerrado por si acaso
	battle_camera.zoom = intro_camera_initial_zoom
	battle_camera.position = player.global_position

	# Mantener un poco el plano cerrado
	await get_tree().create_timer(1.0).timeout

	# Zoom out lento a la vista normal
	var t_out := create_tween()
	t_out.set_parallel(true)
	t_out.tween_property(battle_camera, "zoom", intro_camera_original_zoom, 1.45)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t_out.tween_property(battle_camera, "position", intro_camera_original_pos, 1.45)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t_out.tween_property(darken, "color:a", 0.0, 0.95)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t_out.finished

	battle_camera.zoom = intro_camera_original_zoom
	battle_camera.position = intro_camera_original_pos

	if is_instance_valid(layer):
		layer.queue_free()


func play_boss_intro() -> void:
	if intro_played:
		return

	intro_played = true
	update_arena_rect()

	var layer := CanvasLayer.new()
	layer.layer = 10000
	add_child(layer)

	# Oscurecer solo el área de combate
	var arena_overlay := ColorRect.new()
	arena_overlay.color = Color(0, 0, 0, 0.0)
	arena_overlay.position = arena_rect_global.position
	arena_overlay.size = arena_rect_global.size
	layer.add_child(arena_overlay)

	# Tamaño y posición del bocadillo dentro del área de combate
	var bubble_size := Vector2(430, 115)
	var bubble_pos := Vector2(
		arena_rect_global.get_center().x - bubble_size.x * 0.5,
		arena_rect_global.position.y + 28
	)

	var bubble_panel := PanelContainer.new()
	bubble_panel.custom_minimum_size = bubble_size
	bubble_panel.position = bubble_pos
	bubble_panel.modulate.a = 0.0
	layer.add_child(bubble_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = bubble_bg
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = alien_green
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 6
	bubble_panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	bubble_panel.add_child(margin)

	var bubble_label := Label.new()
	bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bubble_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bubble_label.text = ""
	bubble_label.add_theme_font_override("font", enchant_font)
	bubble_label.add_theme_font_size_override("font_size", 22)
	bubble_label.add_theme_color_override("font_color", Color(0.86, 1.0, 0.90))
	bubble_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	bubble_label.add_theme_constant_override("outline_size", 5)
	margin.add_child(bubble_label)

	# Tag del nombre dentro del área de combate
	var name_tag := PanelContainer.new()
	name_tag.position = bubble_pos + Vector2(14, -20)
	name_tag.modulate.a = 0.0
	layer.add_child(name_tag)

	var name_style := StyleBoxFlat.new()
	name_style.bg_color = Color(0.07, 0.11, 0.07, 0.95)
	name_style.border_width_left = 2
	name_style.border_width_top = 2
	name_style.border_width_right = 2
	name_style.border_width_bottom = 2
	name_style.border_color = alien_green
	name_style.corner_radius_top_left = 10
	name_style.corner_radius_top_right = 10
	name_style.corner_radius_bottom_left = 10
	name_style.corner_radius_bottom_right = 10
	name_tag.add_theme_stylebox_override("panel", name_style)

	var name_margin := MarginContainer.new()
	name_margin.add_theme_constant_override("margin_left", 10)
	name_margin.add_theme_constant_override("margin_right", 10)
	name_margin.add_theme_constant_override("margin_top", 4)
	name_margin.add_theme_constant_override("margin_bottom", 4)
	name_tag.add_child(name_margin)

	var name_label := Label.new()
	name_label.text = "AUSPICIO"
	name_label.add_theme_font_override("font", boss_name_font)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.90, 1.0, 0.92))
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	name_label.add_theme_constant_override("outline_size", 2)
	name_margin.add_child(name_label)

	var t_in := create_tween()
	t_in.set_parallel(true)
	t_in.tween_property(arena_overlay, "color:a", 0.22, 0.20)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t_in.tween_property(bubble_panel, "modulate:a", 1.0, 0.20)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t_in.tween_property(name_tag, "modulate:a", 1.0, 0.20)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await t_in.finished

	for i in range(intro_lines.size()):
		var line: String = intro_lines[i]

		play_intro_voice_line(i)

		await type_text(bubble_label, line, intro_text_speed)
		await get_tree().create_timer(intro_hold_time).timeout
		bubble_label.text = ""

	var t_out := create_tween()
	t_out.set_parallel(true)
	t_out.tween_property(arena_overlay, "color:a", 0.0, 0.18)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t_out.tween_property(bubble_panel, "modulate:a", 0.0, 0.18)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t_out.tween_property(name_tag, "modulate:a", 0.0, 0.18)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t_out.finished

	if is_instance_valid(layer):
		layer.queue_free()


func type_text(label: Label, full_text: String, speed: float = 0.025) -> void:
	label.text = ""

	for i in range(full_text.length()):
		label.text += full_text[i]
		await get_tree().create_timer(speed).timeout
	
func play_intro_voice_line(index: int) -> void:
	if intro_voice_player == null:
		return

	var stream: AudioStream = null

	match index:
		0:
			stream = AUSPICIO_VOICE_1
		1:
			stream = AUSPICIO_VOICE_2

	if stream == null:
		return

	intro_voice_player.stop()
	intro_voice_player.stream = stream
	intro_voice_player.play()
	
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

		var final_rotation := fish_sprite.rotation
		var final_scale := fish_sprite.scale

		# Caso especial: Leonardo es muy grande
		if texture_path.to_lower().contains("leonardo"):
			final_scale *= 0.65

			# Peces de la izquierda: Pez y Pez3 normalmente son índice 0 y 2
			if i == 0 or i == 2:
				final_rotation += deg_to_rad(53)
			else:
				final_rotation -= deg_to_rad(53)

		fish_sprite.rotation = final_rotation
		fish_sprite.scale = final_scale

		background_fish_idle_data.append({
			"base_position": fish_sprite.position,
			"base_rotation": final_rotation,
			"base_scale": final_scale,
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
	while current_phase == BossPhase.PHASE_3 and not is_dead and not has_won and not is_winning_sequence:
		await spawn_random_glitch_zone()

		if is_winning_sequence or has_won or is_dead:
			return

		await get_tree().create_timer(3.8).timeout
		

func spawn_random_glitch_zone() -> void:
	if glitch_zone_scene == null:
		return

	if is_winning_sequence or has_won or is_dead:
		return

	cleanup_dead_glitch_zones()

	if not active_glitch_zones.is_empty():
		return

	await flash_alien_antennas_before_glitch_warning()

	if is_winning_sequence or has_won or is_dead:
		return

	await get_tree().create_timer(0.6).timeout

	if is_winning_sequence or has_won or is_dead:
		return

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

	if is_winning_sequence or has_won or is_dead:
		return

	var blink_total_time: float = 0.4
	var blink_step: float = 0.08
	var elapsed: float = 0.0
	var visible_white: bool = false

	while elapsed < blink_total_time:
		if is_winning_sequence or has_won or is_dead:
			return

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
	if is_dead or is_invulnerable or has_won or is_phase_transitioning or is_winning_sequence:
		return

	if area == null or not is_instance_valid(area):
		return

	if area.is_in_group("enemy_attack"):
		take_damage(1)

		if not area.is_in_group("persistent_hazard"):
			if is_instance_valid(area):
				area.queue_free()


func take_damage(amount: int = 1) -> void:
	if is_dead or is_invulnerable or has_won or is_phase_transitioning or is_winning_sequence:
		return

	damage_taken_count += 1

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
	if is_dead or has_won or is_finishing or is_winning_sequence:
		return

	is_dead = true
	play_glitch_sfx()
	
	set_process(false)
	remove_phase_2_worm()
	clear_glitch_zones()
	clear_remaining_attacks()

	await play_lose_sequence()
	await finish_minigame_and_return(false, true)


func play_lose_sequence() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10002
	add_child(layer)

	var fade_rect := ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0.0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fade_rect)

	# 1) Fundido a negro
	var t_fade := create_tween()
	t_fade.tween_property(fade_rect, "color:a", 1.0, 0.35)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t_fade.finished

	# 2) Concha en el centro
	var shell := TextureRect.new()
	shell.texture = defeat_shell_texture if defeat_shell_texture != null else shell_empty_texture
	shell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shell.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shell.size = Vector2(140, 140)

	var viewport_size := get_viewport_rect().size
	shell.position = viewport_size * 0.5 - shell.size * 0.5
	shell.modulate = Color(1, 1, 1, 0.0)
	shell.scale = Vector2(0.75, 0.75)
	layer.add_child(shell)

	var t_shell_in := create_tween()
	t_shell_in.set_parallel(true)
	t_shell_in.tween_property(shell, "modulate:a", 1.0, 0.20)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t_shell_in.tween_property(shell, "scale", Vector2(1.0, 1.0), 0.22)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t_shell_in.finished

	await get_tree().create_timer(0.35).timeout

	# 3) "Se apaga" lento
	var t_shell_off := create_tween()
	t_shell_off.set_parallel(true)
	t_shell_off.tween_property(shell, "modulate", Color(0.10, 0.10, 0.10, 1.0), 1.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t_shell_off.tween_property(shell, "scale", Vector2(0.86, 0.86), 1.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t_shell_off.finished

	await get_tree().create_timer(0.22).timeout

	# 4) Burst de glitches sobre negro
	await play_lose_glitch_burst(layer)

	# Asegurar negro total
	fade_rect.color = Color(0, 0, 0, 1.0)
	await get_tree().process_frame



func play_lose_glitch_burst(parent_layer: CanvasLayer) -> void:
	play_glitch_sfx()
	
	var total_duration: float = 1.45
	var elapsed: float = 0.0
	var interval: float = 0.055

	while elapsed < total_duration:
		var burst_count := 3
		if elapsed > 0.35:
			burst_count = 5
		if elapsed > 0.75:
			burst_count = 7
		if elapsed > 1.05:
			burst_count = 9

		for i in range(burst_count):
			spawn_lose_glitch(parent_layer)

		elapsed += interval
		await get_tree().create_timer(interval).timeout


func spawn_lose_glitch(parent_layer: CanvasLayer) -> void:
	if glitch_zone_scene == null:
		return

	var viewport_size := get_viewport_rect().size

	var pos := Vector2(
		randf_range(0.0, viewport_size.x),
		randf_range(0.0, viewport_size.y)
	)

	var size := Vector2(
		randf_range(70.0, 180.0),
		randf_range(24.0, 90.0)
	)

	var glitch = glitch_zone_scene.instantiate()
	parent_layer.add_child(glitch)

	if glitch is Node2D:
		glitch.global_position = pos

	if glitch.has_method("play_visual_burst"):
		glitch.play_visual_burst(self, size, randf_range(0.18, 0.32))

func play_glitch_sfx() -> void:
	var sfx := AudioStreamPlayer.new()
	sfx.bus = "Efectos"
	sfx.stream = SFX_GLITCH
	get_tree().root.add_child(sfx)
	sfx.play()

	sfx.finished.connect(func():
		if is_instance_valid(sfx):
			sfx.queue_free()
	)
	
func play_win_explosion_sfx() -> void:
	var sfx := AudioStreamPlayer.new()
	sfx.bus = "Efectos"
	sfx.stream = SFX_WIN_EXPLOSION
	get_tree().root.add_child(sfx)
	sfx.play()

	sfx.finished.connect(func():
		if is_instance_valid(sfx):
			sfx.queue_free()
	)

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
	
	if battle_music_player != null:
		battle_music_player.stop()


func _process(delta: float) -> void:
	if is_dead or has_won:
		return
	
	update_background_fish_idle(delta)
	update_arena_rect()

	# Permitir mover al player siempre, excepto durante la intro inicial
	if intro_played:
		handle_player_mouse_movement()

	if not is_timer_paused:
		remaining_time = max(remaining_time - delta, 0.0)
		update_timer_ui()
		update_pre_phase_3_worm_escape()
		update_phase()

		if remaining_time <= 0.0 and not is_winning_sequence:
			start_win_sequence()


func start_win_sequence() -> void:
	if is_winning_sequence or has_won or is_dead or is_finishing:
		return

	is_winning_sequence = true
	is_timer_paused = true
	phase_3_zone_loop_started = false

	call_deferred("_run_win_sequence")


func _run_win_sequence() -> void:
	clear_remaining_attacks()
	clear_glitch_zones()
	remove_phase_2_worm()

	await play_win_explosion_sequence()
	await finish_minigame_and_return(true, true)


func clear_remaining_attacks() -> void:
	if attacks == null or not is_instance_valid(attacks):
		return

	for child in attacks.get_children():
		if child != null and is_instance_valid(child):
			child.queue_free()


func play_win_explosion_sequence() -> void:
	play_win_explosion_sfx()
	
	var layer := CanvasLayer.new()
	layer.layer = 10001
	add_child(layer)

	var fade_rect := ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0.0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fade_rect)

	if alien_sprite != null and is_instance_valid(alien_sprite):
		alien_sprite.modulate = Color(1, 1, 1, 1)

	var total_duration: float = 2.4
	var elapsed: float = 0.0
	var interval: float = 0.05

	# El negro sube durante toda la secuencia
	var fade_t := create_tween()
	fade_t.tween_property(fade_rect, "color:a", 1.0, total_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	while elapsed < total_duration:
		var burst_count := 3
		if elapsed > 0.6:
			burst_count = 4
		if elapsed > 1.2:
			burst_count = 5

		for i in range(burst_count):
			spawn_win_explosion(layer)

		elapsed += interval
		await get_tree().create_timer(interval).timeout

	# Asegurar negro total al final
	fade_rect.color = Color(0, 0, 0, 1)

	# Espera mínima para que el último frame visible ya sea completamente negro
	await get_tree().process_frame


func spawn_win_explosion(parent_layer: CanvasLayer) -> void:
	var viewport_size := get_viewport_rect().size

	# 35% cerca del alien, 65% por toda la pantalla
	var use_alien_focus := randf() < 0.35 and alien_sprite != null and is_instance_valid(alien_sprite)

	var pos: Vector2
	if use_alien_focus:
		pos = alien_sprite.global_position + Vector2(
			randf_range(-180.0, 180.0),
			randf_range(-130.0, 130.0)
		)
	else:
		pos = Vector2(
			randf_range(0.0, viewport_size.x),
			randf_range(0.0, viewport_size.y)
		)

	# Capa exterior grande
	var outer := ColorRect.new()
	var outer_size := randf_range(110.0, 220.0)
	outer.size = Vector2(outer_size, outer_size)
	outer.position = pos - outer.size * 0.5
	outer.color = Color(
		1.0,
		randf_range(0.28, 0.55),
		0.05,
		0.78
	)
	parent_layer.add_child(outer)

	# Capa media
	var mid := ColorRect.new()
	var mid_size := outer_size * randf_range(0.55, 0.74)
	mid.size = Vector2(mid_size, mid_size)
	mid.position = pos - mid.size * 0.5
	mid.color = Color(
		1.0,
		randf_range(0.55, 0.85),
		0.08,
		0.92
	)
	parent_layer.add_child(mid)

	# Núcleo
	var inner := ColorRect.new()
	var inner_size := outer_size * randf_range(0.22, 0.34)
	inner.size = Vector2(inner_size, inner_size)
	inner.position = pos - inner.size * 0.5
	inner.color = Color(1.0, 0.95, 0.78, 1.0)
	parent_layer.add_child(inner)

	# Chispas
	var spark_count := randi_range(6, 10)
	var sparks: Array[ColorRect] = []

	for i in range(spark_count):
		var spark := ColorRect.new()
		var spark_size := randf_range(10.0, 24.0)
		spark.size = Vector2(spark_size, spark_size)
		spark.position = pos + Vector2(
			randf_range(-45.0, 45.0),
			randf_range(-45.0, 45.0)
		) - spark.size * 0.5
		spark.color = Color(
			1.0,
			randf_range(0.75, 1.0),
			randf_range(0.15, 0.35),
			0.95
		)
		parent_layer.add_child(spark)
		sparks.append(spark)

	# Flash
	var flash := ColorRect.new()
	var flash_size := outer_size * 1.35
	flash.size = Vector2(flash_size, flash_size)
	flash.position = pos - flash.size * 0.5
	flash.color = Color(1, 1, 1, 0.25)
	parent_layer.add_child(flash)

	shake_camera_small()

	var t_outer := create_tween()
	t_outer.set_parallel(true)
	t_outer.tween_property(outer, "scale", Vector2(2.1, 2.1), 0.36)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t_outer.tween_property(outer, "modulate:a", 0.0, 0.38)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var t_mid := create_tween()
	t_mid.set_parallel(true)
	t_mid.tween_property(mid, "scale", Vector2(1.8, 1.8), 0.30)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t_mid.tween_property(mid, "modulate:a", 0.0, 0.32)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var t_inner := create_tween()
	t_inner.set_parallel(true)
	t_inner.tween_property(inner, "scale", Vector2(1.45, 1.45), 0.20)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t_inner.tween_property(inner, "modulate:a", 0.0, 0.22)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var t_flash := create_tween()
	t_flash.set_parallel(true)
	t_flash.tween_property(flash, "scale", Vector2(1.6, 1.6), 0.14)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t_flash.tween_property(flash, "modulate:a", 0.0, 0.16)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	for spark in sparks:
		var spark_dir := Vector2(
			randf_range(-95.0, 95.0),
			randf_range(-95.0, 95.0)
		)

		var t_spark := create_tween()
		t_spark.set_parallel(true)
		t_spark.tween_property(spark, "position", spark.position + spark_dir, 0.30)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t_spark.tween_property(spark, "modulate:a", 0.0, 0.30)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await get_tree().create_timer(0.42).timeout

	for node in [outer, mid, inner, flash]:
		if node != null and is_instance_valid(node):
			node.queue_free()

	for spark in sparks:
		if spark != null and is_instance_valid(spark):
			spark.queue_free()


func shake_camera_small() -> void:
	if battle_camera == null or not is_instance_valid(battle_camera):
		return

	var original_pos := battle_camera.position
	var offset := Vector2(
		randf_range(-8.0, 8.0),
		randf_range(-8.0, 8.0)
	)

	var t := create_tween()
	t.tween_property(battle_camera, "position", original_pos + offset, 0.04)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(battle_camera, "position", original_pos, 0.06)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


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


func finish_minigame_and_return(player_won: bool, skip_transition: bool = false) -> void:
	if is_finishing:
		return

	is_finishing = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	GlobalData.set_pending_alien_result({
		"won": player_won,
		"no_hit": player_won and damage_taken_count <= 0,
		"timestamp": Time.get_unix_time_from_system()
	})

	if not skip_transition:
		await play_return_transition()

	get_tree().change_scene_to_file(RETURN_SCENE_PATH)


func update_arena_rect() -> void:
	arena_rect_global = arena_inner.get_global_rect()


func center_player_in_arena() -> void:
	player.global_position = arena_rect_global.get_center()


func handle_player_mouse_movement() -> void:
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
		if is_dead or has_won or is_winning_sequence:
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
	if is_dead or has_won or is_winning_sequence:
		return

	is_attack_running = true

	match current_phase:
		BossPhase.PHASE_1:
			await perform_phase_1_attack()
		BossPhase.PHASE_2:
			await perform_phase_2_attack()
		BossPhase.PHASE_3:
			await perform_phase_3_attack()

	is_attack_running = false

	if is_dead or has_won or is_winning_sequence:
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
