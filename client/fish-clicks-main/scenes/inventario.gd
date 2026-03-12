extends Control

signal close_requested
signal move_fish_to_inventory(fish_id: String, slot_index: int, habitat_id: String)
signal move_fish_to_aquarium(fish_id: String, habitat_id: String)

const AQUARIUM_SLOT_SCENE := preload("res://scenes/aquarium_slot.tscn")
const SHELF_ROW_SCENE := preload("res://scenes/inventory_shelf_row.tscn")
const INVENTORY_FISH_ITEM_SCENE := preload("res://scenes/inventory_fish_item.tscn")
const BAG_TEXTURE := preload("res://assets/ui/inventario/bolsa_vacia.png")
const DROP_DARK_BASE := 0.42
const DROP_LIGHT_BASE := 0.28
const DROP_PULSE_AMPLITUDE := 0.10
const DROP_PULSE_SPEED := 5.5

@onready var btn_close: TextureButton = $MarginContainer/Fondo/BtnClose
@onready var habitat_tabs: HBoxContainer = $MarginContainer/Fondo/HabitatTabs
@onready var pecera_background: TextureRect = $MarginContainer/Fondo/Content/LeftSide/VBoxContainer/PeceraPanel/GlassArea/PeceraBackground
@onready var label_titulo_pecera: Label = $MarginContainer/Fondo/Content/LeftSide/LabelTituloPecera
@onready var pecera_grid: GridContainer = $MarginContainer/Fondo/Content/LeftSide/VBoxContainer/PeceraPanel/GlassArea/PeceraBackground/MarginContainer/PeceraGrid
@onready var shelf_list: VBoxContainer = $MarginContainer/Fondo/Content/RightSide/ShelfPanel/MarginContainer/ScrollContainer/VBoxContainer
@onready var pecera_frame: TextureRect = $MarginContainer/Fondo/Content/LeftSide/VBoxContainer/PeceraPanel/PeceraFrame
@onready var shelf_frame: TextureRect = $MarginContainer/Fondo/Content/RightSide/ShelfPanel/TextureRect
@onready var glass_area: Control = $MarginContainer/Fondo/Content/LeftSide/VBoxContainer/PeceraPanel/GlassArea
@onready var shelf_panel: Control = $MarginContainer/Fondo/Content/RightSide/ShelfPanel
@onready var aquarium_drop_zone: ColorRect = $MarginContainer/Fondo/Content/LeftSide/VBoxContainer/PeceraPanel/GlassArea/AquariumDropZone
@onready var shelf_drop_zone: Control = $MarginContainer/Fondo/Content/RightSide/ShelfPanel/ShelfDropZone

var habitats: Dictionary = {}
var unlocked_habitats: Array[String] = []
var current_habitat: String = ""
var aquarium_data: Dictionary = {}
var fish_defs: Dictionary = {}
var fish_inventory: Dictionary = {}
var min_shelves := 3

var drag_fish_id: String = ""
var drag_source: String = "" # "aquarium" o "inventory"
var drag_slot_index: int = -1
var drag_preview: TextureRect = null
var is_dragging := false
var pending_drag := false
var pending_fish_id: String = ""
var pending_source: String = ""
var pending_slot_index: int = -1
var drag_start_mouse_pos: Vector2 = Vector2.ZERO
const DRAG_THRESHOLD := 10.0

func _ready() -> void:
	btn_close.pressed.connect(func():
		close_requested.emit()
	)

	aquarium_drop_zone.visible = false
	shelf_drop_zone.visible = false

	aquarium_drop_zone.color = Color(0, 0, 0, 0.18)
	shelf_drop_zone.color = Color(0, 0, 0, 0.18)

	pecera_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pecera_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shelf_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass_area.mouse_filter = Control.MOUSE_FILTER_IGNORE

	await get_tree().process_frame
	print("aquarium_drop_zone rect:", aquarium_drop_zone.get_global_rect())
	print("shelf_drop_zone rect:", shelf_drop_zone.get_global_rect())

func set_inventory_data(
	p_habitats: Dictionary,
	p_unlocked_habitats: Array[String],
	p_current_habitat: String,
	p_aquarium_data: Dictionary,
	p_fish_defs: Dictionary,
	p_fish_inventory: Dictionary
) -> void:
	habitats = p_habitats
	unlocked_habitats = p_unlocked_habitats
	current_habitat = p_current_habitat
	aquarium_data = p_aquarium_data
	fish_defs = p_fish_defs
	fish_inventory = p_fish_inventory

	if unlocked_habitats.is_empty():
		return

	if not unlocked_habitats.has(current_habitat):
		current_habitat = unlocked_habitats[0]

	build_aquarium_grid()
	build_shelf_list()
	rebuild_habitat_tabs()
	refresh_panel()

func rebuild_habitat_tabs() -> void:
	for child in habitat_tabs.get_children():
		child.queue_free()

	await get_tree().process_frame

	# si solo hay un hábitat, puedes ocultar la barra
	habitat_tabs.visible = unlocked_habitats.size() > 1

	for habitat_id in unlocked_habitats:
		if not habitats.has(habitat_id):
			continue

		var btn := Button.new()
		btn.text = habitats[habitat_id]["name"]
		btn.custom_minimum_size = Vector2(140, 48)

		btn.pressed.connect(func():
			set_current_habitat(habitat_id)
		)

		habitat_tabs.add_child(btn)

func set_current_habitat(habitat_id: String) -> void:
	if not unlocked_habitats.has(habitat_id):
		return

	current_habitat = habitat_id
	refresh_panel()

func refresh_panel() -> void:
	if not habitats.has(current_habitat):
		return

	label_titulo_pecera.text = "Pecera de %s" % habitats[current_habitat]["name"]

	if habitats[current_habitat].has("background"):
		pecera_background.texture = habitats[current_habitat]["background"]

func build_aquarium_grid() -> void:
	for child in pecera_grid.get_children():
		child.queue_free()

	await get_tree().process_frame

	pecera_grid.columns = 5

	var slots = aquarium_data[current_habitat]

	for i in range(slots.size()):
		var slot = AQUARIUM_SLOT_SCENE.instantiate()
		pecera_grid.add_child(slot)

		var fish_id = slots[i]

		if fish_id != null:
			var fish_texture = fish_defs[fish_id]["icon"]
			slot.setup(fish_texture, i, fish_id)
		else:
			slot.setup(null, i, "")
		
		slot.pressed_slot.connect(_on_aquarium_slot_pressed)

func build_shelf_list() -> void:
	for child in shelf_list.get_children():
		child.queue_free()

	await get_tree().process_frame

	var visible_fish: Array[String] = []

	for fish_id in fish_inventory.keys():
		var amount: int = int(fish_inventory.get(fish_id, 0))
		if amount > 0:
			visible_fish.append(fish_id)

	var items_per_shelf := 3
	var needed_shelves := int(ceil(float(visible_fish.size()) / float(items_per_shelf)))
	var total_shelves := maxi(needed_shelves, min_shelves)

	var fish_index := 0

	for i in range(total_shelves):
		var shelf_row = SHELF_ROW_SCENE.instantiate()
		shelf_list.add_child(shelf_row)

		for j in range(items_per_shelf):
			if fish_index >= visible_fish.size():
				break

			var fish_id := visible_fish[fish_index]
			var item = INVENTORY_FISH_ITEM_SCENE.instantiate()
			shelf_row.items_row.add_child(item)

			item.setup(
				fish_defs[fish_id]["icon"],
				int(fish_inventory[fish_id]),
				BAG_TEXTURE,
				fish_id,
				fish_defs[fish_id].get("name", fish_id)
			)

			item.pressed_item.connect(_on_inventory_item_pressed)

			item.scale = Vector2(0.9, 0.9)
			item.modulate.a = 0.0

			var t := create_tween()
			t.set_trans(Tween.TRANS_BACK)
			t.set_ease(Tween.EASE_OUT)
			t.tween_interval(fish_index * 0.03)
			t.tween_property(item, "scale", Vector2.ONE, 0.18)

			var t2 := create_tween()
			t2.tween_interval(fish_index * 0.03)
			t2.tween_property(item, "modulate:a", 1.0, 0.12)

			fish_index += 1

func _on_aquarium_slot_pressed(slot_index: int, fish_id: String) -> void:
	if is_dragging or pending_drag:
		return
	begin_pending_drag(fish_id, "aquarium", slot_index)

func _on_inventory_item_pressed(fish_id: String) -> void:
	if is_dragging or pending_drag:
		return
	begin_pending_drag(fish_id, "inventory", -1)

func begin_pending_drag(fish_id: String, source: String, slot_index: int) -> void:
	pending_drag = true
	pending_fish_id = fish_id
	pending_source = source
	pending_slot_index = slot_index
	drag_start_mouse_pos = get_viewport().get_mouse_position()
	
func start_drag(fish_id: String, source: String, slot_index: int) -> void:
	if not fish_defs.has(fish_id):
		return

	print("start_drag | fish:", fish_id, " source:", source, " slot:", slot_index)

	drag_fish_id = fish_id
	drag_source = source
	drag_slot_index = slot_index
	is_dragging = true

	aquarium_drop_zone.visible = false
	shelf_drop_zone.visible = false

	if source == "aquarium":
		shelf_drop_zone.visible = true
		shelf_drop_zone.color = Color(0, 0, 0, 0.18)
	elif source == "inventory":
		aquarium_drop_zone.visible = true
		aquarium_drop_zone.color = Color(0, 0, 0, 0.18)

	if drag_preview:
		drag_preview.queue_free()

	drag_preview = TextureRect.new()
	drag_preview.texture = fish_defs[fish_id]["icon"]
	drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	drag_preview.custom_minimum_size = Vector2(48, 48)
	drag_preview.z_index = 999
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(drag_preview)

	var mouse_pos = get_viewport().get_mouse_position()
	drag_preview.global_position = mouse_pos - drag_preview.custom_minimum_size / 2.0
	
func _process(_delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()

	if pending_drag and not is_dragging:
		if mouse_pos.distance_to(drag_start_mouse_pos) >= DRAG_THRESHOLD:
			start_drag(pending_fish_id, pending_source, pending_slot_index)
			pending_drag = false

	if is_dragging and drag_preview:
		drag_preview.global_position = mouse_pos - drag_preview.custom_minimum_size / 2.0
	
	if is_dragging:
		var over_aquarium := _is_point_inside_control(glass_area, mouse_pos)
		var over_shelf := _is_point_inside_control(shelf_panel, mouse_pos)

		var pulse := (sin(Time.get_ticks_msec() / 1000.0 * DROP_PULSE_SPEED) + 1.0) * 0.5
		var dark_alpha: float = clamp(DROP_DARK_BASE + pulse * DROP_PULSE_AMPLITUDE, 0.0, 1.0)
		var light_alpha: float = clamp(DROP_LIGHT_BASE + pulse * DROP_PULSE_AMPLITUDE, 0.0, 1.0)

		if drag_source == "aquarium":
			if over_shelf:
				shelf_drop_zone.color = Color(0, 0, 0, light_alpha)
			else:
				shelf_drop_zone.color = Color(0, 0, 0, dark_alpha)

		elif drag_source == "inventory":
			if over_aquarium:
				aquarium_drop_zone.color = Color(0, 0, 0, light_alpha)
			else:
				aquarium_drop_zone.color = Color(0, 0, 0, dark_alpha)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if is_dragging:
			finish_drag()
		else:
			pending_drag = false

func finish_drag() -> void:
	if not is_dragging:
		return

	var mouse_pos = get_viewport().get_mouse_position()

	var over_aquarium := _is_point_inside_control(pecera_background, mouse_pos)
	var over_shelf := _is_point_inside_control(shelf_panel, mouse_pos)

	print("mouse_pos:", mouse_pos)
	print("glass_area rect:", glass_area.get_global_rect())
	print("shelf_panel rect:", shelf_panel.get_global_rect())
	print("finish_drag | source:", drag_source, " fish:", drag_fish_id, " over_aquarium:", over_aquarium, " over_shelf:", over_shelf)

	if drag_source == "aquarium" and over_shelf:
		move_fish_to_inventory.emit(drag_fish_id, drag_slot_index, current_habitat)
	elif drag_source == "inventory" and over_aquarium:
		move_fish_to_aquarium.emit(drag_fish_id, current_habitat)

	clear_drag()

func clear_drag() -> void:
	is_dragging = false
	drag_fish_id = ""
	drag_source = ""
	drag_slot_index = -1

	aquarium_drop_zone.visible = false
	shelf_drop_zone.visible = false

	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null

func _is_point_inside_control(control: Control, point: Vector2) -> bool:
	return control.get_global_rect().has_point(point)
