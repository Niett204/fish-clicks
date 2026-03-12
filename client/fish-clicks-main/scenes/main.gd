extends Node2D

const ENCYCLOPEDIA_FISH_IDS := {
	"fish_basic": 1,
	"fish_sobrasada": 2,
	"fish_rufinus": 3,
}
@export var floating_text_scene: PackedScene
@export var fish_scene: PackedScene
@export var dps_per_fish: float = 1.0
@export var shop_item_card_scene: PackedScene

@onready var shop_panel: Control = $UI/Root/HUD/TiendaPanel
@onready var btn_shop_icon: TextureButton = $UI/Root/HUD/TopBar/RightGroup/BtnShop
@onready var encyclopedia_panel: Control = $UI/Root/HUD/EncyclopediaPanel
@onready var btn_encyclopedia_icon: TextureButton = $UI/Root/HUD/TopBar/RightGroup/BtnEncyclopedia
@onready var inventory_panel: Control = $UI/Root/HUD/Inventario
@onready var btn_inventory_icon: TextureButton = $UI/Root/HUD/TopBar/RightGroup/BtnInventory
@onready var coins_label: Label = $UI/Root/HUD/LeftInfoPanel/VBoxContainer/HBoxContainer/DoblonesLabel
@onready var chest: Area2D = $Cofre
@onready var chest_sprite: Sprite2D = $Cofre/Sprite2D
@onready var fish_layer = $PecesLayer
@onready var dps_label: Label = $UI/Root/HUD/LeftInfoPanel/VBoxContainer2/DpsLabel
@onready var unidades_label: Label = $UI/Root/HUD/LeftInfoPanel/VBoxContainer/UnidadesLabel
@onready var tab_container: TabContainer = $UI/Root/HUD/TiendaPanel/TabContainer
@onready var list_peces: VBoxContainer = $UI/Root/HUD/TiendaPanel/TabContainer/Peces/ScrollContainer/ListPeces
@onready var list_estructuras: VBoxContainer = $UI/Root/HUD/TiendaPanel/TabContainer/Estructuras/ScrollContainer/ListEstructuras
@onready var info_panel: Control = $UI/Root/HUD/InfoExtraPanel
@onready var hud: Control = $UI/Root/HUD
@onready var btn_hide: TextureButton = $UI/Root/BtnHideHUD
@onready var http_request: HTTPRequest = $HTTPRequest

const ITEMS := {
	"fish_basic": {
		"tab": "Peces",
		"title": "Doblon",
		"icon": "res://assets/peces/doblon.png",
		"unlock_price": 10,
		"kind": "passive",
		"base_price": 25.0,
		"price_growth": 1.15,
		"base_value": 1.0,
		"value_label": "DPS"
	},
	"cofre": {
		"tab": "Estructuras",
		"title": "Cofre",
		"icon": "res://assets/estructuras/cofre_cerrado.png",
		"unlock_price": 0,
		"kind": "click",
		"base_price": 10.0,
		"price_growth": 1.05,
		"base_value": 1.3,
		"value_label": "clicks"
	},
	"boat": {
		"tab": "Estructuras",
		"title": "Barco",
		"icon": "res://assets/estructuras/cofre_cerrado.png",
		"unlock_price": 300,
		"kind": "passive",
		"base_price": 200.0,
		"price_growth": 1.20,
		"base_value": 5.0,
		"value_label": "DPS"
	}
}

############################################################################
const HABITATS := {
	"habitat_1": {
		"name": "Acuario",
		"background": preload("res://assets/fondos/fondo1.png")
	}
	# en el futuro:
	# "habitat_2": {
	# 	"name": "Hábitat 2",
	# 	"background": preload("res://assets/fondos/fondo2.png")
	# }
}

var unlocked_habitats: Array[String] = ["habitat_1"]
var current_habitat: String = "habitat_1"

var aquarium_data := {
	"habitat_1": [null, null, null, null, null, null, null, null, null, null]
}

var fish_inventory := {
	"fish_basic": 4,
	"sobrasada": 3,
	"pacos": 1000,
	"fish_shiny": 2
}

var fish_defs := {
	"fish_basic": {
		"name": "Doblon",
		"icon": preload("res://assets/peces/doblon.png")
	},
	"sobrasada": {
		"name": "Doblon",
		"icon": preload("res://assets/peces/doblon.png")
	},
	"pacos": {
		"name": "Doblon",
		"icon": preload("res://assets/peces/doblon.png")
	},
	"fish_shiny": {
		"name": "Doblon shiny",
		"icon": preload("res://assets/peces/doblon.png")
	}
}
############################################################################

var lifetime_generated: Dictionary = {
	"fish_basic": 0.0,
	"cofre": 0.0,
	"boat": 0.0
}

const TEX_CHEST_CLOSED := preload("res://assets/estructuras/cofre_cerrado.png")
const TEX_CHEST_EMPTY  := preload("res://assets/estructuras/cofre_abierto_vacio.png")
const TEX_CHEST_MID    := preload("res://assets/estructuras/cofre_abierto_medio.png")
const TEX_CHEST_FULL   := preload("res://assets/estructuras/cofre_abierto_lleno.png")
const ICON_HIDE = preload("res://assets/ui/iconos/icono_hud_abierto.png")
const ICON_SHOW = preload("res://assets/ui/iconos/icono_hud_cerrado.png")

var unlocked: Dictionary = {}  # id -> bool
var levels: Dictionary = {}

var dps: float = 0.0
var coins: float = 0.0 
var click_power: int = 1
var chest_base_scale: Vector2
var shop_open := false
var shop_tween: Tween
var shop_x_open: float
var shop_x_closed: float

var _block_info_hover := false
var hud_visible := true

func _ready() -> void:
	http_request.request_completed.connect(_on_request_completed)

	var url := "https://fish-clicks.onrender.com/api/test"
	http_request.request(url)

	for k in ITEMS.keys():
		var id := String(k)
		levels[id] = 0
		unlocked[id] = int(ITEMS[id].get("unlock_price", 0)) == 0
		lifetime_generated[id] = 0.0

	shop_panel.visible = false
	encyclopedia_panel.visible = false
	chest_base_scale = chest_sprite.scale

	btn_hide.pressed.connect(func():
		play_squish(btn_shop_icon)
		_toggle_hud()
	)

	btn_shop_icon.pressed.connect(func():
		play_squish(btn_shop_icon)
		toggle_shop()
	)

	btn_encyclopedia_icon.pressed.connect(func():
		play_squish(btn_encyclopedia_icon)
		toggle_encyclopedia()
	)

	btn_inventory_icon.pressed.connect(func():
		play_squish(btn_inventory_icon)
		toggle_inventario()
	)

	tab_container.tab_changed.connect(_on_tab_changed)
	_update_chest_sprite_by_level()
	chest.clicked.connect(_on_chest_clicked)

	_update_cps()
	_update_ui()
	_actualizar_peces_desbloqueados_en_enciclopedia()

	inventory_panel.move_fish_to_inventory.connect(_on_move_fish_to_inventory)
	inventory_panel.move_fish_to_aquarium.connect(_on_move_fish_to_aquarium)

	await get_tree().process_frame  # asegura tamaños correctos

	shop_x_open = shop_panel.position.x
	shop_x_closed = shop_x_open + shop_panel.size.x + 20

	shop_panel.position.x = shop_x_closed
	shop_panel.visible = true
	shop_open = false

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Código:", response_code)
	print("Respuesta:", body.get_string_from_utf8())

func _toggle_hud():
	hud_visible = !hud_visible
	hud.visible = hud_visible
	
	if hud.visible:
		btn_hide.texture_normal = ICON_HIDE
	else:
		btn_hide.texture_normal = ICON_SHOW

func toggle_shop() -> void:
	shop_open = !shop_open

	if shop_open:
		encyclopedia_panel.visible = false

	if not shop_open and info_panel:
		info_panel.request_hide()

	shop_tween = create_tween()
	shop_tween.set_trans(Tween.TRANS_QUAD)
	shop_tween.set_ease(Tween.EASE_OUT)

	var target_x := shop_x_open if shop_open else shop_x_closed
	shop_tween.tween_property(shop_panel, "position:x", target_x, 0.25)

	if shop_open:
		_on_tab_changed(tab_container.current_tab)

func toggle_encyclopedia() -> void:
	encyclopedia_panel.visible = !encyclopedia_panel.visible

	if encyclopedia_panel.visible:
		_actualizar_peces_desbloqueados_en_enciclopedia()
		shop_open = false
		if info_panel:
			info_panel.request_hide()
		if shop_tween:
			shop_tween.kill()
		shop_panel.position.x = shop_x_closed

func toggle_inventario() -> void:
	inventory_panel.visible = !inventory_panel.visible

	if inventory_panel.visible:
		shop_open = false
		encyclopedia_panel.visible = false

		if info_panel:
			info_panel.request_hide()

		if shop_tween:
			shop_tween.kill()

		shop_panel.position.x = shop_x_closed

		inventory_panel.set_inventory_data(
			HABITATS,
			unlocked_habitats,
			current_habitat,
			aquarium_data,
			fish_defs,
			fish_inventory
		)

func _on_tab_changed(tab: int) -> void:
	_block_info_hover = true
	if info_panel:
		info_panel.visible = false
	
	var tab_name := tab_container.get_tab_title(tab)

	if tab_name == "Peces":
		_rebuild_tab("Peces", list_peces)
	elif tab_name == "Estructuras":
		_rebuild_tab("Estructuras", list_estructuras)

	update_shop_cards()
	
	await get_tree().process_frame
	_block_info_hover = false

func _rebuild_tab(tab_name: String, list: VBoxContainer) -> void:
	for c in list.get_children():
		c.queue_free()
	await get_tree().process_frame
	_populate_tab(tab_name, list)

func _populate_tab(tab_name: String, list: VBoxContainer) -> void:
	for k in ITEMS.keys():
		var id: String = String(k)
		if String(ITEMS[id]["tab"]) == tab_name:
			add_item_card_to_list(id, list)

func add_item_card_to_list(id: String, list: VBoxContainer) -> void:
	var def: Dictionary = ITEMS[id]

	var card = shop_item_card_scene.instantiate()
	card.info_panel_path = info_panel.get_path()
	list.add_child(card)

	var unlock_price: int = int(def.get("unlock_price", 0))
	var icon_texture: Texture2D = load(String(def.get("icon", "")))

	card.setup(
		id,
		String(def.get("title", id)),
		"Precio: %d" % get_price(id),
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

	card.set_unlocked(bool(unlocked.get(id, unlock_price == 0)))
	card.update_state(coins) # <- importante
	card.buy_pressed.connect(_on_buy_pressed)
	card.unlock_pressed.connect(_on_unlock_pressed)

func _on_chest_clicked() -> void:
	coins += click_power
	lifetime_generated["cofre"] += click_power

	_update_ui()
	_play_click_animation()
	_spawn_floating_text()
	_mostrar_monedas_y_burbujas()

func _spawn_floating_text() -> void:
	var t: Label = floating_text_scene.instantiate()
	add_child(t)

	t.text = "+" + str(click_power)

	var mouse_pos = get_viewport().get_mouse_position()
	t.position = mouse_pos + Vector2(-5, -20)
	t.z_index = 1000

func _update_ui() -> void:
	_update_currency_ui()
	_update_dps_ui()

	if shop_open:
		update_shop_cards()
	
func _on_toggle_tienda_button_pressed() -> void:
	toggle_shop()
		
func _update_cps() -> void:
	dps = get_total_passive_dps()
	_update_dps_ui()

func get_total_passive_dps() -> float:
	var total: float = 0.0

	for key in ITEMS.keys():
		var id := String(key)
		var def: Dictionary = ITEMS[id]
		if String(def.get("kind", "")) == "passive":
			total += get_item_current_value(id)

	return total

func _update_dps_ui() -> void:
	var parts: Dictionary = format_doblones_parts(dps)
	dps_label.text = "+" + parts.value + " " + parts.unit.replace(" de doblones", "").replace(" doblones", "") + "/s"
	
func _process(delta: float) -> void:
	var total_generated: float = get_total_passive_dps() * delta
	coins += total_generated

	lifetime_generated["fish_basic"] += float(get_level("fish_basic")) * dps_per_fish * delta
	lifetime_generated["boat"] += float(get_level("boat")) * 5.0 * delta

	_update_currency_ui()

func _update_currency_ui() -> void:
	var parts := format_doblones_parts(coins)
	coins_label.text = parts.value
	unidades_label.text = parts.unit

func _play_click_animation() -> void:
	var tween = create_tween()
	tween.tween_property(chest_sprite, "scale", chest_base_scale * 1.08, 0.06)
	tween.tween_property(chest_sprite, "scale", chest_base_scale, 0.08)

func get_level(id: String) -> int:
	return int(levels.get(id, 0))

func get_price(id: String) -> int:
	var def: Dictionary = ITEMS[id]
	var base_price: float = float(def.get("base_price", 10.0))
	var growth: float = float(def.get("price_growth", 1.1))
	return int(round(base_price * pow(growth, get_level(id))))

func apply_purchase(id: String) -> void:
	levels[id] = get_level(id) + 1

	match id:
		"fish_basic":
			_spawn_fish()
		"cofre":
			click_power = int(round(get_item_current_value("cofre")))
			_update_chest_sprite_by_level()

	_update_cps()

func _spawn_fish() -> void:
	var fish = fish_scene.instantiate()

	if "swim_area" in fish:
		fish.swim_area = $SwimArea
	else:
		push_error("El pez no tiene propiedad swim_area")

	fish_layer.add_child(fish)
	fish.position = Vector2(randi_range(200, 1000), randi_range(300, 600))

func get_list_for_category(category: String) -> VBoxContainer:
	match category:
		"Peces":
			return list_peces
		"Estructuras":
			return list_estructuras
		_:
			return list_peces

func _on_buy_pressed(id: String) -> void:
	var price := get_price(id)
	if coins < price:
		return

	coins -= price
	apply_purchase(id)

	if fish_defs.has(id):
		var added_to_aquarium := try_add_fish_to_aquarium(current_habitat, id)

		if not added_to_aquarium:
			fish_inventory[id] = int(fish_inventory.get(id, 0)) + 1

	if inventory_panel.visible:
		inventory_panel.set_inventory_data(
			HABITATS,
			unlocked_habitats,
			current_habitat,
			aquarium_data,
			fish_defs,
			fish_inventory
		)

	_update_ui()

func _on_unlock_pressed(id: String) -> void:
	if bool(unlocked.get(id, false)):
		return

	var unlock_price: int = int(ITEMS[id].get("unlock_price", 0))
	if coins < unlock_price:
		return

	coins -= unlock_price
	unlocked[id] = true
	_update_ui()
	_actualizar_peces_desbloqueados_en_enciclopedia()

func update_shop_cards() -> void:
	for card in list_peces.get_children():
		_refresh_card(card)
	for card in list_estructuras.get_children():
		_refresh_card(card)

func _refresh_card(card) -> void:
	var id: String = String(card.item_id)
	var p: int = get_price(id)

	card.set_unlocked(bool(unlocked.get(id, true)))
	card.set_dynamic(
		p,
		"Precio: %d" % p,
		get_item_effect_text(id),
		str(get_level(id))
	)
	card.update_state(coins)

	card.extra_b1 = get_tooltip_line_1(id)
	card.extra_b2 = get_tooltip_line_2(id)
	card.extra_b3 = get_tooltip_line_3(id)

	if card.has_method("refresh_info_panel_if_hovered"):
		card.refresh_info_panel_if_hovered()

func get_item_effect_text(id: String) -> String:
	var def: Dictionary = ITEMS[id]
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
		return "Potencia de clic: %d" % click_power
	return "Produce ahora: %s" % get_current_production_text(id)

func get_tooltip_line_2(id: String) -> String:
	if id == "cofre":
		return "Aporte pasivo: ninguno"
	return "Aporta al DPS total: %.1f%%" % get_current_dps_contribution(id)

func get_tooltip_line_3(id: String) -> String:
	return "Generado total: %s" % get_lifetime_generated_text(id)

func play_squish(node: Control) -> void:
	var t := create_tween()
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	node.scale = Vector2(1, 1)
	t.tween_property(node, "scale", Vector2(0.92, 0.88), 0.06)
	t.tween_property(node, "scale", Vector2(1.02, 1.02), 0.08)
	t.tween_property(node, "scale", Vector2(1, 1), 0.08)

func _on_btn_shop_pressed() -> void:
	pass # Replace with function body.

func _on_btn_hide_hud_pressed() -> void:
	pass # Replace with function body.

func _update_chest_sprite_by_level() -> void:
	var chest_level: int = get_level("cofre")

	if chest_level <= 0:
		chest_sprite.texture = TEX_CHEST_CLOSED
	elif chest_level <= 3:
		chest_sprite.texture = TEX_CHEST_EMPTY
	elif chest_level <= 7:
		chest_sprite.texture = TEX_CHEST_MID
	else:
		chest_sprite.texture = TEX_CHEST_FULL

func _chest_level_up_fx() -> void:
	var t := create_tween()
	t.tween_property(chest_sprite, "scale", chest_base_scale * 1.12, 0.08)
	t.tween_property(chest_sprite, "scale", chest_base_scale, 0.10)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos: Vector2 = get_viewport().get_mouse_position()

		# Asusta peces cercanos al click
		for fish in fish_layer.get_children():
			if fish.has_method("scare_from"):
				if fish.global_position.distance_to(click_pos) < 120:
					fish.scare_from(click_pos)

func format_doblones_parts(n: float) -> Dictionary:
	var abs_n: float = abs(n)
	var txt := ""
	# 🔹 Menos de 1 millón → número completo sin prefijo
	if abs_n < 1_000_000.0:
		txt = format_with_separator(int(round(n)))
		return {"value": txt, "unit": "doblones"}

	var value: float
	var unit: String

	if abs_n < 1_000_000.0:
		value = n / 1_000.0
		unit = "mil doblones"
	elif abs_n < 1_000_000_000.0:
		value = n / 1_000_000.0
		unit = "millón de doblones" if abs(value) < 2.0 else "millones de doblones"
	elif abs_n < 1_000_000_000_000.0:
		value = n / 1_000_000_000.0
		unit = "mil millones de doblones"
	elif abs_n < 1_000_000_000_000_000.0:
		value = n / 1_000_000_000_000.0
		unit = "billón de doblones" if abs(value) < 2.0 else "billones de doblones"
	elif abs_n < 1_000_000_000_000_000_000.0:
		value = n / 1_000_000_000_000_000.0
		unit = "mil billones de doblones"
	else:
		value = n / 1_000_000_000_000_000_000.0
		unit = "trillón de doblones" if abs(value) < 2.0 else "trillones de doblones"

	var decimals: int

	if abs(value) < 10.0:
		decimals = 2
	elif abs(value) < 100.0:
		decimals = 2
	else:
		decimals = 2
	txt = ("%0." + str(decimals) + "f") % value
	txt = txt.replace(".", ",")

	return {"value": txt, "unit": unit}

func format_with_separator(n: int) -> String:
	var s := str(n)
	var result := ""
	while s.length() > 3:
		result = "." + s.substr(s.length() - 3, 3) + result
		s = s.substr(0, s.length() - 3)
	return s + result
	
func _mostrar_monedas_y_burbujas() -> void:
	# Carga imágenes
	var coin_tex: Texture2D = load("res://assets/misc/doblon_tres_cuartos.png")
	var bubble_tex: Texture2D = load("res://assets/misc/burbuja.png")

	# Punto de spawn: un poco más arriba del sprite del cofre 
	var base_pos: Vector2 = chest_sprite.global_position + Vector2(0, -60)

	# Añade los FX al mundo
	var parent: Node = get_tree().current_scene

	# --- Ajuste de escala automático a un tamaño “bonito” en pantalla ---
	var moneda_escalada_px: float = 28.0
	var burbuja_escalada_px: float = 22.0

	var coin_scale: float = 1.0
	if coin_tex and coin_tex.get_size().x > 0:
		coin_scale = moneda_escalada_px / coin_tex.get_size().x

	var bubble_scale: float = 1.0
	if bubble_tex and bubble_tex.get_size().x > 0:
		bubble_scale = burbuja_escalada_px / bubble_tex.get_size().x

	# --- MONEDAS ---
	for i in 8:
		var spr := Sprite2D.new()
		spr.texture = coin_tex
		parent.add_child(spr)

		spr.global_position = base_pos
		spr.scale = Vector2.ONE * coin_scale * randf_range(0.9, 1.2)
		spr.z_index = 2000

		var target := base_pos + Vector2(
			randf_range(-140, 140),
			-randf_range(80, 220)
		)

		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(spr, "global_position", target, 0.55)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(spr, "rotation", randf_range(-2.2, 2.2), 0.55)
		t.tween_property(spr, "modulate:a", 0.0, 0.55)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		# Limpieza
		t.finished.connect(Callable(spr, "queue_free"))

	# --- BURBUJAS ---
	for i in 12:
		var b := Sprite2D.new()
		b.texture = bubble_tex
		parent.add_child(b)

		b.global_position = base_pos + Vector2(randf_range(-12, 12), randf_range(-8, 8))
		b.scale = Vector2.ONE * bubble_scale * randf_range(0.8, 1.4)
		b.modulate.a = randf_range(0.55, 0.9)
		b.z_index = 1990

		var target_b := b.global_position + Vector2(
			randf_range(-70, 70),
			-randf_range(140, 260)
		)

		var tb := create_tween()
		tb.set_parallel(true)
		tb.tween_property(b, "global_position", target_b, 0.95)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tb.tween_property(b, "modulate:a", 0.0, 0.95)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		tb.finished.connect(Callable(b, "queue_free"))

func get_current_production_text(id: String) -> String:
	var def: Dictionary = ITEMS[id]
	var value_label: String = String(def.get("value_label", ""))
	var value: float = get_item_current_value(id)
	return "%d %s" % [int(round(value)), value_label]

func get_item_current_value(id: String) -> float:
	var def: Dictionary = ITEMS[id]
	var kind: String = String(def.get("kind", ""))
	var base_value: float = float(def.get("base_value", 1.0))
	var level: int = get_level(id)

	match kind:
		"passive":
			return float(level) * base_value
		"click":
			if level <= 0:
				return 1.0
			return pow(base_value, level)
		_:
			return 0.0

func get_current_dps_contribution(id: String) -> float:
	var total_dps: float = get_total_passive_dps()
	if total_dps <= 0.0:
		return 0.0

	var def: Dictionary = ITEMS[id]
	if String(def.get("kind", "")) != "passive":
		return 0.0

	return (get_item_current_value(id) / total_dps) * 100.0

func get_lifetime_generated_text(id: String) -> String:
	var amount := float(lifetime_generated.get(id, 0.0))
	return "%s doblones" % format_with_separator(int(amount))

# ENCICLOPEDIA
func _actualizar_peces_desbloqueados_en_enciclopedia() -> void:
	var ids_desbloqueados: Array[int] = []

	for item_id in ENCYCLOPEDIA_FISH_IDS.keys():
		if bool(unlocked.get(item_id, false)):
			ids_desbloqueados.append(int(ENCYCLOPEDIA_FISH_IDS[item_id]))

	if encyclopedia_panel.has_method("set_pez_ids_desbloqueados"):
		encyclopedia_panel.set_pez_ids_desbloqueados(ids_desbloqueados)

func try_add_fish_to_aquarium(habitat_id: String, fish_id: String) -> bool:
	if not aquarium_data.has(habitat_id):
		return false

	var slots: Array = aquarium_data[habitat_id]

	for i in range(slots.size()):
		if slots[i] == null:
			slots[i] = fish_id
			aquarium_data[habitat_id] = slots
			return true

	return false
func _on_move_fish_to_inventory(fish_id: String, slot_index: int, habitat_id: String) -> void:
	print("MAIN move to inventory:", fish_id, slot_index, habitat_id)

	if not aquarium_data.has(habitat_id):
		return

	var slots: Array = aquarium_data[habitat_id]

	if slot_index < 0 or slot_index >= slots.size():
		return

	if slots[slot_index] != fish_id:
		return

	slots[slot_index] = null
	aquarium_data[habitat_id] = slots

	fish_inventory[fish_id] = int(fish_inventory.get(fish_id, 0)) + 1

	refresh_inventory_panel_data()


func _on_move_fish_to_aquarium(fish_id: String, habitat_id: String) -> void:
	print("MAIN move to aquarium:", fish_id, habitat_id)

	if int(fish_inventory.get(fish_id, 0)) <= 0:
		return

	var added := try_add_fish_to_aquarium(habitat_id, fish_id)
	if not added:
		return

	fish_inventory[fish_id] = int(fish_inventory.get(fish_id, 0)) - 1

	refresh_inventory_panel_data()

func refresh_inventory_panel_data() -> void:
	if inventory_panel.visible:
		inventory_panel.set_inventory_data(
			HABITATS,
			unlocked_habitats,
			current_habitat,
			aquarium_data,
			fish_defs,
			fish_inventory
		)
