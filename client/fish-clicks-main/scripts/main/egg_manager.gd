extends Node
class_name EggManager

const ALIEN_EGG_SCENE := preload("res://scenes/alien_egg.tscn")

const INCUBATION_TOTAL_TIME := 18000.0 # 5 horas
const HATCH_RESULT_FISH_ID := "auspezio"

var main: Node = null
var active_egg: Node2D = null

func setup(main_ref: Node) -> void:
	main = main_ref
	randomize()

func spawn_dropped_egg(from_global_position: Vector2) -> void:
	if not can_drop_alien_egg():
		return

	var egg := ALIEN_EGG_SCENE.instantiate() as Node2D
	if egg == null:
		return

	main.add_child(egg)
	active_egg = egg

	egg.global_position = from_global_position
	egg.z_index = 1500

	if egg.has_method("setup_egg"):
		egg.setup_egg(self)

	var target_pos := Vector2(
		from_global_position.x + randf_range(-140.0, 140.0),
		from_global_position.y + 500
	)

	var t := main.create_tween()
	t.set_parallel(true)
	t.tween_property(egg, "global_position", target_pos, 0.95)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(egg, "rotation", randf_range(-0.8, 0.8), 0.95)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await t.finished

	if egg != null and is_instance_valid(egg) and egg.has_method("enter_dropped_state"):
		egg.enter_dropped_state()


func can_drop_alien_egg() -> bool:
	if active_egg != null and is_instance_valid(active_egg):
		return false

	if int(main.fish_inventory.get(HATCH_RESULT_FISH_ID, 0)) > 0:
		return false

	for habitat_id in main.aquarium_data.keys():
		for slot_fish_id in main.aquarium_data[habitat_id]:
			if slot_fish_id != null and String(slot_fish_id) == HATCH_RESULT_FISH_ID:
				return false

	return true


func on_egg_pressed_in_dropped_state(egg: Node2D) -> void:
	if egg == null or not is_instance_valid(egg):
		return

	var nest_pos := get_egg_nest_position()

	if egg.has_method("enter_moving_to_nest_state"):
		egg.enter_moving_to_nest_state()

	var t := main.create_tween()
	t.set_parallel(true)
	t.tween_property(egg, "global_position", nest_pos, 0.75)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(egg, "rotation", 0.0, 0.75)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await t.finished

	if egg != null and is_instance_valid(egg) and egg.has_method("enter_incubating_state"):
		egg.enter_incubating_state(INCUBATION_TOTAL_TIME)

func on_egg_ready_to_hatch(egg: Node2D) -> void:
	# aquí podrías lanzar sonido o FX si quieres
	pass

func on_egg_pressed_ready_to_hatch(egg: Node2D) -> void:
	if egg == null or not is_instance_valid(egg):
		return

	if egg.has_method("enter_hatching_state"):
		egg.enter_hatching_state()

	await main.get_tree().create_timer(0.35).timeout

	spawn_fixed_fish_from_egg(egg.global_position)

	if egg != null and is_instance_valid(egg):
		egg.queue_free()

	if active_egg == egg:
		active_egg = null

func get_egg_nest_position() -> Vector2:
	var viewport_size: Vector2 = main.get_viewport_rect().size

	# base bastante abajo a la derecha
	var pos := Vector2(viewport_size.x - 180.0, viewport_size.y - 55.0)

	# si quieres afinarlo al contenido de pecera, toca estos offsets
	return pos

func spawn_fixed_fish_from_egg(spawn_pos: Vector2) -> void:
	main.unlocked[HATCH_RESULT_FISH_ID] = true

	if main.ui_manager != null:
		main.ui_manager.update_shop_cards()

	main._actualizar_peces_desbloqueados_en_enciclopedia()

	var habitat_id: String = str(main.habitat_manager.current_habitat)
	var slot_index: int = _find_first_free_slot(habitat_id)

	if slot_index == -1:
		main.fish_inventory[HATCH_RESULT_FISH_ID] = int(main.fish_inventory.get(HATCH_RESULT_FISH_ID, 0)) + 1
		main.aquarium_manager.refresh_inventory_panel_data()
		main.ui_manager._update_ui()
		return

	main.aquarium_data[habitat_id][slot_index] = HATCH_RESULT_FISH_ID

	main.aquarium_manager.spawn_fish(
		HATCH_RESULT_FISH_ID,
		habitat_id,
		slot_index,
		false,
		spawn_pos
	)

	main.aquarium_manager.refresh_inventory_panel_data()
	main.ui_manager._update_ui()

func _find_first_free_slot(habitat_id: String) -> int:
	if not main.aquarium_data.has(habitat_id):
		return -1

	for i in range(main.aquarium_data[habitat_id].size()):
		if main.aquarium_data[habitat_id][i] == null:
			return i

	return -1


func get_save_state() -> Dictionary:
	if active_egg == null or not is_instance_valid(active_egg):
		return {
			"has_egg": false
		}

	return {
		"has_egg": true,
		"state": int(active_egg.state),
		"position": {
			"x": active_egg.global_position.x,
			"y": active_egg.global_position.y
		},
		"incubation_elapsed": active_egg.incubation_elapsed,
		"incubation_total_time": active_egg.incubation_total_time
	}


func apply_save_state(data: Dictionary) -> void:
	clear_active_egg()

	if data.is_empty() or not bool(data.get("has_egg", false)):
		return

	var egg := ALIEN_EGG_SCENE.instantiate()
	main.content_pecera.add_child(egg)

	active_egg = egg
	egg.egg_manager = self

	var pos_data: Dictionary = data.get("position", {})
	egg.global_position = Vector2(
		float(pos_data.get("x", 0.0)),
		float(pos_data.get("y", 0.0))
	)

	egg.state = int(data.get("state", AlienEgg.EggState.DROPPED))
	if egg.has_method("refresh_visual_state"):
		egg.refresh_visual_state()
	egg.incubation_elapsed = float(data.get("incubation_elapsed", 0.0))
	egg.incubation_total_time = float(data.get("incubation_total_time", 86400.0))

	if egg.has_method("refresh_visual_state"):
		egg.refresh_visual_state()


func clear_active_egg() -> void:
	if active_egg != null and is_instance_valid(active_egg):
		active_egg.queue_free()

	active_egg = null
