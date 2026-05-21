extends Node
class_name ShopManager

var main: Node = null


func setup(main_ref: Node) -> void:
	main = main_ref


func item_belongs_to_current_habitat(id: String) -> bool:
	var def: Dictionary = main.ITEMS[id]
	var current_habitat: String = main.habitat_manager.current_habitat
	var habitat_ids: Array = def.get("habitat_ids", ["habitat_1"])
	return current_habitat in habitat_ids


func add_item_card_to_list(id: String, list: VBoxContainer) -> void:
	if not item_belongs_to_current_habitat(id):
		return

	if is_item_locked_by_progress(id):
		return

	if id == "auspezio" and not bool(main.unlocked.get("auspezio", false)):
		return

	var def: Dictionary = main.ITEMS[id]
	var card = main.shop_item_card_scene.instantiate()
	card.info_panel_path = main.info_panel.get_path()
	list.add_child(card)

	var unlock_price: int = int(def.get("unlock_price", 0))
	var icon_texture: Texture2D = load(String(def.get("icon", "")))

	var level_text := str(get_level(id))
	var max_level := get_max_level(id)

	if max_level > 0 and get_level(id) >= max_level:
		level_text = "MAX"
	
	var price_text: String = main.get_full_number_text(get_price(id))

	if max_level > 0 and get_level(id) >= max_level:
		price_text = "MAX"

	card.setup(
		id,
		String(def.get("title", id)),
		price_text,
		get_item_effect_text(id),
		level_text,
		icon_texture,
		get_price(id),
		unlock_price
	)
	
	card.set_locked_text(get_locked_text(id))

	card.extra_title = String(def.get("title", id))
	card.extra_desc = "\"" + get_flavor_text(id) + "\""
	card.extra_b1 = get_tooltip_line_1(id)
	card.extra_b2 = get_tooltip_line_2(id)
	card.extra_b3 = get_tooltip_line_3(id)

	card.set_unlocked(bool(main.unlocked.get(id, unlock_price == 0)))
	card.update_state(main.coins)
	card.buy_pressed.connect(on_buy_pressed)
	card.unlock_pressed.connect(on_unlock_pressed)


func update_cps() -> void:
	main.dps = get_total_passive_dps()
	main.ui_manager._update_dps_ui()


func get_total_passive_dps() -> float:
	# Solo los peces generan DPS base. Las estructuras multiplican ese valor.
	var fish_dps: float = 0.0

	for key in main.ITEMS.keys():
		var id := String(key)
		var def: Dictionary = main.ITEMS[id]

		if String(def.get("kind", "")) == "fish":
			fish_dps += get_item_current_value(id)

	return fish_dps * get_fish_dps_multiplier() * get_global_coin_multiplier()


func get_fish_dps_multiplier() -> float:
	var multiplier := 1.0

	for key in main.ITEMS.keys():
		var id := String(key)
		var def: Dictionary = main.ITEMS[id]

		if String(def.get("kind", "")) != "structure_buff":
			continue
		if String(def.get("buff_type", "")) != "fish_dps_multiplier":
			continue

		multiplier += float(get_level(id)) * float(def.get("base_value", 0.0))

	return multiplier


func get_global_coin_multiplier() -> float:
	var multiplier := 1.0

	for key in main.ITEMS.keys():
		var id := String(key)
		var def: Dictionary = main.ITEMS[id]

		if String(def.get("kind", "")) != "structure_buff":
			continue
		if String(def.get("buff_type", "")) != "global_coin_multiplier":
			continue

		multiplier += float(get_level(id)) * float(def.get("base_value", 0.0))

	return multiplier


func get_shiny_chance() -> float:
	var chance := 0.01

	for key in main.ITEMS.keys():
		var id := String(key)
		var def: Dictionary = main.ITEMS[id]

		if String(def.get("kind", "")) != "structure_buff":
			continue
		if String(def.get("buff_type", "")) != "shiny_chance_bonus":
			continue

		chance += float(get_level(id)) * float(def.get("base_value", 0.0))

	# Cap para que no se vaya de madre: 1% base + hasta 5% extra = 6%.
	return min(chance, 0.06)


func get_click_income() -> int:
	var base_click := 1.0

	for key in main.ITEMS.keys():
		var id := String(key)
		var def: Dictionary = main.ITEMS[id]

		if String(def.get("kind", "")) != "structure_buff":
			continue
		if String(def.get("buff_type", "")) != "click_flat":
			continue

		base_click += float(get_level(id)) * float(def.get("base_value", 0.0))

	var click_multiplier := 1.0

	for key in main.ITEMS.keys():
		var id := String(key)
		var def: Dictionary = main.ITEMS[id]

		if String(def.get("buff_type", "")) != "click_multiplier":
			continue

		click_multiplier += float(get_level(id)) * float(def.get("base_value", 0.0))

	return max(1, int(round(base_click * click_multiplier * get_global_coin_multiplier())))


func get_level(id: String) -> int:
	return int(main.levels.get(id, 0))


func get_max_level(id: String) -> int:
	return int(main.ITEMS[id].get("max_level", -1))


func get_price(id: String) -> int:
	var def: Dictionary = main.ITEMS[id]
	var base_price: float = float(def.get("base_price", 10.0))
	var growth: float = float(def.get("price_growth", 1.1))
	return int(round(base_price * pow(growth, get_level(id))))


func apply_purchase(id: String) -> void:
	main.levels[id] = get_level(id) + 1

	match id:
		"cofre":
			main.click_power = get_click_income()
			main._update_chest_sprite_by_level()
		"vallisneria":
			main._update_algas_sprite_by_level()
		"tronco":
			main._update_tronco_visibility_by_level()
		"anubia":
			main._update_anubia_sprite_by_level()
		"coral":
			main._update_coral_sprite_by_level()
		"piedra":
			main._update_piedra_sprite_by_level()
		"iceberg":
			main._update_iceberg_sprite_by_level()
		"barco":
			main._update_barco_sprite_by_level()

	update_cps()
	main.ui_manager.update_unique_tab_visibility()


func on_buy_pressed(id: String) -> void:
	var max_level := get_max_level(id)

	if max_level > 0 and get_level(id) >= max_level:
		return

	var price: int = get_price(id)

	if main.coins < price:
		return

	main.ui_manager.play_ui_sfx(main.SFX_BUY_ITEM)

	main.coins -= price
	if String(main.ITEMS[id].get("tab", "")) == "Estructuras":
		main.achievements_manager.register_structure_spent(price)

	apply_purchase(id)

	var should_spawn_fish: bool = main.fish_defs.has(id)

	if is_unique_fish(id) and has_fish_anywhere(id):
		should_spawn_fish = false

	if should_spawn_fish:
		var spawned_fish_id: String = id
		var is_shiny := false

		if randf() < get_shiny_chance() and main.fish_defs.has(id + "_shiny"):
			spawned_fish_id = id + "_shiny"
			is_shiny = true
			main.achievements_manager.register_shiny_obtained()

		var slot_index: int = main.aquarium_manager.try_add_fish_to_aquarium(
			main.habitat_manager.current_habitat,
			spawned_fish_id
		)

		if slot_index != -1:
			main.aquarium_manager.spawn_fish(
				spawned_fish_id,
				main.habitat_manager.current_habitat,
				slot_index
			)
		else:
			main.fish_inventory[spawned_fish_id] = int(main.fish_inventory.get(spawned_fish_id, 0)) + 1

		if is_shiny:
			await main.get_tree().create_timer(0.5).timeout
			main.ui_manager.play_ui_sfx(main.SFX_SHINY)

	main.aquarium_manager.refresh_inventory_panel_data()
	main.ui_manager._update_ui()
	main.alien_manager.check_alien_event_unlock()
	main.achievements_manager.check_achievements()

	if main.stats_panel.visible:
		main.stats_manager.refresh_stats_values_only()


func on_unlock_pressed(id: String) -> void:
	if id == "auspezio" || id == "chupete_jr":
		return

	if main.ITEMS[id].has("unlock_clicks"):
		return

	if is_item_locked_by_progress(id):
		return
		
	if bool(main.unlocked.get(id, false)):
		return

	var unlock_price: int = int(main.ITEMS[id].get("unlock_price", 0))
	if main.coins < unlock_price:
		return

	main.coins -= unlock_price
	if String(main.ITEMS[id].get("tab", "")) == "Estructuras" and id != "cofre":
		main.achievements_manager.register_structure_spent(unlock_price)

	main.unlocked[id] = true
	main.ui_manager.update_unique_tab_visibility()

	match id:
		"vallisneria":
			main._update_algas_sprite_by_level()
		"tronco":
			main._update_tronco_visibility_by_level()
		"anubia":
			main._update_anubia_sprite_by_level()
		"coral":
			main._update_coral_sprite_by_level()
		"piedra":
			main._update_piedra_sprite_by_level()
		"iceberg":
			main._update_iceberg_sprite_by_level()
		"barco":
			main._update_barco_sprite_by_level()

	main.habitat_manager.update_habitat_unlocks()
	main.update_world_button_visibility()

	if main.shop_open:
		await main.ui_manager._refresh_current_shop_tab(main.tab_container.current_tab)
	else:
		main.ui_manager._update_ui()
	main._actualizar_peces_desbloqueados_en_enciclopedia()
	main.achievements_manager.check_achievements()

	if main.stats_panel.visible:
		main.stats_manager.refresh_stats_values_only()


func get_item_effect_text(id: String) -> String:
	var def: Dictionary = main.ITEMS[id]
	var kind: String = String(def.get("kind", ""))
	var base_value: float = float(def.get("base_value", 0.0))
	var value_label: String = String(def.get("value_label", ""))

	match kind:
		"fish":
			return "DPS +%d" % int(round(base_value))

		"structure_buff":
			var buff_type := String(def.get("buff_type", ""))

			match buff_type:
				"click_flat":
					return "+%.2f %s" % [base_value, value_label]

				"shiny_chance_bonus":
					return "+%.2f%% shiny" % (base_value * 100.0)

				_:
					return "+%.1f%s" % [base_value * 100.0, value_label]


		"unique_buff":
			var buff_type := String(def.get("buff_type", ""))

			match buff_type:
				"cleaning_speed":
					return "+15% de velocidad en limpieza."

				"alien_time_reduction":
					return "-2s en la batalla del alien."

				"critical_click":
					return "Clics críticos +2%."
				_:
					return "Buff único"
					
		_:
			return ""


func get_tooltip_line_1(id: String) -> String:
	var def: Dictionary = main.ITEMS[id]
	var kind := String(def.get("kind", ""))

	if kind == "structure_buff":
		return get_structure_buff_current_text(id)

	if kind == "unique_buff":
		return get_unique_buff_current_text(id)

	return "Produce ahora: %s" % get_current_production_text(id)


func get_tooltip_line_2(id: String) -> String:
	var def: Dictionary = main.ITEMS[id]
	var kind := String(def.get("kind", ""))

	if kind == "structure_buff":
		return get_structure_buff_next_text(id)

	if kind == "unique_buff":
		return get_unique_buff_next_text(id)

	return "Aporta al DPS total: %.1f%%" % get_current_dps_contribution(id)


func get_structure_buff_next_text(id: String) -> String:
	var def: Dictionary = main.ITEMS[id]
	var buff_type := String(def.get("buff_type", ""))
	var base_value := float(def.get("base_value", 0.0))

	match buff_type:
		"click_flat":
			return "Siguiente nivel: +%.2f doblones/clic" % base_value
		"fish_dps_multiplier":
			return "Siguiente nivel: +%.1f%% peces" % (base_value * 100.0)
		"global_coin_multiplier":
			return "Siguiente nivel: +%.1f%% general" % (base_value * 100.0)
		"shiny_chance_bonus":
			return "Siguiente nivel: +%.3f%% shiny" % (base_value * 100.0)
		_:
			return "Nivel infinito"


func get_tooltip_line_3(id: String) -> String:
	var def: Dictionary = main.ITEMS[id]
	var kind := String(def.get("kind", ""))

	if kind == "structure_buff":
		return get_structure_buff_impact_text(id)

	if kind == "unique_buff":
		return get_unique_buff_impact_text(id)

	return "Generado total: %s" % get_lifetime_generated_text(id)


func get_unique_buff_current_text(id: String) -> String:
	var level := get_level(id)

	match id:
		"chupete_jr":
			return "Limpieza x%.2f" % (1.0 + level * 0.15)

		"auspezio":
			return "Supervivencia -%ds" % int(level * 2)

		"piranha":
			return "%d%% de clic crítico" % int(
				get_critical_click_chance() * 100.0
			)
	
		_:
			return "Buff activo"


func get_unique_buff_next_text(id: String) -> String:
	match id:
		"chupete_jr":
			return "Siguiente nivel: +15%"

		"auspezio":
			return "Siguiente nivel: -2s"
			
		"piranha":
			return "Siguiente nivel: +2% crítico"
		_:
			return "Mejora única"


func get_unique_buff_impact_text(id: String) -> String:
	var level := get_level(id)

	match id:
		"chupete_jr":
			return "Bonus total: +%d%%" % int(level * 15)

		"auspezio":
			return "Tiempo reducido: %ds" % int(level * 2)

		"piranha":
			return "Los críticos hacen x%.0f daño" % (
				get_critical_click_multiplier()
			)
	
		_:
			return "Buff activo"

func get_structure_buff_impact_text(id: String) -> String:
	var def: Dictionary = main.ITEMS[id]
	var buff_type := String(def.get("buff_type", ""))
	var level := get_level(id)
	var value := float(def.get("base_value", 0.0))
	var total_bonus := float(level) * value

	match buff_type:
		"click_flat":
			return "Bonus total: +%s/clic" % main.get_full_number_text(total_bonus)
		"fish_dps_multiplier":
			return "Multiplicador peces: x%.2f" % (1.0 + total_bonus)
		"global_coin_multiplier":
			return "Multiplicador global: x%.2f" % (1.0 + total_bonus)
		"shiny_chance_bonus":
			return "Bonus shiny total: +%.2f%%" % (total_bonus * 100.0)
		"alien_minigame_time_reduction":
			return "Reduce minijuego: %.0fs" % total_bonus
		_:
			return "Buff activo"


func get_current_production_text(id: String) -> String:
	var def: Dictionary = main.ITEMS[id]
	var value_label: String = String(def.get("value_label", ""))
	var value: float = get_item_current_value(id)
	return "%d %s" % [int(round(value)), value_label]


func get_item_current_value(id: String) -> float:
	var def: Dictionary = main.ITEMS[id]
	var kind: String = String(def.get("kind", ""))
	var base_value: float = float(def.get("base_value", 1.0))
	var level: int = get_level(id)

	match kind:
		"fish":
			return float(level) * base_value
		"structure_buff":
			return float(level) * base_value
		_:
			return 0.0


func get_structure_buff_current_text(id: String) -> String:
	var def: Dictionary = main.ITEMS[id]
	var buff_type := String(def.get("buff_type", ""))
	var value := get_item_current_value(id)

	match buff_type:
		"click_flat":
			return "Clic actual: +%d doblones" % get_click_income()
		"fish_dps_multiplier":
			return "Buff peces: +%.1f%%" % (value * 100.0)
		"global_coin_multiplier":
			return "Buff general: +%.1f%%" % (value * 100.0)
		"shiny_chance_bonus":
			return "Prob. shiny: %.2f%%" % (get_shiny_chance() * 100.0)
		_:
			return "Buff activo"


func get_current_dps_contribution(id: String) -> float:
	var def: Dictionary = main.ITEMS[id]
	if String(def.get("kind", "")) != "fish":
		return 0.0

	var total_base_fish_dps := 0.0

	for key in main.ITEMS.keys():
		var fish_id := String(key)
		var fish_def: Dictionary = main.ITEMS[fish_id]

		if String(fish_def.get("kind", "")) != "fish":
			continue

		total_base_fish_dps += get_item_current_value(fish_id)

	if total_base_fish_dps <= 0.0:
		return 0.0

	return (get_item_current_value(id) / total_base_fish_dps) * 100.0


func get_lifetime_generated_text(id: String) -> String:
	var amount: float = float(main.lifetime_generated.get(id, 0.0))
	return main.get_full_number_text(amount)


func get_total_structures_count() -> int:
	var total := 0

	for id in main.ITEMS.keys():
		var item_id := String(id)

		if String(main.ITEMS[item_id].get("tab", "")) != "Estructuras":
			continue

		if item_id == "cofre":
			continue

		total += get_level(item_id)

	return total


func get_total_unlocked_structures_count() -> int:
	var total := 0

	for id in main.ITEMS.keys():
		var item_id := String(id)
		var def: Dictionary = main.ITEMS[item_id]

		if String(def.get("tab", "")) != "Estructuras":
			continue

		if item_id == "cofre":
			continue

		if bool(main.unlocked.get(item_id, false)):
			total += 1

	return total

# Progresión por cadenas de desbloqueo.
func is_item_locked_by_progress(id: String) -> bool:
	if id == "auspezio":
		return not bool(main.unlocked.get("auspezio", false))

	if id == "chupete_jr":
		return false

	# Mundo 1
	if id in ["doblon", "vallisneria"]:
		return not bool(main.unlocked.get("cofre", false))
	if id in ["sobrasada", "tronco"]:
		return not bool(main.unlocked.get("vallisneria", false))
	if id in ["espuma", "anubia"]:
		return not bool(main.unlocked.get("tronco", false))
	if id == "rufinus":
		return not bool(main.unlocked.get("anubia", false))

	# Mundo 2
	if id == "coral":
		return not bool(main.unlocked.get("cofre", false))
	if id in ["piedra", "barbacoa"]:
		return not bool(main.unlocked.get("coral", false))
	if id in ["angeles", "iceberg"]:
		return not bool(main.unlocked.get("piedra", false))
	if id in ["jigou", "barco"]:
		return not bool(main.unlocked.get("iceberg", false))
	if id == "leonardo":
		return not bool(main.unlocked.get("barco", false))

	return false
	
func get_locked_text(id: String) -> String:
	
	if main.ITEMS[id].has("unlock_clicks"):
		var current: int = int(main.total_clicks)
		var required := int(main.ITEMS[id].get("unlock_clicks", 0))
		return "Clicks %d/%d" % [current, required]
	
	if id == "auspezio":
		return "Nace de un huevo alienígena"

	if id == "chupete_jr":
		var current := 0
		var target := 5

		if main.cleaning_manager != null:
			current = main.cleaning_manager.get_cleaner_fish_progress()
			target = main.cleaning_manager.CLEANER_FISH_REQUIRED_EVENTS

		return "Limpiezas %d/%d" % [current, target]

	var unlock_price := float(main.ITEMS[id].get("unlock_price", 0))
	return main.get_compact_number_text(unlock_price)
	

func get_auspezio_minigame_time_reduction() -> float:
	var level := get_level("auspezio")

	if level <= 0:
		return 0.0

	var reduction_per_level := 2.0  # segundos por nivel
	return level * reduction_per_level


func is_unique_fish(id: String) -> bool:
	return id == "chupete_jr" \
		or id == "auspezio" \
		or id == "piranha"


func has_fish_anywhere(fish_id: String) -> bool:
	if int(main.fish_inventory.get(fish_id, 0)) > 0:
		return true

	for habitat_id in main.aquarium_data.keys():
		for slot_fish_id in main.aquarium_data[habitat_id]:
			if slot_fish_id != null and str(slot_fish_id) == fish_id:
				return true

	return false


func get_flavor_text(id: String) -> String:
	match id:

		# --- PECES MUNDO 1 ---
		"doblon":
			return "Tu primer generador."
		"sobrasada":
			return "Más carne, más monedas."
		"espuma":
			return "La producción despega."
		"rufinus":
			return "Poder económico puro."

		# --- PECES MUNDO 2 ---
		"barbacoa":
			return "Las aguas se calientan."
		"angeles":
			return "Elegancia con beneficios."
		"jigou":
			return "Producción a otro nivel."
		"leonardo":
			return "El rey del acuario."

		# --- ESTRUCTURAS ---
		"cofre":
			return "Cada clic vale más."
		"vallisneria":
			return "Los peces crecen mejor."
		"tronco":
			return "Todo produce más."
		"anubia":
			return "Raíces del progreso."

		"coral":
			return "Vida entre el hielo."
		"piedra":
			return "Economía sólida."
		"iceberg":
			return "Frío, pero rentable."
		"barco":
			return "Más suerte exótica."

		# --- ÚNICOS ---
		"chupete_jr":
			return "Siempre deja todo limpio."
		"auspezio":
			return "No debería existir."
		"piranha":
			return "A veces muerde el cofre."
		_:
			return "Una nueva mejora."

func get_critical_click_chance() -> float:
	var level := get_level("piranha")
	var base_value := float(main.ITEMS["piranha"].get("base_value", 0.0))
	return min(float(level) * base_value, 0.25)


func get_critical_click_multiplier() -> float:
	return float(main.ITEMS["piranha"].get("critical_multiplier", 5.0))
