extends Node
class_name AquariumManager

var main: Node = null


func setup(main_ref: Node) -> void:
	main = main_ref


func spawn_fish(
	fish_id: String,
	habitat_id: String,
	slot_index: int,
	play_spawn_animation: bool = true,
	initial_global_position: Variant = null
) -> Node:
	var fish = main.fish_scene.instantiate()

	if "swim_area" in fish:
		fish.swim_area = main.get_node("ContentPecera/SwimArea")
	else:
		push_error("El pez no tiene propiedad swim_area")

	main.fish_layer.add_child(fish)

	if fish.has_method("setup_fish_instance"):
		fish.setup_fish_instance(fish_id, habitat_id, slot_index)

	fish.visible = habitat_id == main.habitat_manager.current_habitat

	if main.fish_defs.has(fish_id) and fish.has_method("set_fish_texture"):
		var tex: Texture2D = main.fish_defs[fish_id]["icon"]
		fish.set_fish_texture(tex)

	if initial_global_position != null:
		fish.global_position = initial_global_position

	if play_spawn_animation:
		var target_pos := Vector2(
			randi_range(120, 920),
			randi_range(120, 520)
		)

		if fish.has_method("play_spawn_arc"):
			fish.play_spawn_arc(target_pos)
		else:
			fish.position = target_pos

	return fish
	

func try_add_fish_to_aquarium(habitat_id: String, fish_id: String) -> int:
	if not main.aquarium_data.has(habitat_id):
		return -1

	var slots: Array = main.aquarium_data[habitat_id]

	for i in range(slots.size()):
		if slots[i] == null:
			slots[i] = fish_id
			main.aquarium_data[habitat_id] = slots
			return i

	return -1


func on_move_fish_to_inventory(fish_id: String, slot_index: int, habitat_id: String) -> void:
	if not main.aquarium_data.has(habitat_id):
		return

	var slots: Array = main.aquarium_data[habitat_id]

	if slot_index < 0 or slot_index >= slots.size():
		return

	if slots[slot_index] != fish_id:
		return

	slots[slot_index] = null
	main.aquarium_data[habitat_id] = slots

	remove_spawned_fish_from_aquarium(habitat_id, slot_index)

	main.fish_inventory[fish_id] = int(main.fish_inventory.get(fish_id, 0)) + 1

	refresh_inventory_panel_data()
	main.alien_manager.check_alien_event_unlock()


func on_move_fish_to_aquarium(fish_id: String, habitat_id: String, slot_index: int) -> void:
	if int(main.fish_inventory.get(fish_id, 0)) <= 0:
		return

	if not main.aquarium_data.has(habitat_id):
		return

	var slots: Array = main.aquarium_data[habitat_id]

	if slot_index < 0 or slot_index >= slots.size():
		return

	var replaced_fish_id = slots[slot_index]

	if replaced_fish_id != null:
		main.fish_inventory[replaced_fish_id] = int(main.fish_inventory.get(replaced_fish_id, 0)) + 1
		remove_spawned_fish_from_aquarium(habitat_id, slot_index)

	slots[slot_index] = fish_id
	main.aquarium_data[habitat_id] = slots

	main.fish_inventory[fish_id] = int(main.fish_inventory.get(fish_id, 0)) - 1
	if int(main.fish_inventory[fish_id]) <= 0:
		main.fish_inventory.erase(fish_id)

	spawn_fish(fish_id, habitat_id, slot_index)
	refresh_visible_fish_by_habitat()
	refresh_inventory_panel_data()
	main.alien_manager.check_alien_event_unlock()


func on_move_fish_within_aquarium(from_slot_index: int, to_slot_index: int, habitat_id: String) -> void:
	if not main.aquarium_data.has(habitat_id):
		return

	var slots: Array = main.aquarium_data[habitat_id]

	if from_slot_index < 0 or from_slot_index >= slots.size():
		return
	if to_slot_index < 0 or to_slot_index >= slots.size():
		return
	if from_slot_index == to_slot_index:
		return
	if slots[from_slot_index] == null:
		return

	var from_fish_id = slots[from_slot_index]
	var to_fish_id = slots[to_slot_index]

	slots[from_slot_index] = to_fish_id
	slots[to_slot_index] = from_fish_id
	main.aquarium_data[habitat_id] = slots

	swap_spawned_fish_slots(habitat_id, from_slot_index, to_slot_index)

	refresh_inventory_panel_data()


func refresh_visible_fish_by_habitat() -> void:
	for child in main.fish_layer.get_children():
		child.visible = child.get("habitat_id") == main.habitat_manager.current_habitat


func on_inventory_habitat_changed(habitat_id: String) -> void:
	main.habitat_manager.inventory_habitat = habitat_id


func swap_spawned_fish_slots(habitat_id: String, from_slot_index: int, to_slot_index: int) -> void:
	var fish_from = null
	var fish_to = null

	for child in main.fish_layer.get_children():
		if child.get("habitat_id") != habitat_id:
			continue

		if child.get("slot_index") == from_slot_index:
			fish_from = child
		elif child.get("slot_index") == to_slot_index:
			fish_to = child

	if fish_from != null:
		fish_from.slot_index = to_slot_index
	if fish_to != null:
		fish_to.slot_index = from_slot_index


func move_spawned_fish_to_aquarium_slot(habitat_id: String, from_slot_index: int, to_slot_index: int) -> void:
	for child in main.fish_layer.get_children():
		if child.get("habitat_id") == habitat_id and child.get("slot_index") == from_slot_index:
			child.slot_index = to_slot_index
			return


func refresh_inventory_panel_data() -> void:
	if main.inventory_panel.visible:
		main.inventory_panel.set_inventory_data(
			main.HABITATS,
			main.habitat_manager.unlocked_habitats,
			main.habitat_manager.inventory_habitat,
			main.aquarium_data,
			main.fish_defs,
			main.fish_inventory
		)


func remove_spawned_fish_from_aquarium(habitat_id: String, slot_index: int) -> void:
	for child in main.fish_layer.get_children():
		if child.get("habitat_id") == habitat_id and child.get("slot_index") == slot_index:
			child.queue_free()
			return


func get_total_fish_count() -> int:
	var total := 0

	for habitat_id in main.aquarium_data.keys():
		for fish_id in main.aquarium_data[habitat_id]:
			if fish_id != null:
				total += 1

	for fish_id in main.fish_inventory.keys():
		total += int(main.fish_inventory[fish_id])

	return total


func get_total_special_fish_count() -> int:
	var total := 0

	for habitat_id in main.aquarium_data.keys():
		for fish_id in main.aquarium_data[habitat_id]:
			if fish_id != null and String(fish_id).ends_with("_shiny"):
				total += 1

	for fish_id in main.fish_inventory.keys():
		if String(fish_id).ends_with("_shiny"):
			total += int(main.fish_inventory[fish_id])

	return total


func get_total_shiny_fish_count() -> int:
	var total := 0

	for habitat_id in main.aquarium_data.keys():
		var slots = main.aquarium_data[habitat_id]
		for fish_id in slots:
			if fish_id != null and String(fish_id).ends_with("_shiny"):
				total += 1

	for fish_id in main.fish_inventory.keys():
		if String(fish_id).ends_with("_shiny"):
			total += int(main.fish_inventory[fish_id])

	return total

func get_spawned_fish_by_id(fish_id: String) -> Node2D:
	for child in main.fish_layer.get_children():
		if child == null or not is_instance_valid(child):
			continue

		if String(child.get("fish_id")) == fish_id:
			return child as Node2D

	return null

func has_fish_in_aquarium(fish_id: String) -> bool:
	for habitat_id in main.aquarium_data.keys():
		var slots: Array = main.aquarium_data[habitat_id]

		for slot_fish_id in slots:
			if slot_fish_id != null and String(slot_fish_id) == fish_id:
				return true

	return false

func set_fish_visual_hidden_by_id(fish_id: String, hidden: bool) -> void:
	for child in main.fish_layer.get_children():
		if child == null or not is_instance_valid(child):
			continue

		if String(child.get("fish_id")) != fish_id:
			continue

		if hidden:
			child.visible = false
		else:
			child.visible = child.get("habitat_id") == main.habitat_manager.current_habitat
