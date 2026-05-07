extends Node
class_name AlienManager

enum AlienEventState {
	IDLE,
	ABDUCTING,
	WAITING_FOR_CLICK,
	MINIGAME
}

const UNLOCK_FISH_COUNT := 50
const MINIGAME_DISPLAY_FISH_COUNT := 4
const ALIEN_SCENE := preload("res://scenes/alien.tscn")
const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const ALIEN_MINIGAME_COOLDOWN_SECONDS := 600.0
const ALIEN_EVENT_TRIGGER_CHANCE := 0.15
const ALIEN_EVENT_STARTUP_GRACE_SECONDS := 180.0

var main: Node = null
var alien_event_state := AlienEventState.IDLE
var alien_event_available := false
var alien_event_done := false
var alien_instance: Node2D = null
var abducted_fish_snapshots: Array[Dictionary] = []
var abduct_return_origin: Vector2 = Vector2.ZERO
var alien_escape_fx_active: bool = false
var manager_started_unix: float = 0.0

func setup(main_ref: Node) -> void:
	main = main_ref
	manager_started_unix = float(Time.get_unix_time_from_system())

func check_alien_event_unlock() -> void:
	if get_total_fish_count() < UNLOCK_FISH_COUNT:
		alien_event_available = false
		return

	alien_event_available = not is_alien_minigame_on_cooldown()

func try_start_alien_event() -> void:
	if not can_trigger_alien_event():
		return

	if randf() > ALIEN_EVENT_TRIGGER_CHANCE:
		return

	call_deferred("start_alien_event")

func start_alien_event() -> void:
	alien_event_state = AlienEventState.ABDUCTING

	if main.ui_manager != null:
		main.ui_manager.close_all_panels()

	if main.has_method("update_ui_block_state"):
		main.update_ui_block_state()

	call_deferred("_start_alien_event_flow")

func _start_alien_event_flow() -> void:
	await spawn_and_enter_alien()

	if alien_instance != null and alien_instance.has_method("set_waiting_for_click"):
		alien_instance.set_waiting_for_click(false)

	if alien_instance != null and alien_instance.has_method("show_beam"):
		alien_instance.show_beam()

	await start_aquarium_abduction_sequence()

func spawn_and_enter_alien() -> void:
	alien_instance = ALIEN_SCENE.instantiate() as Node2D
	if alien_instance == null:
		return

	main.add_child(alien_instance)

	if alien_instance.has_signal("clicked"):
		alien_instance.clicked.connect(_on_alien_clicked)

	var screen_size: Vector2 = main.get_viewport_rect().size
	var final_pos: Vector2 = Vector2(screen_size.x * 0.5, 100)

	# Empieza fuera de pantalla, arriba
	alien_instance.position = Vector2(final_pos.x, -180)

	await animate_alien_zigzag_entry(final_pos)
	
func animate_alien_zigzag_entry(final_pos: Vector2) -> void:
	if alien_instance == null or not is_instance_valid(alien_instance):
		return

	var p1 := Vector2(final_pos.x - 120, -40)
	var p2 := Vector2(final_pos.x + 100, 10)
	var p3 := Vector2(final_pos.x - 70, 55)
	var p4 := final_pos

	var t := main.create_tween()

	t.set_parallel(true)
	t.tween_property(alien_instance, "position", p1, 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(alien_instance, "rotation", -0.18, 0.35)
	await t.finished

	t = main.create_tween()
	t.set_parallel(true)
	t.tween_property(alien_instance, "position", p2, 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(alien_instance, "rotation", 0.16, 0.35)
	await t.finished

	t = main.create_tween()
	t.set_parallel(true)
	t.tween_property(alien_instance, "position", p3, 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(alien_instance, "rotation", -0.10, 0.35)
	await t.finished

	t = main.create_tween()
	t.set_parallel(true)
	t.tween_property(alien_instance, "position", p4, 0.30)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(alien_instance, "rotation", 0.0, 0.30)
	await t.finished

func _on_alien_clicked() -> void:
	if alien_event_state != AlienEventState.WAITING_FOR_CLICK:
		return

	alien_event_state = AlienEventState.MINIGAME
	GlobalData.alien_last_minigame_trigger_unix = float(Time.get_unix_time_from_system())
	main.achievements_manager.register_alien_clicked()

	var runtime_state: Dictionary = main.save_manager.get_save_state()

	GlobalData.set_pending_runtime_state(runtime_state)
	GlobalData.set_pending_abducted_fish_snapshots(abducted_fish_snapshots)
	GlobalData.set_pending_abduct_return_origin(abduct_return_origin)
	GlobalData.set_pending_minigame_display_fish_data(build_minigame_display_fish_data())
	GlobalData.set_pending_auspezio_level(main.shop_manager.get_level("auspezio"))
	
	await play_alien_click_feedback()
	await play_battle_transition()
	get_tree().change_scene_to_file("res://scenes/alien_minigame.tscn")

func play_alien_click_feedback() -> void:
	if alien_instance == null or not is_instance_valid(alien_instance):
		return

	if alien_instance.has_method("set_waiting_for_click"):
		alien_instance.set_waiting_for_click(false)

	var base_scale: Vector2 = alien_instance.scale
	var t := main.create_tween()
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(alien_instance, "scale", Vector2(base_scale.x * 1.12, base_scale.y * 0.88), 0.08)
	t.tween_property(alien_instance, "scale", Vector2(base_scale.x * 0.92, base_scale.y * 1.08), 0.07)
	t.tween_property(alien_instance, "scale", base_scale, 0.10)

	await t.finished

func play_battle_transition() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 9999
	main.add_child(layer)

	# Fondo negro
	var fade_rect := ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fade_rect)

	# Flash blanco
	var flash_rect := ColorRect.new()
	flash_rect.color = Color(1, 1, 1, 0)
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(flash_rect)

	# Barras estilo combate
	var bars: Array[ColorRect] = []
	var bar_count := 7
	var screen_size: Vector2 = main.get_viewport_rect().size
	var bar_height := screen_size.y / float(bar_count)

	for i in range(bar_count):
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.size = Vector2(screen_size.x, bar_height + 2)
		bar.position = Vector2(-screen_size.x, i * bar_height)
		layer.add_child(bar)
		bars.append(bar)

	# Pequeño zoom de la nave mientras arranca la transición
	if alien_instance != null and is_instance_valid(alien_instance):
		var alien_tween := main.create_tween()
		alien_tween.set_parallel(true)
		alien_tween.tween_property(alien_instance, "scale", alien_instance.scale * 1.35, 0.25)
		alien_tween.tween_property(alien_instance, "modulate:a", 0.0, 0.25)

	# Flash inicial
	var flash_tween := main.create_tween()
	flash_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(flash_rect, "color:a", 0.85, 0.08)
	flash_tween.tween_property(flash_rect, "color:a", 0.0, 0.12)

	await flash_tween.finished

	# Entran barras en cascada
	for i in range(bars.size()):
		var bar: ColorRect = bars[i]
		var t := main.create_tween()
		t.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t.tween_property(bar, "position:x", 0.0, 0.22)

		await main.get_tree().create_timer(0.04).timeout

	# Oscurecer fondo por completo al final
	var fade_tween := main.create_tween()
	fade_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_tween.tween_property(fade_rect, "color:a", 1.0, 0.20)

	await fade_tween.finished
	layer.queue_free()

func start_aquarium_abduction_sequence() -> void:
	var fish_list: Array = get_visible_aquarium_fish()

	abducted_fish_snapshots.clear()

	if alien_instance != null and alien_instance.has_method("get_abduct_target_position"):
		abduct_return_origin = alien_instance.get_abduct_target_position()
	else:
		abduct_return_origin = alien_instance.global_position if alien_instance != null else Vector2.ZERO

	_save_all_aquarium_fish_snapshots()

	if fish_list.is_empty():
		finish_abduction_sequence()
		return

	await abduct_aquarium_abduction_sequence_with_snapshots(fish_list)
	finish_abduction_sequence()
	
func _save_all_aquarium_fish_snapshots() -> void:
	var visible_snapshots := {}

	for fish in main.fish_layer.get_children():
		if not is_instance_valid(fish):
			continue

		var key := "%s:%s" % [str(fish.habitat_id), str(fish.slot_index)]

		visible_snapshots[key] = {
			"fish_id": str(fish.fish_id),
			"habitat_id": str(fish.habitat_id),
			"slot_index": int(fish.slot_index),
			"position": fish.global_position,
			"scale": fish.scale,
			"rotation": fish.rotation,
			"alpha": fish.modulate.a
		}

	for habitat_id in main.aquarium_data.keys():
		var slots: Array = main.aquarium_data[habitat_id]

		for i in range(slots.size()):
			var fish_id = slots[i]
			if fish_id == null:
				continue

			var key := "%s:%s" % [str(habitat_id), str(i)]

			if visible_snapshots.has(key):
				abducted_fish_snapshots.append(visible_snapshots[key])
			else:
				abducted_fish_snapshots.append({
					"fish_id": str(fish_id),
					"habitat_id": str(habitat_id),
					"slot_index": i,
					"position": Vector2.ZERO,
					"scale": Vector2.ONE,
					"rotation": 0.0,
					"alpha": 1.0
				})

func abduct_aquarium_abduction_sequence_with_snapshots(fish_list: Array) -> void:
	var tweens: Array[Tween] = []

	for fish in fish_list:
		if not is_instance_valid(fish):
			continue

		var tween := abduct_single_fish(fish)
		if tween != null:
			tweens.append(tween)

	for tween in tweens:
		await tween.finished

	await main.get_tree().create_timer(0.25).timeout

func get_visible_aquarium_fish() -> Array:
	var result: Array = []

	for fish in main.fish_layer.get_children():
		if is_instance_valid(fish) and fish.visible:
			result.append(fish)

	return result

func abduct_aquarium_fish_sequence(fish_list: Array) -> void:
	var tweens: Array[Tween] = []

	for fish in fish_list:
		if not is_instance_valid(fish):
			continue

		var tween := abduct_single_fish(fish)
		if tween != null:
			tweens.append(tween)

	for tween in tweens:
		await tween.finished

	await main.get_tree().create_timer(0.25).timeout

func abduct_single_fish(fish: Node2D) -> Tween:
	if alien_instance == null or not is_instance_valid(alien_instance) or not is_instance_valid(fish):
		return null

	var target_pos: Vector2 = fish.global_position
	if alien_instance.has_method("get_abduct_target_position"):
		target_pos = alien_instance.get_abduct_target_position()

	var abduct_duration: float = 2.0
	var spins: float = randf_range(2.5, 4.5)
	var final_rotation: float = fish.rotation + TAU * spins

	var t := main.create_tween()
	t.set_parallel(true)
	t.tween_property(fish, "global_position", target_pos, abduct_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(fish, "scale", Vector2(0.05, 0.05), abduct_duration)
	t.tween_property(fish, "modulate:a", 0.0, abduct_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(fish, "rotation", final_rotation, abduct_duration)\
		.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	t.finished.connect(func():
		if is_instance_valid(fish):
			fish.visible = false
	)

	return t
	
func finish_abduction_sequence() -> void:
	alien_event_state = AlienEventState.WAITING_FOR_CLICK

	if alien_instance != null and alien_instance.has_method("hide_beam"):
		await alien_instance.hide_beam()

	if alien_instance != null and alien_instance.has_method("set_waiting_for_click"):
		alien_instance.set_waiting_for_click(true)

func start_alien_minigame() -> void:
	alien_event_state = AlienEventState.MINIGAME
	alien_event_done = true
	get_tree().change_scene_to_file("res://scenes/alien_minigame.tscn")

func get_inventory_fish_count() -> int:
	var total := 0
	for fish_id in main.fish_inventory.keys():
		total += int(main.fish_inventory[fish_id])
	return total

func get_aquarium_fish_count() -> int:
	var total := 0

	for habitat_id in main.aquarium_data.keys():
		for slot in main.aquarium_data[habitat_id]:
			if slot != null:
				total += 1

	return total

func get_total_fish_count() -> int:
	return get_inventory_fish_count() + get_aquarium_fish_count()

func play_return_from_minigame_transition() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 9999
	main.add_child(layer)

	var fade_rect := ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fade_rect)

	var flash_rect := ColorRect.new()
	flash_rect.color = Color(1, 1, 1, 0)
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(flash_rect)

	var flash_tween := main.create_tween()
	flash_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(flash_rect, "color:a", 0.45, 0.10)
	flash_tween.tween_property(flash_rect, "color:a", 0.0, 0.12)

	var fade_tween := main.create_tween()
	fade_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(fade_rect, "color:a", 0.0, 0.45)

	await fade_tween.finished
	layer.queue_free()
	
func _resume_after_minigame_flow(result: Dictionary) -> void:
	alien_event_available = false

	if main.stats_manager != null:
		main.stats_manager.register_alien_minigame_result(bool(result.get("won", false)))

	if main.achievements_manager != null:
		if bool(result.get("no_hit", false)):
			main.achievements_manager.register_alien_no_hit()

		main.achievements_manager.check_achievements()

	clear_visual_fish_layer()
	await main.get_tree().process_frame

	spawn_alien_in_return_position()

	if alien_instance != null and alien_instance.has_method("show_beam"):
		alien_instance.show_beam()

	await play_return_from_minigame_transition()

	if bool(result.get("won", false)):
		alien_escape_fx_active = true
	else:
		if main != null:
			main.start_fish_loss_debuff()

	await spit_fish_back_into_aquarium()

	if alien_instance != null and alien_instance.has_method("hide_beam"):
		await alien_instance.hide_beam()

	if bool(result.get("won", false)):
		await animate_alien_escape_damaged()
	else:
		await animate_alien_exit_after_minigame()

	if alien_instance != null and is_instance_valid(alien_instance):
		alien_instance.queue_free()
		alien_instance = null

	alien_event_state = AlienEventState.IDLE
	alien_escape_fx_active = false

	main.update_ui_block_state()
	check_alien_event_unlock()

	if main.achievements_manager != null:
		main.achievements_manager.check_achievements()
		main.achievements_manager._try_show_next_achievement_popup()


func animate_alien_escape_damaged() -> void:
	if alien_instance == null or not is_instance_valid(alien_instance):
		return

	alien_escape_fx_active = true

	var screen_size: Vector2 = main.get_viewport_rect().size

	var fx_layer := CanvasLayer.new()
	fx_layer.layer = 9998
	main.add_child(fx_layer)

	alien_instance.rotation = 0.0
	alien_instance.modulate.a = 1.0

	for i in range(3):
		if alien_instance == null or not is_instance_valid(alien_instance):
			break

		var shake_t := main.create_tween()
		shake_t.set_parallel(true)
		shake_t.tween_property(
			alien_instance,
			"position",
			alien_instance.position + Vector2(randf_range(-16.0, 16.0), randf_range(-8.0, 8.0)),
			0.06
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		shake_t.tween_property(
			alien_instance,
			"rotation",
			randf_range(-0.15, 0.15),
			0.06
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await shake_t.finished

	var escape_target := Vector2(alien_instance.position.x + randf_range(-80.0, 80.0), -220.0)

	var move_t := main.create_tween()
	move_t.set_parallel(true)
	move_t.tween_property(alien_instance, "position", escape_target, 1.4)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	move_t.tween_property(alien_instance, "rotation", randf_range(-0.35, 0.35), 1.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	move_t.tween_property(alien_instance, "modulate:a", 0.0, 1.2)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var should_drop_egg := randf() < 1
	if should_drop_egg:
		call_deferred("_drop_egg_during_escape")

	var elapsed := 0.0
	var interval := 0.09

	while elapsed < 1.25 and alien_instance != null and is_instance_valid(alien_instance):
		spawn_alien_escape_smoke_fx(fx_layer)
		if randf() < 0.55:
			spawn_alien_escape_explosion_fx(fx_layer)

		await main.get_tree().create_timer(interval).timeout
		elapsed += interval

	await move_t.finished

	if is_instance_valid(fx_layer):
		fx_layer.queue_free()

	alien_escape_fx_active = false


func _drop_egg_during_escape() -> void:
	await main.get_tree().create_timer(0.28).timeout

	if alien_instance == null or not is_instance_valid(alien_instance):
		return

	if main.egg_manager != null:
		main.egg_manager.spawn_dropped_egg(alien_instance.global_position)

	if main.achievements_manager != null:
		main.achievements_manager.register_alien_egg_obtained()


func spawn_alien_escape_smoke_fx(parent: CanvasLayer) -> void:
	if alien_instance == null or not is_instance_valid(alien_instance):
		return

	var smoke := ColorRect.new()
	var size := randf_range(14.0, 30.0)
	smoke.size = Vector2(size, size)
	smoke.position = alien_instance.global_position + Vector2(
		randf_range(-26.0, 26.0),
		randf_range(10.0, 28.0)
	) - smoke.size * 0.5
	smoke.color = Color(
		randf_range(0.20, 0.36),
		randf_range(0.20, 0.36),
		randf_range(0.20, 0.36),
		0.60
	)
	parent.add_child(smoke)

	var drift := Vector2(
		randf_range(-18.0, 18.0),
		randf_range(16.0, 40.0)
	)

	var t := main.create_tween()
	t.set_parallel(true)
	t.tween_property(smoke, "position", smoke.position + drift, 0.40)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(smoke, "scale", Vector2(1.5, 1.5), 0.40)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(smoke, "modulate:a", 0.0, 0.40)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await t.finished

	if is_instance_valid(smoke):
		smoke.queue_free()


func spawn_alien_escape_explosion_fx(parent: CanvasLayer) -> void:
	if alien_instance == null or not is_instance_valid(alien_instance):
		return

	var pos := alien_instance.global_position + Vector2(
		randf_range(-34.0, 34.0),
		randf_range(-18.0, 24.0)
	)

	var outer := ColorRect.new()
	var outer_size := randf_range(18.0, 36.0)
	outer.size = Vector2(outer_size, outer_size)
	outer.position = pos - outer.size * 0.5
	outer.color = Color(1.0, randf_range(0.38, 0.6), 0.08, 0.75)
	parent.add_child(outer)

	var mid := ColorRect.new()
	var mid_size := outer_size * 0.58
	mid.size = Vector2(mid_size, mid_size)
	mid.position = pos - mid.size * 0.5
	mid.color = Color(1.0, randf_range(0.7, 0.9), 0.15, 0.92)
	parent.add_child(mid)

	var inner := ColorRect.new()
	var inner_size := outer_size * 0.28
	inner.size = Vector2(inner_size, inner_size)
	inner.position = pos - inner.size * 0.5
	inner.color = Color(1.0, 0.95, 0.8, 1.0)
	parent.add_child(inner)

	var t1 := main.create_tween()
	t1.set_parallel(true)
	t1.tween_property(outer, "scale", Vector2(1.45, 1.45), 0.18)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t1.tween_property(outer, "modulate:a", 0.0, 0.20)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var t2 := main.create_tween()
	t2.set_parallel(true)
	t2.tween_property(mid, "scale", Vector2(1.30, 1.30), 0.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t2.tween_property(mid, "modulate:a", 0.0, 0.16)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var t3 := main.create_tween()
	t3.set_parallel(true)
	t3.tween_property(inner, "scale", Vector2(1.18, 1.18), 0.12)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t3.tween_property(inner, "modulate:a", 0.0, 0.13)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await t1.finished
	await t2.finished
	await t3.finished

	if is_instance_valid(outer):
		outer.queue_free()
	if is_instance_valid(mid):
		mid.queue_free()
	if is_instance_valid(inner):
		inner.queue_free()


func spawn_alien_in_return_position() -> void:
	alien_instance = ALIEN_SCENE.instantiate() as Node2D
	if alien_instance == null:
		return

	main.add_child(alien_instance)

	if alien_instance.has_signal("clicked"):
		alien_instance.clicked.connect(_on_alien_clicked)

	var screen_size: Vector2 = main.get_viewport_rect().size
	var final_pos: Vector2 = Vector2(screen_size.x * 0.5, 100)

	alien_instance.position = final_pos
	alien_instance.rotation = 0.0
	alien_instance.modulate.a = 1.0

	if alien_instance.has_method("set_waiting_for_click"):
		alien_instance.set_waiting_for_click(false)


func resume_after_minigame(result: Dictionary) -> void:
	alien_event_state = AlienEventState.ABDUCTING
	call_deferred("_resume_after_minigame_flow", result)


func spit_fish_back_into_aquarium() -> void:
	if alien_instance == null or not is_instance_valid(alien_instance):
		return

	clear_visual_fish_layer()
	await main.get_tree().process_frame

	var origin := abduct_return_origin
	if origin == Vector2.ZERO:
		if alien_instance != null and alien_instance.has_method("get_abduct_target_position"):
			origin = alien_instance.get_abduct_target_position()
		elif alien_instance != null:
			origin = alien_instance.global_position

	var fx_layer: CanvasLayer = null

	if alien_escape_fx_active:
		fx_layer = CanvasLayer.new()
		fx_layer.layer = 9998
		main.add_child(fx_layer)
		call_deferred("_run_alien_damage_fx_loop", fx_layer)

	var tweens: Array[Tween] = []
	var current_habitat: String = main.habitat_manager.current_habitat

	# Recreamos TODOS los peces visuales, pero solo mostramos los del hábitat actual
	for snap in abducted_fish_snapshots:
		var fish_id: String = str(snap.get("fish_id", ""))
		var habitat_id: String = str(snap.get("habitat_id", ""))
		var slot_index: int = int(snap.get("slot_index", -1))

		if fish_id == "" or habitat_id == "" or slot_index < 0:
			continue

		var fish = main.aquarium_manager.spawn_fish(
			fish_id,
			habitat_id,
			slot_index,
			false,
			origin
		)

		if fish != null and is_instance_valid(fish):
			fish.visible = habitat_id == current_habitat

	await main.get_tree().process_frame

	# Animamos solo los peces del hábitat actual
	for fish in main.fish_layer.get_children():
		if not is_instance_valid(fish):
			continue

		if str(fish.habitat_id) != current_habitat:
			continue

		var snap := _find_snapshot_for_fish(fish)
		if snap.is_empty():
			continue

		var target_pos: Vector2 = snap["position"]
		var target_scale: Vector2 = snap["scale"]
		var target_rotation: float = snap["rotation"]
		var target_alpha: float = float(snap.get("alpha", 1.0))

		fish.global_position = origin
		fish.scale = Vector2(0.05, 0.05)
		fish.rotation = target_rotation + randf_range(-TAU * 2.0, TAU * 2.0)
		fish.modulate.a = 0.0
		fish.visible = true

		var t := main.create_tween()
		t.set_parallel(true)
		t.tween_property(fish, "global_position", target_pos, 2.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(fish, "scale", target_scale, 2.0)
		t.tween_property(fish, "modulate:a", target_alpha, 2.0)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(fish, "rotation", target_rotation, 2.0)\
			.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

		tweens.append(t)

	for t in tweens:
		await t.finished

	# Por si tu manager tiene método de refresco por hábitat
	if main.aquarium_manager.has_method("refresh_visible_fish_by_habitat"):
		main.aquarium_manager.refresh_visible_fish_by_habitat()

	if fx_layer != null and is_instance_valid(fx_layer):
		fx_layer.queue_free()


func _run_alien_damage_fx_loop(fx_layer: CanvasLayer) -> void:
	while alien_escape_fx_active and fx_layer != null and is_instance_valid(fx_layer):
		if alien_instance == null or not is_instance_valid(alien_instance):
			return

		# Mucho más humo que explosión
		for i in range(randi_range(2, 4)):
			spawn_alien_escape_smoke_fx(fx_layer)

		# Explosiones pequeñas y frecuentes
		for i in range(randi_range(1, 3)):
			spawn_alien_escape_explosion_fx(fx_layer)

		await main.get_tree().create_timer(0.08).timeout


func _find_snapshot_for_fish(fish: Node) -> Dictionary:
	for snap in abducted_fish_snapshots:
		if str(snap.get("fish_id", "")) == str(fish.fish_id) \
		and str(snap.get("habitat_id", "")) == str(fish.habitat_id) \
		and int(snap.get("slot_index", -1)) == int(fish.slot_index):
			return snap
	return {}
		
func animate_alien_exit_after_minigame() -> void:
	if alien_instance == null or not is_instance_valid(alien_instance):
		return

	var screen_size: Vector2 = main.get_viewport_rect().size
	var final_pos: Vector2 = Vector2(screen_size.x * 0.5, 100)

	var p4 := final_pos
	var p3 := Vector2(final_pos.x - 70, 55)
	var p2 := Vector2(final_pos.x + 100, 10)
	var p1 := Vector2(final_pos.x - 120, -40)
	var p0 := Vector2(final_pos.x, -180)

	alien_instance.position = p4
	alien_instance.rotation = 0.0
	alien_instance.modulate.a = 1.0

	var t := main.create_tween()
	t.set_parallel(true)
	t.tween_property(alien_instance, "position", p3, 0.30)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_property(alien_instance, "rotation", -0.10, 0.30)
	await t.finished

	t = main.create_tween()
	t.set_parallel(true)
	t.tween_property(alien_instance, "position", p2, 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(alien_instance, "rotation", 0.16, 0.35)
	await t.finished

	t = main.create_tween()
	t.set_parallel(true)
	t.tween_property(alien_instance, "position", p1, 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(alien_instance, "rotation", -0.18, 0.35)
	await t.finished

	t = main.create_tween()
	t.set_parallel(true)
	t.tween_property(alien_instance, "position", p0, 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_property(alien_instance, "modulate:a", 0.0, 0.25)
	await t.finished
	
func clear_visual_fish_layer() -> void:
	for child in main.fish_layer.get_children():
		child.queue_free()


func build_minigame_display_fish_data(max_count: int = MINIGAME_DISPLAY_FISH_COUNT) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var used_types := {}

	# Guardamos cuántos peces hay por tipo disponibles para mostrar
	var available_count_by_type := {}

	# 1) Peces abducidos visibles de la pecera (prioridad)
	for snap in abducted_fish_snapshots:
		var fish_id := str(snap.get("fish_id", ""))
		var fish_type := normalize_fish_type_id(fish_id)

		if fish_type == "":
			continue

		available_count_by_type[fish_type] = int(available_count_by_type.get(fish_type, 0)) + 1

		if result.size() >= max_count:
			continue

		if not used_types.has(fish_type):
			_try_add_fish_to_minigame_display(result, used_types, fish_id)

	# 2) Peces del inventario: suman disponibilidad y sirven para rellenar con tipos únicos
	var inventory_candidates: Array[String] = []

	for raw_fish_id in main.fish_inventory.keys():
		var fish_id := str(raw_fish_id)
		var amount := int(main.fish_inventory[raw_fish_id])

		if amount <= 0:
			continue

		var fish_type := normalize_fish_type_id(fish_id)
		if fish_type == "":
			continue

		available_count_by_type[fish_type] = int(available_count_by_type.get(fish_type, 0)) + amount

		if not used_types.has(fish_type):
			inventory_candidates.append(fish_id)

	inventory_candidates.shuffle()

	for fish_id in inventory_candidates:
		if result.size() >= max_count:
			break
		_try_add_fish_to_minigame_display(result, used_types, fish_id)

	# 3) Si faltan huecos, repetir tipos SOLO si hay cantidad suficiente
	if result.size() < max_count:
		var current_used_per_type := {}

		for entry in result:
			var fish_type := str(entry.get("fish_type", ""))
			if fish_type != "":
				current_used_per_type[fish_type] = int(current_used_per_type.get(fish_type, 0)) + 1

		var repeat_candidates: Array[Dictionary] = []

		# Sacamos posibles repeticiones a partir de lo ya disponible
		for entry in result:
			var fish_id := str(entry.get("fish_id", ""))
			var fish_type := str(entry.get("fish_type", ""))

			if fish_id == "" or fish_type == "":
				continue

			var total_available := int(available_count_by_type.get(fish_type, 0))
			var already_used := int(current_used_per_type.get(fish_type, 0))

			if total_available > already_used:
				repeat_candidates.append({
					"fish_id": fish_id,
					"fish_type": fish_type
				})

		repeat_candidates.shuffle()

		while result.size() < max_count and not repeat_candidates.is_empty():
			var picked: Dictionary = repeat_candidates.pop_back()
			var fish_id := str(picked.get("fish_id", ""))
			var fish_type := str(picked.get("fish_type", ""))

			var total_available := int(available_count_by_type.get(fish_type, 0))
			var already_used := int(current_used_per_type.get(fish_type, 0))

			if total_available <= already_used:
				continue

			var texture_path := resolve_fish_texture_path(fish_id)
			if texture_path == "":
				texture_path = resolve_fish_texture_path(fish_type)

			if texture_path == "":
				continue

			result.append({
				"fish_id": fish_id,
				"fish_type": fish_type,
				"texture_path": texture_path,
				"is_capsule": false
			})

			current_used_per_type[fish_type] = already_used + 1

			# Si aún podría repetirse otra vez, lo volvemos a meter
			if total_available > current_used_per_type[fish_type]:
				repeat_candidates.push_back({
					"fish_id": fish_id,
					"fish_type": fish_type
				})

			repeat_candidates.shuffle()

	# 4) Si todavía faltan huecos, rellenar con cápsulas random
	while result.size() < max_count:
		result.append(build_random_capsule_entry())

	return result


func _try_add_fish_to_minigame_display(
	result: Array[Dictionary],
	used_types: Dictionary,
	fish_id: String
) -> void:
	if fish_id == "":
		return

	var fish_type := normalize_fish_type_id(fish_id)
	if fish_type == "" or used_types.has(fish_type):
		return

	var texture_path := resolve_fish_texture_path(fish_id)
	if texture_path == "":
		texture_path = resolve_fish_texture_path(fish_type)

	if texture_path == "":
		return

	used_types[fish_type] = true
	result.append({
		"fish_id": fish_id,
		"fish_type": fish_type,
		"texture_path": texture_path,
		"is_capsule": false
	})


func build_random_capsule_entry() -> Dictionary:
	var capsule_paths := [
		"res://assets/minigame_alien/capsula_1.png",
		"res://assets/minigame_alien/capsula_2.png",
		"res://assets/minigame_alien/capsula_3.png"
	]

	var valid_paths: Array[String] = []

	for path in capsule_paths:
		if ResourceLoader.exists(path):
			valid_paths.append(path)

	if valid_paths.is_empty():
		return {
			"fish_id": "",
			"fish_type": "capsule",
			"texture_path": "",
			"is_capsule": true
		}

	var picked_path := valid_paths[randi() % valid_paths.size()]

	return {
		"fish_id": "",
		"fish_type": "capsule",
		"texture_path": picked_path,
		"is_capsule": true
	}


func normalize_fish_type_id(fish_id: String) -> String:
	var normalized := fish_id.strip_edges()

	# Si quieres que shiny y normal cuenten como el mismo tipo
	if normalized.ends_with("_shiny"):
		normalized = normalized.substr(0, normalized.length() - 6)
	elif normalized.ends_with("_brillante"):
		normalized = normalized.substr(0, normalized.length() - 10)

	return normalized


func resolve_fish_texture_path(fish_id: String) -> String:
	if fish_id == "":
		return ""

	var fish_defs_variant = main.get("fish_defs")
	if fish_defs_variant is Dictionary:
		var fish_defs: Dictionary = fish_defs_variant

		if fish_defs.has(fish_id):
			var fish_def = fish_defs[fish_id]

			if fish_def is Dictionary:
				for key in ["texture_path", "sprite_path", "icon_path", "texture", "sprite", "icon"]:
					if fish_def.has(key):
						var value = fish_def[key]

						if value is String and value != "":
							return value

						if value is Texture2D and value.resource_path != "":
							return value.resource_path

	# Fallback por convención
	var fallback_path := "res://assets/peces/%s.png" % fish_id
	if ResourceLoader.exists(fallback_path):
		return fallback_path

	return ""


func is_event_blocking_achievement_popups() -> bool:
	if alien_escape_fx_active:
		return true

	return alien_event_state != AlienEventState.IDLE


func is_alien_minigame_on_cooldown() -> bool:
	if GlobalData.alien_last_minigame_trigger_unix < 0.0:
		return false

	var now: float = float(Time.get_unix_time_from_system())
	return (now - GlobalData.alien_last_minigame_trigger_unix) < ALIEN_MINIGAME_COOLDOWN_SECONDS


func can_trigger_alien_event() -> bool:
	if not alien_event_available:
		return false
	if alien_event_state != AlienEventState.IDLE:
		return false
	if is_alien_minigame_on_cooldown():
		return false

	if main.cleaning_manager != null and main.cleaning_manager.is_cleaning_event_active():
		return false

	if main.fish_mode_manager != null and main.fish_mode_manager.is_fish_mode_active():
		return false

	var now: float = float(Time.get_unix_time_from_system())
	if now - manager_started_unix < ALIEN_EVENT_STARTUP_GRACE_SECONDS:
		return false

	return true
