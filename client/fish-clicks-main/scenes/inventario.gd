extends Control

signal close_requested
signal move_fish_to_inventory(fish_id: String, slot_index: int, habitat_id: String)
signal move_fish_to_aquarium(fish_id: String, habitat_id: String, slot_index: int)
signal move_fish_within_aquarium(from_slot_index: int, to_slot_index: int, habitat_id: String)
signal habitat_changed(habitat_id: String)

const AQUARIUM_SLOT_SCENE := preload("res://scenes/aquarium_slot.tscn")
const SHELF_ROW_SCENE := preload("res://scenes/inventory_shelf_row.tscn")
const INVENTORY_FISH_ITEM_SCENE := preload("res://scenes/inventory_fish_item.tscn")
const BAG_TEXTURE := preload("res://assets/ui/inventario/bolsa_vacia.png")
const HABITAT_TAB_TEXTURE := preload("res://assets/ui/rarezas/tag_rareza_comun.png")
const DROP_DARK_BASE := 0.42
const DROP_LIGHT_BASE := 0.28
const DROP_PULSE_AMPLITUDE := 0.10
const DROP_PULSE_SPEED := 5.5
const HABITAT_TAB_FONT := preload("res://assets/fuentes/PirataOne-Regular.ttf")

@onready var btn_close: TextureButton = $BtnClose
@onready var habitat_tabs: HBoxContainer = $HabitatTabs
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

@onready var sfx_player: AudioStreamPlayer = $SfxPlayer

const SFX_COGER_PEZ: AudioStream = preload("res://assets/audio/UI/coger_pez_inventario.wav")

var habitats: Dictionary = {}
var unlocked_habitats: Array[String] = []
var current_habitat: String = ""
var aquarium_data: Dictionary = {}
var fish_defs: Dictionary = {}
var fish_inventory: Dictionary = {}
var min_shelves := 4

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
var aquarium_slots: Array = []
var hovered_aquarium_slot = null

func _ready():
	btn_close.pressed.connect(_on_btn_close_pressed)
	btn_close.mouse_entered.connect(_on_btn_close_mouse_entered)
	btn_close.mouse_exited.connect(_on_btn_close_mouse_exited)
	btn_close.button_down.connect(_on_btn_close_button_down)
	btn_close.button_up.connect(_on_btn_close_button_up)

	aquarium_drop_zone.visible = false
	shelf_drop_zone.visible = false

	aquarium_drop_zone.color = Color(0, 0, 0, 0.18)
	shelf_drop_zone.color = Color(0, 0, 0, 0.18)

	pecera_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pecera_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shelf_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	habitat_tabs.add_theme_constant_override("separation", 0)

	await get_tree().process_frame

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

	rebuild_habitat_tabs()
	build_aquarium_grid()
	build_shelf_list()
	refresh_panel()

func rebuild_habitat_tabs() -> void:
	for child in habitat_tabs.get_children():
		child.queue_free()

	await get_tree().process_frame

	habitat_tabs.visible = unlocked_habitats.size() > 1
	habitat_tabs.add_theme_constant_override("separation", 0)

	for habitat_id in unlocked_habitats:
		if not habitats.has(habitat_id):
			continue

		var btn := TextureButton.new()
		btn.texture_normal = HABITAT_TAB_TEXTURE
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_SCALE
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.clip_contents = true

		var is_selected := habitat_id == current_habitat

		if is_selected:
			btn.modulate = Color(0.95, 0.85, 0.65, 1.0)
		else:
			btn.modulate = Color(1, 1, 1, 1)

		var label := Label.new()
		label.text = habitats[habitat_id]["name"]
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.add_theme_font_override("font", HABITAT_TAB_FONT)
		label.add_theme_font_size_override("font_size", 16)
		label.modulate = Color(0.2, 0.12, 0.05, 1.0)
		
		var base_scale := Vector2.ONE
		var hover_scale := Vector2(1.05, 1.05)

		var base_modulate := btn.modulate
		var hover_modulate := Color(
			min(base_modulate.r + 0.08, 1.0),
			min(base_modulate.g + 0.08, 1.0),
			min(base_modulate.b + 0.08, 1.0),
			base_modulate.a
		)

		btn.mouse_entered.connect(func():
			if habitat_id == current_habitat:
				return

			var tween := create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(btn, "scale", hover_scale, 0.10)
			tween.parallel().tween_property(btn, "modulate", hover_modulate, 0.10)
		)

		btn.mouse_exited.connect(func():
			if habitat_id == current_habitat:
				return

			var tween := create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(btn, "scale", base_scale, 0.10)
			tween.parallel().tween_property(btn, "modulate", base_modulate, 0.10)
		)
		
		btn.button_down.connect(func():
			if habitat_id == current_habitat:
				return

			var tween := create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(btn, "scale", Vector2(0.97, 0.97), 0.05)
		)

		btn.button_up.connect(func():
			if habitat_id == current_habitat:
				return

			var is_hover := btn.get_global_rect().has_point(get_global_mouse_position())
			var target_scale := hover_scale if is_hover else base_scale
			var target_modulate := hover_modulate if is_hover else base_modulate

			var tween := create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(btn, "scale", target_scale, 0.08)
			tween.parallel().tween_property(btn, "modulate", target_modulate, 0.08)
		)
		
		var text_width := HABITAT_TAB_FONT.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x

		btn.custom_minimum_size = Vector2(maxf(ceil(text_width) + 10.0, 76.0), 38.0)

		btn.add_child(label)

		btn.pressed.connect(func():
			set_current_habitat(habitat_id)
		)

		@warning_ignore("shadowed_global_identifier")
		var wrap := MarginContainer.new()
		wrap.add_theme_constant_override("margin_right", -8)
		wrap.add_child(btn)
		habitat_tabs.add_child(wrap)

func set_current_habitat(habitat_id: String) -> void:
	if not unlocked_habitats.has(habitat_id):
		return

	if current_habitat == habitat_id:
		return

	clear_drag()
	current_habitat = habitat_id

	build_aquarium_grid()
	build_shelf_list()
	rebuild_habitat_tabs()
	refresh_panel()

	habitat_changed.emit(habitat_id)

func refresh_panel() -> void:
	if not habitats.has(current_habitat):
		return

	label_titulo_pecera.text = "Pecera de %s" % habitats[current_habitat]["name"]

	if habitats[current_habitat].has("background"):
		pecera_background.texture = habitats[current_habitat]["background"]

func build_aquarium_grid() -> void:
	for child in pecera_grid.get_children():
		child.queue_free()

	aquarium_slots.clear()
	hovered_aquarium_slot = null

	await get_tree().process_frame

	pecera_grid.columns = 5

	var slots = aquarium_data[current_habitat]

	for i in range(slots.size()):
		var slot = AQUARIUM_SLOT_SCENE.instantiate()
		pecera_grid.add_child(slot)
		aquarium_slots.append(slot)

		var fish_id = slots[i]

		if fish_id != null:
			var fish_texture = fish_defs[fish_id]["icon"]
			slot.setup(fish_texture, i, fish_id)
		else:
			slot.setup(null, i, "")
		
		slot.pressed_slot.connect(_on_aquarium_slot_pressed)

func _start_aquarium_slot_highlights() -> void:
	for slot in aquarium_slots:
		if slot.my_fish_id == "":
			slot.start_highlight()
		else:
			slot.stop_highlight()

func _stop_aquarium_slot_highlights() -> void:
	for slot in aquarium_slots:
		slot.stop_highlight()
		slot.set_hover_drop_feedback(false)

	hovered_aquarium_slot = null

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

			var is_shiny := fish_id.ends_with("_shiny")
			var base_fish_id := fish_id.replace("_shiny", "")
			var icon_to_use: Texture2D = fish_defs[base_fish_id]["icon"]
			if fish_defs.has(fish_id):
				icon_to_use = fish_defs[fish_id]["icon"]

			item.setup(
				icon_to_use,
				int(fish_inventory[fish_id]),
				BAG_TEXTURE,
				fish_id,
				fish_defs[base_fish_id].get("name", base_fish_id),
				is_shiny
			)

			var fish_matches_habitat := fish_belongs_to_current_habitat(fish_id)

			item.pressed_item.connect(_on_inventory_item_pressed)
			item.scale = Vector2(0.9, 0.9)

			if fish_matches_habitat:
				item.modulate = Color(1, 1, 1, 0.0)
			else:
				item.modulate = Color(0.55, 0.55, 0.55, 0.0)

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
	
	if not fish_belongs_to_current_habitat(fish_id):
		return
	
	begin_pending_drag(fish_id, "inventory", -1)

func begin_pending_drag(fish_id: String, source: String, slot_index: int) -> void:
	pending_drag = true
	pending_fish_id = fish_id
	pending_source = source
	pending_slot_index = slot_index
	drag_start_mouse_pos = get_viewport().get_mouse_position()
	
func start_drag(fish_id: String, source: String, slot_index: int) -> void:
	var base_fish_id := fish_id.replace("_shiny", "")
	if not fish_defs.has(base_fish_id):
		return
	
	if source == "inventory" and not fish_belongs_to_current_habitat(fish_id):
		return
	
	play_sfx(SFX_COGER_PEZ)
		
	drag_fish_id = fish_id
	drag_source = source
	drag_slot_index = slot_index
	is_dragging = true

	aquarium_drop_zone.visible = false
	shelf_drop_zone.visible = false
	
	if source == "aquarium":
		shelf_drop_zone.visible = true
		shelf_drop_zone.color = Color(0, 0, 0, 0.18)
		_start_aquarium_slot_highlights()
	elif source == "inventory":
		aquarium_drop_zone.visible = true
		aquarium_drop_zone.color = Color(0, 0, 0, 0.18)
		_start_aquarium_slot_highlights()

	if drag_preview:
		drag_preview.queue_free()

	drag_preview = TextureRect.new()
	drag_preview.texture = fish_defs[base_fish_id]["icon"]
	if fish_defs.has(fish_id):
		drag_preview.texture = fish_defs[fish_id]["icon"]
	drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	drag_preview.custom_minimum_size = Vector2(48, 48)
	drag_preview.z_index = 999
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(drag_preview)

	var mouse_pos = get_viewport().get_mouse_position()
	drag_preview.global_position = mouse_pos - drag_preview.custom_minimum_size / 2.0

func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return

	sfx_player.stream = stream
	sfx_player.pitch_scale = randf_range(0.95, 1.1)
	sfx_player.stop()
	sfx_player.play()
	
func _get_aquarium_slot_under_mouse(mouse_pos: Vector2):
	for slot in aquarium_slots:
		if slot.get_global_rect().has_point(mouse_pos):
			return slot
	return null	
	
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
		
		if drag_source == "inventory":
			var slot_under_mouse = _get_aquarium_slot_under_mouse(mouse_pos)

			if slot_under_mouse != hovered_aquarium_slot:
				if hovered_aquarium_slot != null:
					hovered_aquarium_slot.set_hover_drop_feedback(false)

				hovered_aquarium_slot = slot_under_mouse

				if hovered_aquarium_slot != null and hovered_aquarium_slot.my_fish_id == "":
					hovered_aquarium_slot.set_hover_drop_feedback(true)

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

	var over_shelf := _is_point_inside_control(shelf_panel, mouse_pos)
	var slot_under_mouse = _get_aquarium_slot_under_mouse(mouse_pos)

	if drag_source == "aquarium":
		if over_shelf:
			move_fish_to_inventory.emit(drag_fish_id, drag_slot_index, current_habitat)
		elif slot_under_mouse != null and slot_under_mouse.my_slot_index != drag_slot_index:
			move_fish_within_aquarium.emit(drag_slot_index, slot_under_mouse.my_slot_index, current_habitat)

	elif drag_source == "inventory":
		if slot_under_mouse != null and fish_belongs_to_current_habitat(drag_fish_id):
			move_fish_to_aquarium.emit(drag_fish_id, current_habitat, slot_under_mouse.my_slot_index)
		
	clear_drag()

func clear_drag() -> void:
	is_dragging = false
	drag_fish_id = ""
	drag_source = ""
	drag_slot_index = -1

	_stop_aquarium_slot_highlights()

	aquarium_drop_zone.visible = false
	shelf_drop_zone.visible = false

	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null

func _is_point_inside_control(control: Control, point: Vector2) -> bool:
	return control.get_global_rect().has_point(point)

func _on_btn_close_pressed() -> void:
	close_requested.emit()

func _on_btn_close_mouse_entered() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(btn_close, "scale", Vector2(1.08, 1.08), 0.08)
	tween.parallel().tween_property(btn_close, "modulate", Color(0.85, 0.85, 0.85, 1.0), 0.08)

func _on_btn_close_mouse_exited() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(btn_close, "scale", Vector2.ONE, 0.08)
	tween.parallel().tween_property(btn_close, "modulate", Color(1, 1, 1, 1), 0.08)

func _on_btn_close_button_down() -> void:
	var tween := create_tween()
	tween.tween_property(btn_close, "scale", Vector2(0.94, 0.94), 0.05)
	btn_close.modulate = Color(0.7, 0.7, 0.7, 1.0)

func _on_btn_close_button_up() -> void:
	var hover := btn_close.get_global_rect().has_point(get_global_mouse_position())
	var target_scale := Vector2(1.08, 1.08) if hover else Vector2.ONE
	var target_modulate := Color(0.85, 0.85, 0.85, 1.0) if hover else Color(1, 1, 1, 1)

	var tween := create_tween()
	tween.tween_property(btn_close, "scale", target_scale, 0.06)
	tween.parallel().tween_property(btn_close, "modulate", target_modulate, 0.06)

# Para el cambio de hábitat
func fish_belongs_to_current_habitat(fish_id: String) -> bool:
	var base_fish_id := fish_id.replace("_shiny", "")
	
	if not fish_defs.has(base_fish_id):
		return false
	
	var def: Dictionary = fish_defs[base_fish_id]
	var fish_habitat: String = String(def.get("habitat", "habitat_1"))
	
	return fish_habitat == current_habitat
