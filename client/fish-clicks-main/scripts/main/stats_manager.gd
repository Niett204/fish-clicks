extends Node
class_name StatsManager

var main: Node = null


func setup(main_ref: Node) -> void:
	main = main_ref


func refresh_stats_panel() -> void:
	if main.stats_panel.has_method("set_stats_data"):
		main.stats_panel.set_stats_data({
			"total_clicks": main.total_clicks,
			"total_fish": main.aquarium_manager.get_total_fish_count(),
			"total_structures": main.shop_manager.get_total_unlocked_structures_count(),
			"total_doblones": main.get_compact_number_text(main.total_coins_earned),
			"total_special_fish": main.aquarium_manager.get_total_shiny_fish_count(),
			"play_time": main.format_play_time(int(main.session_time_seconds)),
			"start_date": main.game_start_date_string,
			"dps": main.get_compact_number_text(main.dps) + " d/s",
			"dpc": main.get_compact_number_text(main.shop_manager.get_click_income()) + " d/click",
			# Stats minijuego limpieza, solo se muestran al desbloquearse el minijuego
			"total_dirt_cleaned": main.cleaning_manager.total_dirt_spots_cleaned,
			"cleaning_events_completed": main.cleaning_manager.cleaning_events_completed,
			"show_cleaning_stats": main.cleaning_manager.is_cleaning_feature_unlocked(),
			# Stats minijuego alien, solo se muestran al desbloquearse el minijuego
			"alien_minigame_wins": main.alien_minigame_wins,
			"alien_minigame_losses": main.alien_minigame_losses,
			"show_alien_stats": main.alien_manager.is_alien_feature_unlocked()
		})

	if main.stats_panel.has_method("set_achievements_progress"):
		main.stats_panel.set_achievements_progress(
			get_unlocked_achievements_count(),
			get_total_achievements_count()
		)

	if main.stats_panel.has_method("set_achievements_data"):
		main.stats_panel.set_achievements_data(get_achievements_ui_data())


func refresh_stats_values_only() -> void:
	if main.stats_panel.has_method("set_stats_data"):
		main.stats_panel.set_stats_data({
			"total_clicks": main.total_clicks,
			"total_fish": main.aquarium_manager.get_total_fish_count(),
			"total_structures": main.shop_manager.get_total_unlocked_structures_count(),
			"total_doblones": main.get_compact_number_text(main.total_coins_earned),
			"total_special_fish": main.aquarium_manager.get_total_shiny_fish_count(),
			"play_time": main.format_play_time(int(main.session_time_seconds)),
			"start_date": main.game_start_date_string,
			"dps": main.get_compact_number_text(main.dps) + " d/s",
			"dpc": main.get_compact_number_text(main.click_power) + " d/c",
			# Stats minijuego limpieza, solo se muestran al desbloquearse el minijuego
			"total_dirt_cleaned": main.cleaning_manager.total_dirt_spots_cleaned,
			"cleaning_events_completed": main.cleaning_manager.cleaning_events_completed,
			"show_cleaning_stats": main.cleaning_manager.is_cleaning_feature_unlocked(),
			# Stats minijuego alien, solo se muestran al desbloquearse el minijuego
			"alien_minigame_wins": main.alien_minigame_wins,
			"alien_minigame_losses": main.alien_minigame_losses,
			"show_alien_stats": main.alien_manager.is_alien_feature_unlocked()
		})


func refresh_stats_panel_full() -> void:
	refresh_stats_values_only()

	if main.stats_panel.has_method("set_achievements_progress"):
		main.stats_panel.set_achievements_progress(
			get_unlocked_achievements_count(),
			get_total_achievements_count()
		)

	if main.stats_panel.has_method("set_achievements_data"):
		main.stats_panel.set_achievements_data(get_achievements_ui_data())


func get_achievements_ui_data() -> Array:
	var result: Array = []

	for achievement_id in main.achievements_manager.ACHIEVEMENT_DEFS.keys():
		var def: Dictionary = main.achievements_manager.ACHIEVEMENT_DEFS[achievement_id]
		result.append({
			"id": achievement_id,
			"title": String(def.get("title", "")),
			"condition": get_achievement_condition_text(def),
			"desc": String(def.get("desc", "")),
			"icon": def.get("icon", null),
			"unlocked": bool(main.achievements_manager.achievements_unlocked.get(achievement_id, false)),
			"hidden": bool(def.get("hidden", false))
		})

	return result


func get_unlocked_achievements_count() -> int:
	var total := 0
	for achievement_id in main.achievements_manager.achievements_unlocked.keys():
		if main.achievements_manager.achievements_unlocked[achievement_id]:
			total += 1
	return total


func get_total_achievements_count() -> int:
	return main.achievements_manager.ACHIEVEMENT_DEFS.size()


func get_achievement_condition_text(def: Dictionary) -> String:
	return "Desbloqueo: %s" % String(def.get("condition", "Desbloqueo especial"))


func register_alien_minigame_result(won: bool) -> void:
	if won:
		main.alien_minigame_wins += 1
	else:
		main.alien_minigame_losses += 1
