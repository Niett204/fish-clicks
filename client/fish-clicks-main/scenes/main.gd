extends Node2D

@export var floating_text_scene: PackedScene
@export var fish_scene: PackedScene
@export var dps_per_fish: float = 1.0
@export var shop_item_card_scene: PackedScene

@onready var coins_label: Label = $UI/Root/HUD/LeftInfoPanel/VBoxContainer/HBoxContainer/DoblonesLabel
@onready var shop_panel: Control = $UI/Root/HUD/TiendaPanel
@onready var btn_shop_icon: TextureButton = $UI/Root/HUD/TopBar/RightGroup/BtnShop
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

const ITEMS := {
	"fish_basic": {
		"tab": "Peces",
		"title": "Pez Común",
		"right": "DPS +1",
		"icon": "res://assets/peces/doblon.png",
		"unlock_price": 0,
	},
	
	"cofre": {
		"tab": "Estructuras",
		"title": "Cofre",
		"right": "+1 Click",
		"icon": "res://assets/estructuras/cofre_cerrado.png",
		"unlock_price": 0,
	},
	"boat": {
		"tab": "Estructuras",
		"title": "Barco",
		"right": "DPS +5",
		"icon": "res://assets/estructuras/cofre1.png",
		"unlock_price": 300,
	},
		"boat1234": {
		"tab": "Estructuras",
		"title": "Barco",
		"right": "DPS +5",
		"icon": "res://assets/estructuras/cofre1.png",
		"unlock_price": 300,
	},	"boat123": {
		"tab": "Estructuras",
		"title": "Barco",
		"right": "DPS +5",
		"icon": "res://assets/estructuras/cofre1.png",
		"unlock_price": 300,
	},	"boat56": {
		"tab": "Estructuras",
		"title": "Barco",
		"right": "DPS +5",
		"icon": "res://assets/estructuras/cofre1.png",
		"unlock_price": 300,
	},	"boat5": {
		"tab": "Estructuras",
		"title": "Barco",
		"right": "DPS +5",
		"icon": "res://assets/estructuras/cofre1.png",
		"unlock_price": 300,
	},	"boat66": {
		"tab": "Estructuras",
		"title": "Barco",
		"right": "DPS +5",
		"icon": "res://assets/estructuras/cofre1.png",
		"unlock_price": 300,
	},	"boat6": {
		"tab": "Estructuras",
		"title": "Barco",
		"right": "DPS +5",
		"icon": "res://assets/estructuras/cofre1.png",
		"unlock_price": 300,
	}
	
}

const TEX_CHEST_CLOSED := preload("res://assets/estructuras/cofre_cerrado.png")
const TEX_CHEST_EMPTY  := preload("res://assets/estructuras/cofre_abierto_vacio.png")
const TEX_CHEST_MID    := preload("res://assets/estructuras/cofre_abierto_medio.png")
const TEX_CHEST_FULL   := preload("res://assets/estructuras/cofre_abierto_lleno.png")

var unlocked: Dictionary = {}  # id -> bool

var dps: float = 0.0
var coins: float = 0.0 
var click_power: int = 1
var fish_count: int = 0
var chest_base_scale: Vector2
var chest_level: int = 0
var boat_count: int = 0
var shop_open := false
var shop_tween: Tween
var shop_x_open: float
var shop_x_closed: float
var _block_info_hover := false
var hud_visible := true

func _ready() -> void:
	for k in ITEMS.keys():
		var id := String(k)
		unlocked[id] = false
	shop_panel.visible = false
	chest_base_scale = chest_sprite.scale

	btn_hide.pressed.connect(func():
		play_squish(btn_shop_icon)
		_toggle_hud()
	)
	
	btn_shop_icon.pressed.connect(func():
		play_squish(btn_shop_icon)
		toggle_shop()
	)

	tab_container.tab_changed.connect(_on_tab_changed)
	_update_chest_sprite_by_level()
	chest.clicked.connect(_on_chest_clicked)

	_update_cps()
	_update_ui()
	
	await get_tree().process_frame  # asegura tamaños correctos
	
	shop_x_open = shop_panel.position.x
	shop_x_closed = shop_x_open + shop_panel.size.x + 20  # 20px extra fuera
	
	shop_panel.position.x = shop_x_closed
	shop_panel.visible = true  # importante: visible para que pueda animarse
	shop_open = false

func _toggle_hud():
	hud_visible = !hud_visible
	hud.visible = hud_visible

func toggle_shop() -> void:
	shop_open = !shop_open

	if not shop_open and info_panel:
		info_panel.request_hide()

	shop_tween = create_tween()
	shop_tween.set_trans(Tween.TRANS_QUAD)
	shop_tween.set_ease(Tween.EASE_OUT)

	var target_x := shop_x_open if shop_open else shop_x_closed
	shop_tween.tween_property(shop_panel, "position:x", target_x, 0.25)

	if shop_open:
		_on_tab_changed(tab_container.current_tab)

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

	# icono
	var icon_tex: Texture2D = null
	var icon_path: String = String(def.get("icon", ""))
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon_tex = load(icon_path)

	var unlock_price: int = int(def.get("unlock_price", 0))

	card.setup(
		id,
		String(def.get("title", id)),
		"", # left dinámico
		String(def.get("right", "")),
		str(get_level(id)),
		icon_tex,
		get_price(id),
		unlock_price
	)

	card.extra_title = String(def.get("title", id))
	card.extra_desc  = "\"Mejora tu producción.\""

	var p := get_price(id)
	var right := String(def.get("right", ""))

	card.extra_b1 = "Efecto: %s" % right
	card.extra_b2 = "Precio actual: %d" % p

	# Si está bloqueado, enseña unlock; si no, algo útil
	var unlock_p := int(def.get("unlock_price", 0))
	if unlock_p > 0 and not bool(unlocked.get(id, false)):
		card.extra_b3 = "Desbloquear: %d doblones" % unlock_p
	else:
		card.extra_b3 = "Nivel actual: %d" % get_level(id)

	# Footer tipo “cookies clicked so far”
	card.extra_footer = "%s doblones acumulados" % format_with_separator(int(coins))

	card.set_unlocked(bool(unlocked.get(id, unlock_price == 0)))
	card.buy_pressed.connect(_on_buy_pressed)
	card.unlock_pressed.connect(_on_unlock_pressed)

func _on_chest_clicked() -> void:
	coins += click_power
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
	var parts := format_doblones_parts(coins)
	coins_label.text = parts.value
	unidades_label.text = parts.unit
	update_shop_cards()
	
func _on_toggle_tienda_button_pressed() -> void:
	toggle_shop()
		
func _update_cps() -> void:
	dps = fish_count * dps_per_fish
	_update_dps_ui()

func _update_dps_ui() -> void:
	var parts: Dictionary = format_doblones_parts(dps)
	dps_label.text = "+" + parts.value + " " + parts.unit.replace(" de doblones", "").replace(" doblones", "") + "/s"
	
func _process(delta: float) -> void:
	coins += dps * delta
	_update_ui()
	
func _play_click_animation() -> void:
	var tween = create_tween()
	tween.tween_property(chest_sprite, "scale", chest_base_scale * 1.08, 0.06)
	tween.tween_property(chest_sprite, "scale", chest_base_scale, 0.08)

func fish_price() -> int:
	return int(round(25 * pow(1.15, fish_count)))

func chest_upgrade_price() -> int:
	# click_power empieza en 1; la primera mejora cuesta 10
	return int(round(10 * pow(1.25, click_power - 1)))

func get_level(id: String) -> int:
	match id:
		"fish_basic":
			return fish_count
		"cofre":
			return chest_level
		"boat":
			return boat_count
		_:
			return 0

func get_price(id: String) -> int:
	match id:
		"fish_basic":
			return int(round(0 * pow(1.15, fish_count)))
		"cofre":
			return int(round(10 * pow(1.05, click_power - 1)))
		"boat":
			return int(round(200 * pow(1.20, boat_count)))
		_:
			return 999999

func apply_purchase(id: String) -> void:
	match id:
		"fish_basic":
			fish_count += 1
			var fish = fish_scene.instantiate()
			fish.swim_area = $SwimArea
			fish_layer.add_child(fish)
			fish.position = Vector2(randi_range(200, 1000), randi_range(300, 600))
			_update_cps()
		"cofre":
			chest_level += 1
			click_power = int(round(1 * pow(1.3, chest_level)))
			_update_chest_sprite_by_level()
		"boat":
			boat_count += 1
			dps += 5
			_update_dps_ui()
		_:
			pass
	
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
	_update_ui()

func _on_unlock_pressed(id: String) -> void:
	if bool(unlocked.get(id, false)):
		return

	var unlock_price: int = int(ITEMS[id].get("unlock_price", 0))
	if coins < unlock_price:
		return

	coins -= unlock_price
	unlocked[id] = true
	_update_ui()  # esto refresca cards

func update_shop_cards() -> void:
	for card in list_peces.get_children():
		_refresh_card(card)
	for card in list_estructuras.get_children():
		_refresh_card(card)

func _refresh_card(card) -> void:
	var id: String = String(card.item_id)
	card.set_unlocked(bool(unlocked.get(id, true)))

	var p: int = get_price(id)
	card.set_dynamic(
		p,
		"Precio: %d" % p,
		String(ITEMS[id]["right"]),
		str(get_level(id))
	)
	card.update_state(coins)

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

	# 🔹 Menos de 1 millón → número completo sin prefijo
	if abs_n < 1_000_000.0:
		var txt := format_with_separator(int(round(n)))
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
	var txt := ("%0." + str(decimals) + "f") % value
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
	var coin_tex: Texture2D = load("res://assets/doblon_tres_cuartos.png")
	var bubble_tex: Texture2D = load("res://assets/burbuja.png")

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
