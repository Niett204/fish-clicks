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
		"current_habitat": main.habitat_manager.current_habitat,
		"unlocked_habitats": main.habitat_manager.unlocked_habitats,
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
		"total_dirt_spots_cleaned": main.cleaning_manager.total_dirt_spots_cleaned,
		"cleaning_events_completed": main.cleaning_manager.cleaning_events_completed,
		"alien_minigame_wins": main.alien_minigame_wins,
		"alien_minigame_losses": main.alien_minigame_losses,
		"alien_egg": main.egg_manager.get_save_state(),
		"alien_no_hit_unlocked": main.achievements_manager.alien_no_hit_unlocked,
		"alien_egg_obtained": main.achievements_manager.alien_egg_obtained,
		"alien_coin_debuff_multiplier": main.alien_coin_debuff_multiplier,
		"audio": {
			"master_volume": AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")),
			"music_volume": AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Musica")),
			"sfx_volume": AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Efectos")),
			"master_muted": AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")),
			"music_muted": AudioServer.is_bus_mute(AudioServer.get_bus_index("Musica")),
			"sfx_muted": AudioServer.is_bus_mute(AudioServer.get_bus_index("Efectos"))
		}
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
	
	# Reseteo de habitats
	main.habitat_manager.unlocked_habitats.clear()
	main.habitat_manager.unlocked_habitats.append("habitat_1")

	main.habitat_manager.current_habitat = "habitat_1"
	main.habitat_manager.inventory_habitat = "habitat_1"
	
	main.alien_minigame_wins = 0
	main.alien_minigame_losses = 0
	main.alien_coin_debuff_multiplier = 1.0
	
	if main.egg_manager != null:
		main.egg_manager.clear_active_egg()
	
	# Re-inicializar desbloqueos gratuitos
	for k in main.ITEMS.keys():
		var id := String(k)
		main.levels[id] = 0
		main.unlocked[id] = main._is_item_unlocked_by_default(id)

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
	main.cleaning_manager.total_dirt_spots_cleaned = 0
	main.cleaning_manager.cleaning_events_completed = 0

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
	main.habitat_manager.apply_current_habitat()
	GlobalData.user_photo_url = ""

func apply_save_state(state: Dictionary, spawn_visual_fish: bool = true) -> void:
	if state.is_empty():
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
	main.habitat_manager.current_habitat = state.get("current_habitat", "habitat_1")
	
	var saved_habitats = state.get("unlocked_habitats", ["habitat_1"])
	main.habitat_manager.unlocked_habitats.clear()
	for h in saved_habitats:
		main.habitat_manager.unlocked_habitats.append(str(h))

	if not main.habitat_manager.unlocked_habitats.has(main.habitat_manager.current_habitat):
		main.habitat_manager.current_habitat = main.habitat_manager.unlocked_habitats[0]

	main.habitat_manager.inventory_habitat = main.habitat_manager.current_habitat

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
	
	if state.has("audio"):
		var audio: Dictionary = state["audio"]

		_set_bus_volume("Master", float(audio.get("master_volume", 0.0)))
		_set_bus_volume("Musica", float(audio.get("music_volume", 0.0)))
		_set_bus_volume("Efectos", float(audio.get("sfx_volume", 0.0)))

		_set_bus_mute("Master", bool(audio.get("master_muted", false)))
		_set_bus_mute("Musica", bool(audio.get("music_muted", false)))
		_set_bus_mute("Efectos", bool(audio.get("sfx_muted", false)))

	main.total_clicks = int(state.get("total_clicks", 0))
	main.total_coins_earned = float(state.get("total_coins_earned", 0.0))
	main.achievements_manager.total_shinies_ever = int(state.get("total_shinies_ever", 0))
	main.session_time_seconds = float(state.get("session_time_seconds", 0.0))
	main.game_start_date_string = state.get("game_start_date", main.game_start_date_string)
	main.achievements_manager.total_structures_spent = float(state.get("total_structures_spent", 0.0))
	main.achievements_manager.alien_clicked_count = int(state.get("alien_clicked_count", 0))
	main.achievements_manager.profile_clicks_count = int(state.get("profile_clicks_count", 0))
	main.achievements_manager.annoyed_fish_count = int(state.get("annoyed_fish_count", 0))
	main.cleaning_manager.total_dirt_spots_cleaned = int(state.get("total_dirt_spots_cleaned", 0))
	main.cleaning_manager.cleaning_events_completed = int(state.get("cleaning_events_completed", 0))
	main.alien_minigame_wins = int(state.get("alien_minigame_wins", 0))
	main.alien_minigame_losses = int(state.get("alien_minigame_losses", 0))
	main.alien_coin_debuff_multiplier = float(state.get("alien_coin_debuff_multiplier", 1.0))
	main.cleaning_manager.try_unlock_cleaner_fish()
	main.achievements_manager.alien_no_hit_unlocked = bool(state.get("alien_no_hit_unlocked", false))
	main.achievements_manager.alien_egg_obtained = bool(state.get("alien_egg_obtained", false))

	main.fish_inventory = state.get("fish_inventory", {})

	main.shop_manager.update_cps()
	main.ui_manager._update_ui()
	main._actualizar_peces_desbloqueados_en_enciclopedia()

	if main.egg_manager != null:
		main.egg_manager.apply_save_state(state.get("alien_egg", {}))

	main._update_algas_sprite_by_level()
	main._update_anubia_sprite_by_level()
	main._update_tronco_visibility_by_level()
	main._update_chest_sprite_by_level()
	main.alien_manager.check_alien_event_unlock()
	main.habitat_manager.apply_current_habitat()

func _set_bus_volume(bus_name: String, volume_db: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, volume_db)


func _set_bus_mute(bus_name: String, muted: bool) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_mute(bus_index, muted)
