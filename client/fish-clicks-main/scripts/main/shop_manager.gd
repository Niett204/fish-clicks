extends Node
class_name ShopManager

var main: Node = null


func setup(main_ref: Node) -> void:
	main = main_ref


func add_item_card_to_list(id: String, list: VBoxContainer) -> void:
	var def: Dictionary = main.ITEMS[id]

	var card = main.shop_item_card_scene.instantiate()
	card.info_panel_path = main.info_panel.get_path()
	list.add_child(card)

	var unlock_price: int = int(def.get("unlock_price", 0))
	var icon_texture: Texture2D = load(String(def.get("icon", "")))

	card.setup(
		id,
		String(def.get("title", id)),
		"%d" % get_price(id),
		get_item_effect_text(id),
		str(get_level(id)),
		icon_texture,
		get_price(id),
		unlock_price
	)

	card.extra_title = String(def.get("title", id))
	card.extra_desc = "\"Mejora tu producción.\""
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
	var total: float = 0.0

	for key in main.ITEMS.keys():
		var id := String(key)
		var def: Dictionary = main.ITEMS[id]
		if String(def.get("kind", "")) == "passive":
			total += get_item_current_value(id)

	return total


func get_level(id: String) -> int:
	return int(main.levels.get(id, 0))


func get_price(id: String) -> int:
	var def: Dictionary = main.ITEMS[id]
	var base_price: float = float(def.get("base_price", 10.0))
	var growth: float = float(def.get("price_growth", 1.1))
	return int(round(base_price * pow(growth, get_level(id))))


func apply_purchase(id: String) -> void:
	main.levels[id] = get_level(id) + 1

	match id:
		"cofre":
			main.click_power = int(round(get_item_current_value("cofre")))
			main._update_chest_sprite_by_level()
		"vallisneria":
			main._update_algas_sprite_by_level()
		"tronco":
			main._update_tronco_visibility_by_level()
		"anubia":
			main._update_anubia_sprite_by_level()

	update_cps()

func on_buy_pressed(id: String) -> void:
	var price: int = get_price(id)
	if main.coins < price:
		return

	main.ui_manager.play_ui_sfx(main.SFX_BUY_ITEM)

	main.coins -= price
	if String(main.ITEMS[id].get("tab", "")) == "Estructuras":
		main.achievements_manager.register_structure_spent(price)

	apply_purchase(id)

	if main.fish_defs.has(id):
		var spawned_fish_id: String = id
		var is_shiny := false

		if randf() < 0.01 and main.fish_defs.has(id + "_shiny"):
			spawned_fish_id = id + "_shiny"
			is_shiny = true
			main.achievements_manager.register_shiny_obtained()

		var slot_index: int = main.aquarium_manager.try_add_fish_to_aquarium(main.current_habitat, spawned_fish_id)

		if slot_index != -1:
			main.aquarium_manager.spawn_fish(spawned_fish_id, main.current_habitat, slot_index)
		else:
			main.fish_inventory[spawned_fish_id] = int(main.fish_inventory.get(spawned_fish_id, 0)) + 1

		if is_shiny:
			await main.get_tree().create_timer(0.5).timeout
			main.ui_manager.play_ui_sfx(main.SFX_SHINY)

	main.aquarium_manager.refresh_inventory_panel_data()
	main.ui_manager._update_ui()
	main.achievements_manager.check_achievements()

	if main.stats_panel.visible:
		main.stats_manager.refresh_stats_values_only()

func on_unlock_pressed(id: String) -> void:
	if bool(main.unlocked.get(id, false)):
		return

	var unlock_price: int = int(main.ITEMS[id].get("unlock_price", 0))
	if main.coins < unlock_price:
		return

	main.coins -= unlock_price
	if String(main.ITEMS[id].get("tab", "")) == "Estructuras" and id != "cofre":
		main.achievements_manager.register_structure_spent(unlock_price)

	main.unlocked[id] = true

	match id:
		"vallisneria":
			main._update_algas_sprite_by_level()
		"tronco":
			main._update_tronco_visibility_by_level()

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
		"passive":
			return "%s +%d" % [value_label, int(round(base_value))]
		"click":
			return "+%d %s" % [int(round(base_value)), value_label]
		_:
			return ""


func get_tooltip_line_1(id: String) -> String:
	if id == "cofre":
		return "Potencia de clic: %d" % main.click_power
	return "Produce ahora: %s" % get_current_production_text(id)


func get_tooltip_line_2(id: String) -> String:
	if id == "cofre":
		return "Aporte pasivo: ninguno"
	return "Aporta al DPS total: %.1f%%" % get_current_dps_contribution(id)


func get_tooltip_line_3(id: String) -> String:
	return "Generado total: %s" % get_lifetime_generated_text(id)


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
		"passive":
			return float(level) * base_value
		"click":
			if level <= 0:
				return 1.0
			return 1.0 + level * base_value
		_:
			return 0.0


func get_current_dps_contribution(id: String) -> float:
	var total_dps: float = get_total_passive_dps()
	if total_dps <= 0.0:
		return 0.0

	var def: Dictionary = main.ITEMS[id]
	if String(def.get("kind", "")) != "passive":
		return 0.0

	return (get_item_current_value(id) / total_dps) * 100.0


func get_lifetime_generated_text(id: String) -> String:
	var amount: float = float(main.lifetime_generated.get(id, 0.0))
	return "%s doblones" % main.format_with_separator(int(amount))


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
