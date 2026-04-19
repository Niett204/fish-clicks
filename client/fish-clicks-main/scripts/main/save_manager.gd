extends Node
class_name SaveManager

var main: Node = null

func setup(main_ref: Node) -> void:
	main = main_ref

func get_save_state() -> Dictionary:
	var aquarium_serialized := {}

	for habitat_id in main.aquarium_data.keys():
		var slots := []
		for slot in main.aquarium_data[habitat_id]:
			slots.append(slot if slot != null else "")
		aquarium_serialized[habitat_id] = slots

	return {
		"user_photo": GlobalData.user_photo_url, # Añadido para que se guarde la foto
		"coins": main.coins,
		"levels": main.levels,
		"unlocked": main.unlocked,
		"lifetime_generated": main.lifetime_generated,
		"achievements_unlocked": main.achievements_manager.achievements_unlocked,
		"random_tick_unlocked": main.achievements_manager.random_tick_unlocked,
		"volume_slider_spam_unlocked": main.achievements_manager.volume_slider_spam_unlocked,
		"aquarium_data": aquarium_serialized,
		"current_habitat": main.current_habitat,
		"unlocked_habitats": main.unlocked_habitats,
		"sound_volume": AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")),
		"total_clicks": main.total_clicks,
		"total_coins_earned": main.total_coins_earned,
		"total_shinies_ever": main.achievements_manager.total_shinies_ever,
		"session_time_seconds": main.session_time_seconds,
		"fish_inventory": main.fish_inventory,
		"game_start_date": main.game_start_date_string,
		"total_structures_spent": main.achievements_manager.total_structures_spent,
		"alien_clicked_count": main.achievements_manager.alien_clicked_count,
		"profile_clicks_count": main.achievements_manager.profile_clicks_count,
		"annoyed_fish_count": main.achievements_manager.annoyed_fish_count,
	}

func reset_local_state() -> void:
	# Reseteo de variables en Main
	main.coins = 0.0
	main.total_coins_earned = 0.0
	main.total_clicks = 0
	main.session_time_seconds = 0.0
	main.click_power = 1

	main.levels.clear()
	main.unlocked.clear()
	main.fish_inventory.clear()

	# Re-inicializar desbloqueos gratuitos
	for k in main.ITEMS.keys():
		var id := String(k)
		main.levels[id] = 0
		main.unlocked[id] = int(main.ITEMS[id].get("unlock_price", 0)) == 0

	# Reseteo de Logros
	main.achievements_manager.achievements_unlocked.clear()
	for achievement_id in main.achievements_manager.ACHIEVEMENT_DEFS.keys():
		main.achievements_manager.achievements_unlocked[achievement_id] = false

	main.achievements_manager.random_tick_unlocked = false
	main.achievements_manager.volume_slider_spam_unlocked = false
	main.achievements_manager.total_shinies_ever = 0
	main.achievements_manager.total_structures_spent = 0.0
	main.achievements_manager.alien_clicked_count = 0
	main.achievements_manager.profile_clicks_count = 0
	main.achievements_manager.annoyed_fish_count = 0
	main.achievements_manager.achievement_check_accum = 0.0

	# Limpieza de Acuarios
	for habitat_id in main.aquarium_data.keys():
		var empty_slots := []
		empty_slots.resize(10)
		empty_slots.fill(null)
		main.aquarium_data[habitat_id] = empty_slots

	for child in main.fish_layer.get_children():
		child.queue_free()
	
	main.alien_manager.alien_event_state = AlienManager.AlienEventState.IDLE
	main.alien_manager.alien_event_available = false
	main.alien_manager.alien_event_done = false

	if main.alien_manager.alien_instance != null:
		main.alien_manager.alien_instance.queue_free()
		main.alien_manager.alien_instance = null
	
	# Actualización Visual
	main.shop_manager.update_cps()
	main._update_chest_sprite_by_level()
	main._update_algas_sprite_by_level()
	main._update_tronco_visibility_by_level()
	main._update_anubia_sprite_by_level()
	main.ui_manager._update_ui()
	GlobalData.user_photo_url = ""

func apply_save_state(state: Dictionary, spawn_visual_fish: bool = true) -> void:
	if state.is_empty():
		print("Cuenta nueva sin datos. Manteniendo progreso local.")
		return 

	reset_local_state() 

	if state.has("user_photo"):
		GlobalData.user_photo_url = state["user_photo"]
		main.get_tree().call_group("main_hud_buttons", "update_avatar")
	
	main.coins = float(state.get("coins", 0.0))

	var saved_levels: Dictionary = state.get("levels", {})
	for k in saved_levels:
		main.levels[k] = int(saved_levels[k])

	var saved_unlocked: Dictionary = state.get("unlocked", {})
	for k in saved_unlocked:
		main.unlocked[k] = bool(saved_unlocked[k])

	var saved_lifetime: Dictionary = state.get("lifetime_generated", {})
	for k in saved_lifetime:
		main.lifetime_generated[k] = float(saved_lifetime[k])

	var saved_achievements: Dictionary = state.get("achievements_unlocked", {})
	for k in saved_achievements:
		main.achievements_manager.achievements_unlocked[k] = bool(saved_achievements[k])

	main.achievements_manager.random_tick_unlocked = bool(state.get("random_tick_unlocked", false))
	main.achievements_manager.volume_slider_spam_unlocked = bool(state.get("volume_slider_spam_unlocked", false))
	main.current_habitat = state.get("current_habitat", "habitat_1")

	var saved_habitats = state.get("unlocked_habitats", ["habitat_1"])
	main.unlocked_habitats.clear()
	for h in saved_habitats:
		main.unlocked_habitats.append(str(h))

	var saved_aquarium: Dictionary = state.get("aquarium_data", {})

	for child in main.fish_layer.get_children():
		child.queue_free()

	for habitat_id in main.aquarium_data.keys():
		var empty_slots := []
		empty_slots.resize(main.aquarium_data[habitat_id].size())
		empty_slots.fill(null)
		main.aquarium_data[habitat_id] = empty_slots

	for habitat_id in saved_aquarium.keys():
		if not main.aquarium_data.has(habitat_id):
			continue

		var slots: Array = saved_aquarium[habitat_id]
		for slot_index in slots.size():
			var fish_id = slots[slot_index]
			if fish_id == null or fish_id == "":
				continue

			main.aquarium_data[habitat_id][slot_index] = fish_id

			if spawn_visual_fish:
				main.aquarium_manager.spawn_fish(fish_id, habitat_id, slot_index)

	if state.has("sound_volume"):
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index("Master"),
			state["sound_volume"]
		)

	main.total_clicks = int(state.get("total_clicks", 0))
	main.total_coins_earned = float(state.get("total_coins_earned", 0.0))
	main.achievements_manager.total_shinies_ever = int(state.get("total_shinies_ever", 0))
	main.session_time_seconds = float(state.get("session_time_seconds", 0.0))
	main.game_start_date_string = state.get("game_start_date", main.game_start_date_string)
	main.achievements_manager.total_structures_spent = float(state.get("total_structures_spent", 0.0))
	main.achievements_manager.alien_clicked_count = int(state.get("alien_clicked_count", 0))
	main.achievements_manager.profile_clicks_count = int(state.get("profile_clicks_count", 0))
	main.achievements_manager.annoyed_fish_count = int(state.get("annoyed_fish_count", 0))

	main.fish_inventory = state.get("fish_inventory", {})

	main.shop_manager.update_cps()
	main.ui_manager._update_ui()
	main._actualizar_peces_desbloqueados_en_enciclopedia()

	main._update_algas_sprite_by_level()
	main._update_anubia_sprite_by_level()
	main._update_tronco_visibility_by_level()
	main._update_chest_sprite_by_level()
	main.alien_manager.check_alien_event_unlock()
