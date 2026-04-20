extends Node
class_name HabitatManager

var main: Node = null

var unlocked_habitats: Array[String] = ["habitat_1", "habitat_2"]
var current_habitat: String = "habitat_1"
var inventory_habitat: String = "habitat_1"

func setup(main_ref: Node) -> void:
	main = main_ref

func apply_current_habitat() -> void:
	_update_background()
	_update_world_structure_visibility()
	main.aquarium_manager.refresh_visible_fish_by_habitat()
	main.aquarium_manager.refresh_inventory_panel_data()

func switch_to_habitat(habitat_id: String) -> void:
	if not unlocked_habitats.has(habitat_id):
		return

	if current_habitat == habitat_id:
		return

	current_habitat = habitat_id
	apply_current_habitat()

func cycle_habitat() -> void:
	if unlocked_habitats.size() <= 1:
		return

	var current_index := unlocked_habitats.find(current_habitat)
	if current_index == -1:
		current_habitat = unlocked_habitats[0]
	else:
		var next_index := (current_index + 1) % unlocked_habitats.size()
		current_habitat = unlocked_habitats[next_index]

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
	var is_main_aquarium := current_habitat == "habitat_1"

	main.chest.visible = is_main_aquarium
	main.vallisneria.visible = is_main_aquarium and main.shop_manager.get_level("vallisneria") > 0
	main.anubia.visible = is_main_aquarium and main.shop_manager.get_level("anubia") > 0

	var tronco_level = main.shop_manager.get_level("tronco")
	main.tronco_1.visible = is_main_aquarium and tronco_level >= 1
	main.tronco_2.visible = is_main_aquarium and tronco_level >= 2
	main.tronco_3.visible = is_main_aquarium and tronco_level >= 3
