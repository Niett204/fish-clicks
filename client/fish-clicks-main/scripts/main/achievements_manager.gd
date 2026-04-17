extends Node
class_name AchievementsManager

@warning_ignore("shadowed_global_identifier")
const AchievementDefs = preload("res://scripts/data/achievement_defs.gd")
const ACHIEVEMENT_DEFS = AchievementDefs.ACHIEVEMENT_DEFS
const ACHIEVEMENT_POPUP_SCENE := preload("res://scenes/achievement_popup.tscn")

var main: Node = null

var achievements_unlocked: Dictionary = {}
var achievement_popup_queue: Array = []
var achievement_popup_active: Control = null

var total_shinies_ever: int = 0
var total_structures_spent: float = 0.0
var alien_clicked_count: int = 0
var random_tick_unlocked: bool = false
var profile_clicks_count: int = 0
var volume_slider_spam_unlocked: bool = false
var annoyed_fish_count: int = 0
var achievement_check_accum: float = 0.0


func setup(main_ref: Node) -> void:
	main = main_ref

	for achievement_id in ACHIEVEMENT_DEFS.keys():
		achievements_unlocked[achievement_id] = false


func process_achievement_timer(delta: float) -> void:
	achievement_check_accum += delta
	if achievement_check_accum >= 0.5:
		achievement_check_accum = 0.0
		if not random_tick_unlocked and randf() < 0.0001:
			random_tick_unlocked = true

		check_achievements()


func register_profile_click() -> void:
	profile_clicks_count += 1
	check_achievements()


func register_volume_slider_spam() -> void:
	if not volume_slider_spam_unlocked:
		volume_slider_spam_unlocked = true
		check_achievements()


func register_fish_annoyed() -> void:
	annoyed_fish_count += 1


func register_structure_spent(amount: float) -> void:
	total_structures_spent += amount


func register_shiny_obtained() -> void:
	total_shinies_ever += 1


func register_alien_clicked() -> void:
	alien_clicked_count += 1
	check_achievements()


func _get_achievement_current_value(kind: String) -> float:
	match kind:
		"clicks":
			return float(main.total_clicks)
		"coins":
			return main.total_coins_earned
		"fish":
			return float(main.aquarium_manager.get_total_fish_count())
		"structures":
			return float(main.shop_manager.get_total_unlocked_structures_count())
		"structures_spent":
			return total_structures_spent
		"shiny_current":
			return float(main.aquarium_manager.get_total_shiny_fish_count())
		"shiny_ever":
			return float(total_shinies_ever)
		"play_time":
			return main.session_time_seconds
		"dps":
			return main.dps
		"dpc":
			return float(main.click_power)
		"all_aquarium_shiny":
			return 1.0 if _is_all_current_aquarium_shiny() else 0.0
		"all_species_in_aquarium":
			return 1.0 if _has_all_species_in_current_aquarium() else 0.0
		"alien_clicked":
			return float(alien_clicked_count)
		"random_tick":
			return 1.0 if random_tick_unlocked else 0.0
		"encyclopedia_complete":
			return 1.0 if _is_encyclopedia_complete() else 0.0
		"profile_clicks":
			return float(profile_clicks_count)
		"volume_slider_spam":
			return 1.0 if volume_slider_spam_unlocked else 0.0
		"same_species_full_aquarium":
			return 1.0 if _is_same_species_full_aquarium() else 0.0
		"annoy_fish":
			return float(annoyed_fish_count)
		"achievements_unlocked":
			return float(get_unlocked_achievements_count())
		_:
			return 0.0


func check_achievements() -> void:
	var changed := false

	for achievement_id in ACHIEVEMENT_DEFS.keys():
		if bool(achievements_unlocked.get(achievement_id, false)):
			continue

		var def: Dictionary = ACHIEVEMENT_DEFS[achievement_id]
		var kind := String(def.get("kind", ""))
		var target := float(def.get("target", 0.0))
		var current := _get_achievement_current_value(kind)

		if current >= target:
			achievements_unlocked[achievement_id] = true
			changed = true

			var title := String(def.get("title", achievement_id))
			var condition := String(def.get("condition", ""))
			var icon_data = def.get("icon", null)
			var icon_tex: Texture2D = null

			if icon_data is Texture2D:
				icon_tex = icon_data
			elif icon_data is String and icon_data != "":
				icon_tex = load(icon_data)
			
			_show_achievement_popup(title, condition, icon_tex)

	if changed and main.stats_panel.visible:
		main.stats_manager.refresh_stats_panel_full()


func _show_achievement_popup(title: String, condition: String, icon_tex: Texture2D = null) -> void:
	achievement_popup_queue.append({
		"title": title,
		"condition": condition,
		"icon": icon_tex
	})

	_try_show_next_achievement_popup()


func _try_show_next_achievement_popup() -> void:
	if achievement_popup_active != null:
		return

	if achievement_popup_queue.is_empty():
		return

	var data: Dictionary = achievement_popup_queue.pop_front()

	var popup = ACHIEVEMENT_POPUP_SCENE.instantiate()
	main.get_node("UI/Root").add_child(popup)
	achievement_popup_active = popup
	
	main.ui_manager.play_achievement_sfx(main.SFX_ACHIEVEMENT)

	if popup.has_method("setup_popup"):
		popup.setup_popup(
			String(data.get("title", "")),
			String(data.get("condition", "")),
			data.get("icon", null)
		)

	await main.get_tree().process_frame

	var screen_size: Vector2 = main.get_viewport_rect().size
	popup.position = Vector2(
		screen_size.x - popup.size.x - 675,
		10
	)

	if popup.has_signal("popup_finished"):
		popup.popup_finished.connect(_on_achievement_popup_finished)

	if popup.has_method("show_popup"):
		popup.show_popup()


func _on_achievement_popup_finished() -> void:
	achievement_popup_active = null
	_try_show_next_achievement_popup()


func _get_base_fish_id(fish_id: String) -> String:
	return fish_id.replace("_shiny", "")


func _get_current_aquarium_fish_ids() -> Array[String]:
	var result: Array[String] = []

	if not main.aquarium_data.has(main.current_habitat):
		return result

	for fish_id in main.aquarium_data[main.current_habitat]:
		if fish_id != null:
			result.append(String(fish_id))

	return result


func _is_current_aquarium_full() -> bool:
	if not main.aquarium_data.has(main.current_habitat):
		return false

	for fish_id in main.aquarium_data[main.current_habitat]:
		if fish_id == null:
			return false

	return true


func _is_all_current_aquarium_shiny() -> bool:
	var fish_ids := _get_current_aquarium_fish_ids()

	if fish_ids.is_empty():
		return false

	if not _is_current_aquarium_full():
		return false

	for fish_id in fish_ids:
		if not fish_id.ends_with("_shiny"):
			return false

	return true


func _has_all_species_in_current_aquarium() -> bool:
	var required_species := {}
	for fish_id in main.ENCYCLOPEDIA_FISH_IDS.keys():
		required_species[String(fish_id)] = true

	var present_species := {}

	for fish_id in _get_current_aquarium_fish_ids():
		present_species[_get_base_fish_id(fish_id)] = true

	for species_id in required_species.keys():
		if not present_species.has(species_id):
			return false

	return true


func _is_same_species_full_aquarium() -> bool:
	var fish_ids := _get_current_aquarium_fish_ids()

	if fish_ids.is_empty():
		return false

	if not _is_current_aquarium_full():
		return false

	var first_species := _get_base_fish_id(fish_ids[0])

	for fish_id in fish_ids:
		if _get_base_fish_id(fish_id) != first_species:
			return false

	return true


func _is_encyclopedia_complete() -> bool:
	for fish_id in main.ENCYCLOPEDIA_FISH_IDS.keys():
		if not bool(main.unlocked.get(fish_id, false)):
			return false
	return true


func get_unlocked_achievements_count() -> int:
	var total := 0
	for k in achievements_unlocked.keys():
		if bool(achievements_unlocked[k]):
			total += 1
	return total
