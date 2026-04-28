extends Node
class_name HabitatManager

var main: Node = null

const HABITAT_2_REQUIRED_FISH := ["doblon", "sobrasada", "espuma", "rufinus"]

var unlocked_habitats: Array[String] = ["habitat_1"]
var current_habitat: String = "habitat_1"
var inventory_habitat: String = "habitat_1"

func setup(main_ref: Node) -> void:
	main = main_ref

func apply_current_habitat() -> void:
	_update_background()
	_update_world_structure_visibility()
	main.aquarium_manager.refresh_visible_fish_by_habitat()
	main.aquarium_manager.refresh_inventory_panel_data()
	await main.ui_manager.refresh_open_shop_for_current_habitat()

func switch_to_habitat(habitat_id: String) -> void:
	if not unlocked_habitats.has(habitat_id):
		return

	if current_habitat == habitat_id:
		return

	current_habitat = habitat_id
	apply_current_habitat()
	
func can_change_habitat() -> bool:
	return unlocked_habitats.size() > 1
	
func update_habitat_unlocks() -> void:
	if unlocked_habitats.has("habitat_2"):
		return

	for fish_id in HABITAT_2_REQUIRED_FISH:
		if not bool(main.unlocked.get(fish_id, false)):
			return

	unlocked_habitats.append("habitat_2")
	main.aquarium_manager.refresh_inventory_panel_data()
	
func cycle_habitat() -> void:
	update_habitat_unlocks()

	if unlocked_habitats.size() <= 1:
		return

	var current_index := unlocked_habitats.find(current_habitat)

	if current_index == -1:
		current_habitat = unlocked_habitats[0]
	else:
		current_index = (current_index + 1) % unlocked_habitats.size()
		current_habitat = unlocked_habitats[current_index]

	apply_current_habitat()

func set_inventory_habitat(habitat_id: String) -> void:
	inventory_habitat = habitat_id

func _update_background() -> void:
	var habitat_info: Dictionary = main.HABITATS.get(current_habitat, {})
	if habitat_info == null:
		return

	if habitat_info.has("background"):
		main.bg.texture = habitat_info["background"]
	
func _update_world_structure_visibility() -> void:
	var is_habitat_1 := current_habitat == "habitat_1"
	var is_habitat_2 := current_habitat == "habitat_2"

	main.chest.visible = true

	main.vallisneria.visible = is_habitat_1 and main.shop_manager.get_level("vallisneria") > 0
	main.anubia.visible = is_habitat_1 and main.shop_manager.get_level("anubia") > 0
	main.barco.visible = is_habitat_2 and main.shop_manager.get_level("barco") > 0

	var tronco_level = main.shop_manager.get_level("tronco")
	var tronco_unlocked: bool = bool(main.unlocked.get("tronco", false))

	main.tronco_1.visible = false
	main.tronco_2.visible = false
	main.tronco_3.visible = false

	if is_habitat_1 and tronco_unlocked and tronco_level > 0:
		if tronco_level <= 5:
			main.tronco_3.visible = true
		elif tronco_level <= 10:
			main.tronco_2.visible = true
		else:
			main.tronco_1.visible = true
