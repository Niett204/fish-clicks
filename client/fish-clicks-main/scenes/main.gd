extends Node2D

const ENCYCLOPEDIA_FISH_IDS := {
	"doblon": 1,
	"sobrasada": 2,
	"rufinus": 3,
	"espuma": 4,
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
@onready var options_panel: Control = $UI/Root/HUD/OptionsPannel
@onready var btn_options_icon: TextureButton = $UI/Root/HUD/TopBar/LeftGroup/BtnOptions
@onready var btn_stats_icon: TextureButton = $UI/Root/HUD/TopBar/LeftGroup/BtnStats
@onready var coins_label: Label = $UI/Root/HUD/LeftInfoPanel/VBoxContainer/HBoxContainer/DoblonesLabel
@onready var left_info_panel: Control = $UI/Root/HUD/LeftInfoPanel
@onready var chest: Area2D = $Cofre
@onready var chest_sprite: Sprite2D = $Cofre/Sprite2D
@onready var fish_layer = $PecesLayer
@onready var dps_label: Label = $UI/Root/HUD/LeftInfoPanel/VBoxContainer2/DpsLabel
@onready var unidades_label: Label = $UI/Root/HUD/LeftInfoPanel/VBoxContainer/UnidadesLabel
@onready var tab_container: TabContainer = $UI/Root/HUD/TiendaPanel/TabContainer
@onready var list_peces: VBoxContainer = $UI/Root/HUD/TiendaPanel/TabContainer/Peces/ScrollContainer/ListPeces
@onready var list_estructuras: VBoxContainer = $UI/Root/HUD/TiendaPanel/TabContainer/Estructuras/ScrollContainer/ListEstructuras
@onready var info_panel: Control = $UI/Root/HUD/InfoExtraPanel
@onready var profile_panel: Control = $UI/Root/HUD/ProfilePanel
@onready var btn_profile_icon: TextureButton = $UI/Root/HUD/TopBar/LeftGroup/BtnProfile
@onready var hud: Control = $UI/Root/HUD
@onready var btn_hide: TextureButton = $UI/Root/BtnHideHUD
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var vallisneria: Sprite2D = $EstructurasLayer/Vallisneria
@onready var stats_panel: Control = $UI/Root/HUD/StatsPanel
@onready var anubia: Sprite2D = $EstructurasLayer/Anubia
@onready var tronco_1: Sprite2D = $EstructurasLayer/Tronco
@onready var tronco_2: Sprite2D = $EstructurasLayer/Tronco2
@onready var tronco_3: Sprite2D = $EstructurasLayer/Tronco3

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var ui_sfx_player: AudioStreamPlayer = $UiSfxPlayer

# Audios 
const SFX_ICON_OPEN := preload("res://assets/audio/UI/abrir_icono.wav")
const SFX_ICON_CLOSE := preload("res://assets/audio/UI/cerrar_icono.wav")
const SFX_COFRE_CLICK:= preload("res://assets/audio/UI/pulsar_cofre.wav")
const SFX_BUY_ITEM:= preload("res://assets/audio/UI/comprar.wav")
const SFX_SHINY:= preload("res://assets/audio/UI/shiny.wav")
const SFX_CAMBIAR_TAB:= preload("res://assets/audio/UI/cambiar_tab.wav")

############################################################################

const ITEMS := {
	"doblon": {
		"tab": "Peces",
		"title": "Doblon",
		"icon": "res://assets/peces/doblon.png",
		"unlock_price": 10,
		"kind": "passive",
		"base_price": 40.0,
		"price_growth": 1.28,
		"base_value": 1.0,
		"value_label": "DPS"
	},
	"sobrasada": {
		"tab": "Peces",
		"title": "Sobrasada",
		"icon": "res://assets/peces/sobrasada.png",
		"unlock_price": 250,
		"kind": "passive",
		"base_price": 220.0,
		"price_growth": 1.30,
		"base_value": 4.0,
		"value_label": "DPS"
	},
	"espuma": {
		"tab": "Peces",
		"title": "Espuma",
		"icon": "res://assets/peces/espuma.png",
		"unlock_price": 1200,
		"kind": "passive",
		"base_price": 900.0,
		"price_growth": 1.32,
		"base_value": 12.0,
		"value_label": "DPS"
	},
	"rufinus": {
		"tab": "Peces",
		"title": "Rufinus",
		"icon": "res://assets/peces/rufinus.png",
		"unlock_price": 5000,
		"kind": "passive",
		"base_price": 3500.0,
		"price_growth": 1.35,
		"base_value": 35.0,
		"value_label": "DPS"
	},

	"cofre": {
		"tab": "Estructuras",
		"title": "Cofre",
		"icon": "res://assets/estructuras/cofre_cerrado.png",
		"unlock_price": 0,
		"kind": "click",
		"base_price": 20.0,
		"price_growth": 1.10,
		"base_value": 0.75,
		"value_label": "clicks"
	},
	"vallisneria": {
		"tab": "Estructuras",
		"title": "Vallisneria",
		"icon": "res://assets/estructuras/vallisneria/vallisneria_mini.png",
		"unlock_price": 500,
		"kind": "passive",
		"base_price": 180.0,
		"price_growth": 1.14,
		"base_value": 6.0,
		"value_label": "DPS"
	},
	"tronco": {
		"tab": "Estructuras",
		"title": "Tronco",
		"icon": "res://assets/estructuras/tronco/tronco_mini.png",
		"unlock_price": 800,
		"kind": "passive",
		"base_price": 250.0,
		"price_growth": 1.15,
		"base_value": 8.0,
		"value_label": "DPS"
	},
	"anubia": {
		"tab": "Estructuras",
		"title": "Anubia",
		"icon": "res://assets/estructuras/anubia/anubia_mini.png",
		"unlock_price": 1200,
		"kind": "passive",
		"base_price": 400.0,
		"price_growth": 1.16,
		"base_value": 12.0,
		"value_label": "DPS"
	},
}

############################################################################

@warning_ignore("shadowed_global_identifier")
const AchievementDefs = preload("res://scripts/data/achievement_defs.gd")
const ACHIEVEMENT_DEFS = AchievementDefs.ACHIEVEMENT_DEFS
const ACHIEVEMENT_POPUP_SCENE := preload("res://scenes/achievement_popup.tscn")
var achievement_popup_queue: Array = []
var achievement_popup_active: Control = null

############################################################################
const HABITATS := {
	"habitat_1": {
		"name": "Acuario",
		"background": preload("res://assets/fondos/fondo1.png")
	},
	"habitat_2": {
		"name": "Vacío",
		"background": preload("res://assets/fondos/fondo2.png")
	}
}

var unlocked_habitats: Array[String] = ["habitat_1", "habitat_2"]
var current_habitat: String = "habitat_1"
var inventory_habitat: String = "habitat_1"
var achievements_unlocked: Dictionary = {}
var total_shinies_ever: int = 0
var _achievement_check_accum: float = 0.0
var total_structures_spent: float = 0.0
var alien_clicked_count: int = 0
var random_tick_unlocked: bool = false
var profile_clicks_count: int = 0
var volume_slider_spam_unlocked: bool = false
var annoyed_fish_count: int = 0

var aquarium_data := {
	"habitat_1": [null, null, null, null, null, null, null, null, null, null],
	"habitat_2": [null, null, null, null, null, null, null, null, null, null]
}

var fish_inventory := {}

var fish_defs := {
	"doblon": {
		"name": "Doblon",
		"icon": preload("res://assets/peces/doblon.png")
	},
	"doblon_shiny": {
		"name": "Doblon",
		"icon": preload("res://assets/peces/doblon_shiny.png")
	},

	"sobrasada": {
		"name": "Sobrasada",
		"icon": preload("res://assets/peces/sobrasada.png")
	},
	"sobrasada_shiny": {
		"name": "Sobrasada",
		"icon": preload("res://assets/peces/sobrasada_shiny.png")
	},

	"espuma": {
		"name": "Espuma",
		"icon": preload("res://assets/peces/espuma.png")
	},
	"espuma_shiny": {
		"name": "Espuma",
		"icon": preload("res://assets/peces/espuma_shiny.png")
	},
	
	"rufinus": {
		"name": "Rufinus",
		"icon": preload("res://assets/peces/rufinus.png")
	},
	"rufinus_shiny": {
		"name": "Rufinus",
		"icon": preload("res://assets/peces/rufinus_shiny.png")
	},
}

############################################################################

var lifetime_generated: Dictionary = {
	"doblon": 0.0,
	"sobrasada": 0.0,
	"espuma": 0.0,
	"rufinus": 0.0,
	"cofre": 0.0,
	"vallisneria": 0.0
}

const TEX_CHEST_CLOSED := preload("res://assets/estructuras/cofre_cerrado_arena.png")
const TEX_CHEST_EMPTY  := preload("res://assets/estructuras/cofre_abierto_vacio_arena.png")
const TEX_CHEST_MID    := preload("res://assets/estructuras/cofre_abierto_medio_arena.png")
const TEX_CHEST_FULL   := preload("res://assets/estructuras/cofre_abierto_lleno_arena.png")
const TEX_ALGAS_0 := preload("res://assets/estructuras/vallisneria/vallisneria_mini.png")
const TEX_ALGAS_1 := preload("res://assets/estructuras/vallisneria/vallisneria_small.png")
const TEX_ALGAS_2 := preload("res://assets/estructuras/vallisneria/vallisneria_medium.png")
const TEX_ALGAS_3 := preload("res://assets/estructuras/vallisneria/vallisneria_large.png")
const TEX_ANUBIA_0 := preload("res://assets/estructuras/anubia/anubia_mini.png")
const TEX_ANUBIA_1 := preload("res://assets/estructuras/anubia/anubia_small.png")
const TEX_ANUBIA_2 := preload("res://assets/estructuras/anubia/anubia_medium.png")
const TEX_ANUBIA_3 := preload("res://assets/estructuras/anubia/anubia_large.png")

const ICON_HIDE = preload("res://assets/ui/iconos/icono_hud_abierto.png")
const ICON_SHOW = preload("res://assets/ui/iconos/icono_hud_cerrado.png")

var unlocked: Dictionary = {}  # id -> bool
var levels: Dictionary = {}
var total_clicks: int = 0
var session_time_seconds: float = 0.0
var game_start_date_string: String = ""

var dps: float = 0.0
var coins: float = 10000000.0
var total_coins_earned: float = 0.0
var click_power: int = 1
var chest_base_scale: Vector2
var shop_open := false
var shop_tween: Tween
var shop_x_open: float
var shop_x_closed: float

var _block_info_hover := false
var hud_visible := true

var vallisneria_ground_y: float = 0.0
var anubia_ground_y: float = 0.0
var vallisneria_base_scale: Vector2
var anubia_base_scale: Vector2


func _ready() -> void:
	http_request.request_completed.connect(_on_request_completed)

	var url := "https://fish-clicks.onrender.com/api/test"
	http_request.request(url)

	# Cargar sonidos música y efectos
	music_player.stream = preload("res://assets/audio/fondo/fondo1.ogg")
	music_player.play()

	for k in ITEMS.keys():
		var id := String(k)
		levels[id] = 0
		unlocked[id] = int(ITEMS[id].get("unlock_price", 0)) == 0
		lifetime_generated[id] = 0.0

	shop_panel.visible = false
	encyclopedia_panel.visible = false
	profile_panel.visible = false
	chest_base_scale = chest_sprite.scale
	
	shop_panel.z_index = 1
	encyclopedia_panel.z_index = 20
	inventory_panel.z_index = 20
	stats_panel.z_index = 20

	btn_hide.pressed.connect(func():
		play_squish(btn_hide)
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
	
	btn_profile_icon.pressed.connect(func():
		profile_clicks_count += 1
		check_achievements()
		play_squish(btn_profile_icon)
		toggle_profile()
	)

	btn_inventory_icon.pressed.connect(func():
		play_squish(btn_inventory_icon)
		toggle_inventario()
	)

	btn_options_icon.pressed.connect(func():
		play_squish(btn_options_icon)
		toggle_options()
	)
	
	btn_stats_icon.pressed.connect(func():
		play_squish(btn_stats_icon)
		toggle_stats_panel()
	)

	tab_container.tab_changed.connect(_on_tab_changed)
	_update_chest_sprite_by_level()
	chest.clicked.connect(_on_chest_clicked)

	vallisneria_base_scale = vallisneria.scale
	anubia_base_scale = anubia.scale

	if vallisneria.texture:
		vallisneria_ground_y = vallisneria.position.y + (vallisneria.texture.get_height() * abs(vallisneria.scale.y) * 0.5)

	if anubia.texture:
		anubia_ground_y = anubia.position.y + (anubia.texture.get_height() * abs(anubia.scale.y) * 0.5)

	_update_cps()
	_update_ui()
	_actualizar_peces_desbloqueados_en_enciclopedia()
	_update_algas_sprite_by_level()
	_update_anubia_sprite_by_level()
	_update_tronco_visibility_by_level()

	inventory_panel.move_fish_to_inventory.connect(_on_move_fish_to_inventory)
	inventory_panel.move_fish_to_aquarium.connect(_on_move_fish_to_aquarium)
	inventory_panel.move_fish_within_aquarium.connect(_on_move_fish_within_aquarium)
	inventory_panel.habitat_changed.connect(_on_inventory_habitat_changed)
	
	options_panel.volume_slider_spam_detected.connect(func():
		if not volume_slider_spam_unlocked:
			volume_slider_spam_unlocked = true
			check_achievements()
	)
	
	inventory_panel.close_requested.connect(func():
		play_ui_sfx(SFX_ICON_CLOSE)
		inventory_panel.visible = false
	)
	
	encyclopedia_panel.close_requested.connect(func():
		play_ui_sfx(SFX_ICON_CLOSE)
		encyclopedia_panel.visible = false
	)
	
	stats_panel.close_requested.connect(func():
		play_ui_sfx(SFX_ICON_CLOSE)
		stats_panel.visible = false
	)

	options_panel.close_requested.connect(func():
		play_ui_sfx(SFX_ICON_CLOSE)
		options_panel.visible = false
	)
	
	profile_panel.close_requested.connect(func():
		play_ui_sfx(SFX_ICON_CLOSE)
		profile_panel._close()
	)
	
	if game_start_date_string == "":
		var dt := Time.get_datetime_dict_from_system()
		game_start_date_string = "%02d/%02d/%04d" % [dt.day, dt.month, dt.year]

	for achievement_id in ACHIEVEMENT_DEFS.keys():
		achievements_unlocked[achievement_id] = false

	await get_tree().process_frame  # asegura tamaños correctos

	shop_x_open = shop_panel.position.x
	shop_x_closed = shop_x_open + shop_panel.size.x + 20

	shop_panel.position.x = shop_x_closed
	shop_panel.visible = true
	shop_open = false
	
	# Guardado
	GlobalData.load_success.connect(apply_save_state)
	GlobalData.load_game()  # intenta cargar al arrancar si hay sesión
	add_to_group("main")

# Función para reproducir el sonido
func play_ui_sfx(stream: AudioStream) -> void:
	if stream == null:
		return

	ui_sfx_player.stream = stream
	ui_sfx_player.stop()
	ui_sfx_player.play()
	
func _close_overlay_panels(except_panel: Control = null) -> void:
	if encyclopedia_panel != except_panel:
		encyclopedia_panel.visible = false

	if inventory_panel != except_panel:
		inventory_panel.visible = false
		
	if profile_panel != except_panel:
		profile_panel.visible = false

	if stats_panel != except_panel:
		stats_panel.visible = false

@warning_ignore("unused_parameter")
func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	@warning_ignore("unused_variable")
	var i: int;

func _toggle_hud():
	hud_visible = !hud_visible
	hud.visible = hud_visible
	
	if hud.visible:
		btn_hide.texture_normal = ICON_HIDE
	else:
		btn_hide.texture_normal = ICON_SHOW

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
		play_ui_sfx(SFX_ICON_OPEN)
		_refresh_current_shop_tab(tab_container.current_tab)
	else:
		play_ui_sfx(SFX_ICON_CLOSE)

func toggle_encyclopedia() -> void:
	var will_open := not encyclopedia_panel.visible

	if will_open:
		_close_overlay_panels(encyclopedia_panel)
		play_ui_sfx(SFX_ICON_OPEN)
		encyclopedia_panel.visible = true
		_actualizar_peces_desbloqueados_en_enciclopedia()

		if info_panel:
			info_panel.request_hide()
	else:
		encyclopedia_panel.visible = false
		play_ui_sfx(SFX_ICON_CLOSE)

func toggle_inventario() -> void:
	var will_open := not inventory_panel.visible

	if will_open:
		_close_overlay_panels(inventory_panel)
		play_ui_sfx(SFX_ICON_OPEN)
		inventory_panel.visible = true

		if info_panel:
			info_panel.request_hide()

		inventory_panel.set_inventory_data(
			HABITATS,
			unlocked_habitats,
			inventory_habitat,
			aquarium_data,
			fish_defs,
			fish_inventory
		)
	else:
		inventory_panel.visible = false
		play_ui_sfx(SFX_ICON_CLOSE)	

func toggle_options() -> void:
	options_panel.visible = !options_panel.visible

	if options_panel.visible:
		play_ui_sfx(SFX_ICON_OPEN)
		shop_open = false
		if info_panel:
			info_panel.request_hide()
		if shop_tween:
			shop_tween.kill()
		shop_panel.position.x = shop_x_closed
	else:
		play_ui_sfx(SFX_ICON_CLOSE)

func toggle_stats_panel() -> void:
	var will_open := not stats_panel.visible

	if will_open:
		_close_overlay_panels(stats_panel)
		play_ui_sfx(SFX_ICON_OPEN)
		stats_panel.visible = true

		if info_panel:
			info_panel.request_hide()

		_refresh_stats_panel_full()
	else:
		stats_panel.visible = false
		play_ui_sfx(SFX_ICON_CLOSE)

func toggle_profile() -> void:
	var will_open := not profile_panel.visible

	if will_open:
		_close_overlay_panels(profile_panel)
		play_ui_sfx(SFX_ICON_OPEN)
		profile_panel._open()

		if info_panel:
			info_panel.request_hide()
	else:
		play_ui_sfx(SFX_ICON_CLOSE)
		profile_panel._close()
		
func _refresh_stats_panel() -> void:
	if stats_panel.has_method("set_stats_data"):
		stats_panel.set_stats_data({
			"total_clicks": total_clicks,
			"total_fish": get_total_fish_count(),
			"total_structures": get_total_unlocked_structures_count(),
			"total_doblones": get_compact_doblones_text(total_coins_earned),
			"total_special_fish": get_total_shiny_fish_count(),
			"play_time": format_play_time(int(session_time_seconds)),
			"start_date": game_start_date_string,
			"dps": get_compact_doblones_text(dps) + " d/s",
			"dpc": get_compact_doblones_text(click_power) + " d/c"
		})

	if stats_panel.has_method("set_achievements_progress"):
		stats_panel.set_achievements_progress(
			get_unlocked_achievements_count(),
			get_total_achievements_count()
		)

	if stats_panel.has_method("set_achievements_data"):
		stats_panel.set_achievements_data(get_achievements_ui_data())

func _refresh_current_shop_tab(tab: int) -> void:
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

func _on_tab_changed(tab: int) -> void:
	play_ui_sfx(SFX_CAMBIAR_TAB)
	_refresh_current_shop_tab(tab)

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

	card.set_unlocked(bool(unlocked.get(id, unlock_price == 0)))
	card.update_state(coins) # <- importante
	card.buy_pressed.connect(_on_buy_pressed)
	card.unlock_pressed.connect(_on_unlock_pressed)

func _on_chest_clicked() -> void:
	total_clicks += 1
	play_ui_sfx(SFX_COFRE_CLICK)
	coins += click_power
	total_coins_earned += click_power
	lifetime_generated["cofre"] += click_power

	_update_ui()
	_play_click_animation()
	_spawn_floating_text()
	_mostrar_monedas_y_burbujas()

	check_achievements()

	if stats_panel.visible:
		_refresh_stats_values_only()

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
	session_time_seconds += delta

	var total_generated: float = get_total_passive_dps() * delta
	coins += total_generated
	total_coins_earned += total_generated

	for id in ITEMS.keys():
		var item_id := String(id)
		var def: Dictionary = ITEMS[item_id]

		if String(def.get("kind", "")) == "passive":
			lifetime_generated[item_id] += get_item_current_value(item_id) * delta

	_update_currency_ui()

	_achievement_check_accum += delta
	if _achievement_check_accum >= 0.5:
		_achievement_check_accum = 0.0
		if not random_tick_unlocked and randf() < 0.0001:
			random_tick_unlocked = true

		check_achievements()

	if stats_panel.visible:
		_refresh_stats_values_only()

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
		"cofre":
			click_power = int(round(get_item_current_value("cofre")))
			_update_chest_sprite_by_level()
		"vallisneria":
			_update_algas_sprite_by_level()
		"tronco":
			_update_tronco_visibility_by_level()
		"anubia":
			_update_anubia_sprite_by_level()
			
	_update_cps()

func _spawn_fish(fish_id: String, habitat_id: String, slot_index: int) -> void:
	var fish = fish_scene.instantiate()

	if "swim_area" in fish:
		fish.swim_area = $SwimArea
	else:
		push_error("El pez no tiene propiedad swim_area")

	fish_layer.add_child(fish)

	if fish.has_method("setup_fish_instance"):
		fish.setup_fish_instance(fish_id, habitat_id, slot_index)

	fish.visible = habitat_id == current_habitat

	if fish_defs.has(fish_id) and fish.has_method("set_fish_texture"):
		var tex: Texture2D = fish_defs[fish_id]["icon"]
		fish.set_fish_texture(tex)

	var target_pos := Vector2(
		randi_range(120, 920),
		randi_range(120, 520)
	)

	if fish.has_method("play_spawn_arc"):
		fish.play_spawn_arc(target_pos)
	else:
		fish.position = target_pos

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
		
	play_ui_sfx(SFX_BUY_ITEM)
	
	coins -= price
	if String(ITEMS[id].get("tab", "")) == "Estructuras":
		total_structures_spent += price
	apply_purchase(id)

	if fish_defs.has(id):
		var spawned_fish_id := id

		if randf() < 0.01 and fish_defs.has(id + "_shiny"):
			spawned_fish_id = id + "_shiny"
			total_shinies_ever += 1
			play_ui_sfx(SFX_SHINY)

		var slot_index := try_add_fish_to_aquarium(current_habitat, spawned_fish_id)

		if slot_index != -1:
			_spawn_fish(spawned_fish_id, current_habitat, slot_index)
		else:
			fish_inventory[spawned_fish_id] = int(fish_inventory.get(spawned_fish_id, 0)) + 1

	refresh_inventory_panel_data()
	_update_ui()
	check_achievements()

	if stats_panel.visible:
		_refresh_stats_values_only()

func _on_unlock_pressed(id: String) -> void:
	if bool(unlocked.get(id, false)):
		return

	var unlock_price: int = int(ITEMS[id].get("unlock_price", 0))
	if coins < unlock_price:
		return

	coins -= unlock_price
	if String(ITEMS[id].get("tab", "")) == "Estructuras" and id != "cofre":
		total_structures_spent += unlock_price
	unlocked[id] = true

	match id:
		"vallisneria":
			_update_algas_sprite_by_level()
		"tronco":
			_update_tronco_visibility_by_level()

	_update_ui()
	_actualizar_peces_desbloqueados_en_enciclopedia()
	check_achievements()

	if stats_panel.visible:
		_refresh_stats_values_only()

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
		"%d" % p,
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
					annoyed_fish_count += 1

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
			return 1.0 + level * base_value
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

func try_add_fish_to_aquarium(habitat_id: String, fish_id: String) -> int:
	if not aquarium_data.has(habitat_id):
		return -1

	var slots: Array = aquarium_data[habitat_id]

	for i in range(slots.size()):
		if slots[i] == null:
			slots[i] = fish_id
			aquarium_data[habitat_id] = slots
			return i

	return -1

func _on_move_fish_to_inventory(fish_id: String, slot_index: int, habitat_id: String) -> void:
	if not aquarium_data.has(habitat_id):
		return

	var slots: Array = aquarium_data[habitat_id]

	if slot_index < 0 or slot_index >= slots.size():
		return

	if slots[slot_index] != fish_id:
		return

	slots[slot_index] = null
	aquarium_data[habitat_id] = slots

	_remove_spawned_fish_from_aquarium(habitat_id, slot_index)

	fish_inventory[fish_id] = int(fish_inventory.get(fish_id, 0)) + 1

	refresh_inventory_panel_data()

func _on_move_fish_to_aquarium(fish_id: String, habitat_id: String, slot_index: int) -> void:
	if int(fish_inventory.get(fish_id, 0)) <= 0:
		return

	if not aquarium_data.has(habitat_id):
		return

	var slots: Array = aquarium_data[habitat_id]

	if slot_index < 0 or slot_index >= slots.size():
		return

	var replaced_fish_id = slots[slot_index]

	# Si había un pez en ese slot, vuelve al inventario
	if replaced_fish_id != null:
		fish_inventory[replaced_fish_id] = int(fish_inventory.get(replaced_fish_id, 0)) + 1
		_remove_spawned_fish_from_aquarium(habitat_id, slot_index)

	# Colocar el nuevo pez en el slot elegido
	slots[slot_index] = fish_id
	aquarium_data[habitat_id] = slots

	fish_inventory[fish_id] = int(fish_inventory.get(fish_id, 0)) - 1
	if int(fish_inventory[fish_id]) <= 0:
		fish_inventory.erase(fish_id)

	_spawn_fish(fish_id, habitat_id, slot_index)
	_refresh_visible_fish_by_habitat()
	refresh_inventory_panel_data()

func _on_move_fish_within_aquarium(from_slot_index: int, to_slot_index: int, habitat_id: String) -> void:
	if not aquarium_data.has(habitat_id):
		return

	var slots: Array = aquarium_data[habitat_id]

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

	# Intercambio lógico
	slots[from_slot_index] = to_fish_id
	slots[to_slot_index] = from_fish_id
	aquarium_data[habitat_id] = slots

	_swap_spawned_fish_slots(habitat_id, from_slot_index, to_slot_index)

	refresh_inventory_panel_data()

func _refresh_visible_fish_by_habitat() -> void:
	for child in fish_layer.get_children():
		child.visible = child.get("habitat_id") == current_habitat

func _on_inventory_habitat_changed(habitat_id: String) -> void:
	inventory_habitat = habitat_id

func _swap_spawned_fish_slots(habitat_id: String, from_slot_index: int, to_slot_index: int) -> void:
	var fish_from = null
	var fish_to = null

	for child in fish_layer.get_children():
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

func _move_spawned_fish_to_aquarium_slot(habitat_id: String, from_slot_index: int, to_slot_index: int) -> void:
	for child in fish_layer.get_children():
		if child.get("habitat_id") == habitat_id and child.get("slot_index") == from_slot_index:
			child.slot_index = to_slot_index
			return

func refresh_inventory_panel_data() -> void:
	if inventory_panel.visible:
		inventory_panel.set_inventory_data(
			HABITATS,
			unlocked_habitats,
			inventory_habitat,
			aquarium_data,
			fish_defs,
			fish_inventory
		)

func _remove_spawned_fish_from_aquarium(habitat_id: String, slot_index: int) -> void:
	for child in fish_layer.get_children():
		if child.get("habitat_id") == habitat_id and child.get("slot_index") == slot_index:
			child.queue_free()
			return

func _update_algas_sprite_by_level() -> void:
	var algas_level: int = get_level("vallisneria")
	var algas_unlocked: bool = bool(unlocked.get("vallisneria", false))

	if not algas_unlocked or algas_level <= 0:
		vallisneria.visible = false
		return

	vallisneria.visible = true

	if algas_level <= 5:
		_set_vallisneria_texture(TEX_ALGAS_0)
	elif algas_level <= 10:
		_set_vallisneria_texture(TEX_ALGAS_1)
	elif algas_level <= 15:
		_set_vallisneria_texture(TEX_ALGAS_2)
	else:
		_set_vallisneria_texture(TEX_ALGAS_3)

func _update_anubia_sprite_by_level() -> void:
	var level: int = get_level("anubia")

	if not bool(unlocked.get("anubia", false)) or level <= 0:
		anubia.visible = false
		return

	anubia.visible = true

	if level <= 5:
		_set_anubia_texture(TEX_ANUBIA_0, 2.0, 0.75)
	elif level <= 10:
		_set_anubia_texture(TEX_ANUBIA_1, 6.0, 0.45)
	elif level <= 15:
		_set_anubia_texture(TEX_ANUBIA_2, 2.0, 0.80)
	else:
		_set_anubia_texture(TEX_ANUBIA_3, 0.0, 1.00)

func _set_anubia_texture(tex: Texture2D, extra_y: float = 0.0, scale_mult: float = 1.0) -> void:
	if tex == null:
		return

	anubia.texture = tex
	anubia.scale = anubia_base_scale * scale_mult

	var tex_height: float = tex.get_height() * abs(anubia.scale.y)

	if anubia.centered:
		anubia.position.y = anubia_ground_y - tex_height * 0.5 + extra_y
	else:
		anubia.position.y = anubia_ground_y - tex_height + extra_y

func _set_vallisneria_texture(tex: Texture2D) -> void:
	if tex == null:
		return

	vallisneria.texture = tex
	vallisneria.scale = vallisneria_base_scale

	var tex_height: float = tex.get_height() * abs(vallisneria.scale.y)

	if vallisneria.centered:
		vallisneria.position.y = vallisneria_ground_y - tex_height * 0.5
	else:
		vallisneria.position.y = vallisneria_ground_y - tex_height

func get_total_fish_count() -> int:
	var total := 0

	for habitat_id in aquarium_data.keys():
		for fish_id in aquarium_data[habitat_id]:
			if fish_id != null:
				total += 1

	for fish_id in fish_inventory.keys():
		total += int(fish_inventory[fish_id])

	return total

func get_total_structures_count() -> int:
	var total := 0

	for id in ITEMS.keys():
		var item_id := String(id)

		if String(ITEMS[item_id].get("tab", "")) != "Estructuras":
			continue

		if item_id == "cofre":
			continue

		total += get_level(item_id)

	return total

func get_total_special_fish_count() -> int:
	var total := 0

	for habitat_id in aquarium_data.keys():
		for fish_id in aquarium_data[habitat_id]:
			if fish_id != null and String(fish_id).ends_with("_shiny"):
				total += 1

	for fish_id in fish_inventory.keys():
		if String(fish_id).ends_with("_shiny"):
			total += int(fish_inventory[fish_id])

	return total

func get_compact_doblones_text(value: float) -> String:
	var parts: Dictionary = format_doblones_parts(value)
	var unit := String(parts.unit)

	unit = unit.replace(" de doblones", "")
	unit = unit.replace(" doblones", "")

	return parts.value if unit == "" else parts.value + " " + unit

func format_play_time(total_seconds: int) -> String:
	@warning_ignore("integer_division")
	var hours := total_seconds / 3600
	@warning_ignore("integer_division")
	var minutes := (total_seconds % 3600) / 60
	var seconds := total_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func get_total_unlocked_structures_count() -> int:
	var total := 0

	for id in ITEMS.keys():
		var item_id := String(id)
		var def: Dictionary = ITEMS[item_id]

		if String(def.get("tab", "")) != "Estructuras":
			continue

		if item_id == "cofre":
			continue

		if bool(unlocked.get(item_id, false)):
			total += 1

	return total

func get_total_shiny_fish_count() -> int:
	var total := 0

	for habitat_id in aquarium_data.keys():
		var slots = aquarium_data[habitat_id]
		for fish_id in slots:
			if fish_id != null and String(fish_id).ends_with("_shiny"):
				total += 1

	for fish_id in fish_inventory.keys():
		if String(fish_id).ends_with("_shiny"):
			total += int(fish_inventory[fish_id])

	return total
	
func _get_achievement_current_value(kind: String) -> float:
	match kind:
		"clicks":
			return float(total_clicks)
		"coins":
			return total_coins_earned
		"fish":
			return float(get_total_fish_count())
		"structures":
			return float(get_total_unlocked_structures_count())
		"structures_spent":
			return total_structures_spent
		"shiny_current":
			return float(get_total_shiny_fish_count())
		"shiny_ever":
			return float(total_shinies_ever)
		"play_time":
			return session_time_seconds
		"dps":
			return dps
		"dpc":
			return float(click_power)
		"all_aquarium_shiny":
			return 1.0 if _is_all_current_aquarium_shiny() else 0.0
		"all_species_in_aquarium":
			return 1.0 if _has_all_species_in_current_aquarium() else 0.0
		"alien_clicked":
			return float(alien_clicked_count)
		"random_tick":
			return 1.0 if random_tick_unlocked else 0.0
		"encyclopedia_complete":
			return 1.0 if _is_encyclopedia_complete() else 0.0
		"profile_clicks":
			return float(profile_clicks_count)
		"volume_slider_spam":
			return 1.0 if volume_slider_spam_unlocked else 0.0
		"same_species_full_aquarium":
			return 1.0 if _is_same_species_full_aquarium() else 0.0
		"annoy_fish":
			return float(annoyed_fish_count)
		"achievements_unlocked":
			return float(get_unlocked_achievements_count())
		_:
			return 0.0

func check_achievements() -> void:
	var changed := false

	for achievement_id in ACHIEVEMENT_DEFS.keys():
		if bool(achievements_unlocked.get(achievement_id, false)):
			continue

		var def: Dictionary = ACHIEVEMENT_DEFS[achievement_id]
		var kind := String(def.get("kind", ""))
		var target := float(def.get("target", 0.0))
		var current := _get_achievement_current_value(kind)

		if current >= target:
			achievements_unlocked[achievement_id] = true
			changed = true

			var title := String(def.get("title", achievement_id))
			var condition := String(def.get("condition", ""))
			var icon_data = def.get("icon", null)
			var icon_tex: Texture2D = null

			if icon_data is Texture2D:
				icon_tex = icon_data
			elif icon_data is String and icon_data != "":
				icon_tex = load(icon_data)

			_show_achievement_popup(title, condition, icon_tex)

	if changed and stats_panel.visible:
		_refresh_stats_panel_full()

func get_achievements_ui_data() -> Array:
	var result: Array = []

	for achievement_id in ACHIEVEMENT_DEFS.keys():
		var def: Dictionary = ACHIEVEMENT_DEFS[achievement_id]
		result.append({
			"id": achievement_id,
			"title": String(def.get("title", "")),
			"condition": _get_achievement_condition_text(def),
			"desc": String(def.get("desc", "")),
			"icon": def.get("icon", null),
			"unlocked": bool(achievements_unlocked.get(achievement_id, false)),
			"hidden": bool(def.get("hidden", false))
		})

	return result

func get_unlocked_achievements_count() -> int:
	var total := 0
	for achievement_id in achievements_unlocked.keys():
		if bool(achievements_unlocked[achievement_id]):
			total += 1
	return total

func get_total_achievements_count() -> int:
	return ACHIEVEMENT_DEFS.size()

func _refresh_stats_values_only() -> void:
	if stats_panel.has_method("set_stats_data"):
		stats_panel.set_stats_data({
			"total_clicks": total_clicks,
			"total_fish": get_total_fish_count(),
			"total_structures": get_total_unlocked_structures_count(),
			"total_doblones": get_compact_doblones_text(total_coins_earned),
			"total_special_fish": get_total_shiny_fish_count(),
			"play_time": format_play_time(int(session_time_seconds)),
			"start_date": game_start_date_string,
			"dps": get_compact_doblones_text(dps) + " d/s",
			"dpc": get_compact_doblones_text(click_power) + " d/c"
		})

func _refresh_stats_panel_full() -> void:
	_refresh_stats_values_only()

	if stats_panel.has_method("set_achievements_progress"):
		stats_panel.set_achievements_progress(
			get_unlocked_achievements_count(),
			get_total_achievements_count()
		)

	if stats_panel.has_method("set_achievements_data"):
		stats_panel.set_achievements_data(get_achievements_ui_data())

func _get_achievement_condition_text(def: Dictionary) -> String:
	return "Desbloqueo: %s" % String(def.get("condition", "Desbloqueo especial"))

func _show_achievement_popup(title: String, condition: String, icon_tex: Texture2D = null) -> void:
	achievement_popup_queue.append({
		"title": title,
		"condition": condition,
		"icon": icon_tex
	})

	_try_show_next_achievement_popup()

func _try_show_next_achievement_popup() -> void:
	if achievement_popup_active != null:
		return

	if achievement_popup_queue.is_empty():
		return

	var data: Dictionary = achievement_popup_queue.pop_front()

	var popup = ACHIEVEMENT_POPUP_SCENE.instantiate()
	$UI/Root.add_child(popup)
	achievement_popup_active = popup

	if popup.has_method("setup_popup"):
		popup.setup_popup(
			String(data.get("title", "")),
			String(data.get("condition", "")),
			data.get("icon", null)
		)

	await get_tree().process_frame

	var screen_size: Vector2 = get_viewport_rect().size
	popup.position = Vector2(
		screen_size.x - popup.size.x - 675,
		10
	)

	if popup.has_signal("popup_finished"):
		popup.popup_finished.connect(_on_achievement_popup_finished)

	if popup.has_method("show_popup"):
		popup.show_popup()

func _on_achievement_popup_finished() -> void:
	achievement_popup_active = null
	_try_show_next_achievement_popup()

func _get_base_fish_id(fish_id: String) -> String:
	return fish_id.replace("_shiny", "")

func _get_current_aquarium_fish_ids() -> Array[String]:
	var result: Array[String] = []

	if not aquarium_data.has(current_habitat):
		return result

	for fish_id in aquarium_data[current_habitat]:
		if fish_id != null:
			result.append(String(fish_id))

	return result

func _is_current_aquarium_full() -> bool:
	if not aquarium_data.has(current_habitat):
		return false

	for fish_id in aquarium_data[current_habitat]:
		if fish_id == null:
			return false

	return true

func _is_all_current_aquarium_shiny() -> bool:
	var fish_ids := _get_current_aquarium_fish_ids()

	if fish_ids.is_empty():
		return false

	if not _is_current_aquarium_full():
		return false

	for fish_id in fish_ids:
		if not fish_id.ends_with("_shiny"):
			return false

	return true

func _has_all_species_in_current_aquarium() -> bool:
	var required_species := {}
	for fish_id in ENCYCLOPEDIA_FISH_IDS.keys():
		required_species[String(fish_id)] = true

	var present_species := {}

	for fish_id in _get_current_aquarium_fish_ids():
		present_species[_get_base_fish_id(fish_id)] = true

	for species_id in required_species.keys():
		if not present_species.has(species_id):
			return false

	return true

func _is_same_species_full_aquarium() -> bool:
	var fish_ids := _get_current_aquarium_fish_ids()

	if fish_ids.is_empty():
		return false

	if not _is_current_aquarium_full():
		return false

	var first_species := _get_base_fish_id(fish_ids[0])

	for fish_id in fish_ids:
		if _get_base_fish_id(fish_id) != first_species:
			return false

	return true

func _is_encyclopedia_complete() -> bool:
	for fish_id in ENCYCLOPEDIA_FISH_IDS.keys():
		if not bool(unlocked.get(fish_id, false)):
			return false
	return true

func _update_tronco_visibility_by_level() -> void:
	var level: int = get_level("tronco")
	var is_unlocked: bool = bool(unlocked.get("tronco", false))

	tronco_1.visible = false
	tronco_2.visible = false
	tronco_3.visible = false

	if not is_unlocked or level <= 0:
		return

	if level <= 5:
		tronco_3.visible = true
	elif level <= 10:
		tronco_2.visible = true
	else:
		tronco_1.visible = true


# ── GUARDADO DE PARTIDA ─────────────────────────────────────────────────────
func get_save_state() -> Dictionary:
	# Serializa aquarium_data (los arrays tienen null o strings)
	var aquarium_serialized := {}
	for habitat_id in aquarium_data.keys():
		var slots := []
		for slot in aquarium_data[habitat_id]:
			slots.append(slot if slot != null else "")
		aquarium_serialized[habitat_id] = slots

	return {
		"coins": coins,
		"levels": levels,
		"unlocked": unlocked,
		"lifetime_generated": lifetime_generated,
		"achievements_unlocked": achievements_unlocked,
		"random_tick_unlocked": random_tick_unlocked,
		"volume_slider_spam_unlocked": volume_slider_spam_unlocked,
		"aquarium_data": aquarium_serialized,
		"current_habitat": current_habitat,
		"unlocked_habitats": unlocked_habitats,
	}


func apply_save_state(state: Dictionary) -> void:
	coins = float(state.get("coins", 0.0))

	var saved_levels: Dictionary = state.get("levels", {})
	for k in saved_levels:
		levels[k] = int(saved_levels[k])

	var saved_unlocked: Dictionary = state.get("unlocked", {})
	for k in saved_unlocked:
		unlocked[k] = bool(saved_unlocked[k])

	var saved_lifetime: Dictionary = state.get("lifetime_generated", {})
	for k in saved_lifetime:
		lifetime_generated[k] = float(saved_lifetime[k])

	var saved_achievements: Dictionary = state.get("achievements_unlocked", {})
	for k in saved_achievements:
		achievements_unlocked[k] = bool(saved_achievements[k])

	random_tick_unlocked = bool(state.get("random_tick_unlocked", false))
	volume_slider_spam_unlocked = bool(state.get("volume_slider_spam_unlocked", false))
	current_habitat = state.get("current_habitat", "habitat_1")

	var saved_habitats = state.get("unlocked_habitats", ["habitat_1"])
	unlocked_habitats.clear()
	for h in saved_habitats:
		unlocked_habitats.append(str(h))

	# Restaurar aquarium_data y spawnear peces
	var saved_aquarium: Dictionary = state.get("aquarium_data", {})
	# Limpiar peces actuales en pantalla
	for child in fish_layer.get_children():
		child.queue_free()
	# Resetear slots
	for habitat_id in aquarium_data.keys():
		var empty_slots = []
		empty_slots.resize(aquarium_data[habitat_id].size())
		empty_slots.fill(null)
		aquarium_data[habitat_id] = empty_slots

	# Restaurar slots y spawnear
	for habitat_id in saved_aquarium.keys():
		if not aquarium_data.has(habitat_id):
			continue
		var slots: Array = saved_aquarium[habitat_id]
		for slot_index in slots.size():
			var fish_id = slots[slot_index]
			if fish_id == null or fish_id == "":
				continue
			aquarium_data[habitat_id][slot_index] = fish_id
			_spawn_fish(fish_id, habitat_id, slot_index)

	_update_cps()
	_update_ui()
