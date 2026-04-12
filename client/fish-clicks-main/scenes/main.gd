extends Node2D

const ENCYCLOPEDIA_FISH_IDS := {
	"doblon": 1,
	"sobrasada": 2,
	"espuma": 3,
	"rufinus": 4,
}

@export var floating_text_scene: PackedScene
@export var fish_scene: PackedScene
@export var dps_per_fish: float = 1.0
@export var shop_item_card_scene: PackedScene

@onready var top_bar: Control = $UI/Root/HUD/TopBar
@onready var shop_panel: Control = $UI/Root/HUD/TiendaPanel
@onready var btn_shop_icon: TextureButton = $UI/Root/HUD/TopBar/RightGroup/BtnShop
@onready var encyclopedia_panel: Control = $UI/Root/HUD/EncyclopediaPanel
@onready var btn_encyclopedia_icon: TextureButton = $UI/Root/HUD/TopBar/RightGroup/BtnEncyclopedia
@onready var inventory_panel: Control = $UI/Root/HUD/Inventario
@onready var btn_inventory_icon: TextureButton = $UI/Root/HUD/TopBar/RightGroup/BtnInventory
@onready var options_panel: Control = $UI/Root/HUD/OptionsPannel
@onready var btn_options_icon: TextureButton = $UI/Root/HUD/TopBar/LeftGroup/BtnOptions
@onready var pecera_blocker: Control = $UI/Root/PeceraBlocker
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
@onready var ui_root: Control = $UI/Root
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

var hud_visible := true

var vallisneria_ground_y: float = 0.0
var anubia_ground_y: float = 0.0
var vallisneria_base_scale: Vector2
var anubia_base_scale: Vector2

const UiManagerScript = preload("res://scripts/main/ui_manager.gd")
var ui_manager: UiManager

const FishModeManagerScript = preload("res://scripts/main/fish_mode_manager.gd")
var fish_mode_manager: FishModeManager

const SaveManagerScript = preload("res://scripts/main/save_manager.gd")
var save_manager: SaveManager

const StatsManagerScript = preload("res://scripts/main/stats_manager.gd")
var stats_manager: StatsManager

const AchievementsManagerScript = preload("res://scripts/main/achievements_manager.gd")
var achievements_manager: AchievementsManager

func _ready() -> void:
	
	ui_manager = UiManagerScript.new()
	add_child(ui_manager)
	ui_manager.setup(self)
	
	fish_mode_manager = FishModeManagerScript.new()
	add_child(fish_mode_manager)
	fish_mode_manager.setup(self)
	
	save_manager = SaveManagerScript.new()
	add_child(save_manager)
	save_manager.setup(self)
	
	stats_manager = StatsManagerScript.new()
	add_child(stats_manager)
	stats_manager.setup(self)
	
	achievements_manager = AchievementsManagerScript.new()
	add_child(achievements_manager)
	achievements_manager.setup(self)

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
		ui_manager.play_squish(btn_hide)
		ui_manager._toggle_hud()
	)

	btn_shop_icon.pressed.connect(func():
		ui_manager.play_squish(btn_shop_icon)
		ui_manager.toggle_shop()
	)

	btn_encyclopedia_icon.pressed.connect(func():
		ui_manager.play_squish(btn_encyclopedia_icon)
		ui_manager.toggle_encyclopedia()
	)
	
	btn_profile_icon.pressed.connect(func():
		achievements_manager.register_profile_click()
		ui_manager.play_squish(btn_profile_icon)
		ui_manager.toggle_profile()
	)

	btn_inventory_icon.pressed.connect(func():
		ui_manager.play_squish(btn_inventory_icon)
		ui_manager.toggle_inventario()
	)

	btn_options_icon.pressed.connect(func():
		ui_manager.play_squish(btn_options_icon)
		ui_manager.toggle_options()
	)
	
	options_panel.modo_pecera_requested.connect(fish_mode_manager.toggle_fish_mode)
	
	btn_stats_icon.pressed.connect(func():
		ui_manager.play_squish(btn_stats_icon)
		ui_manager.toggle_stats_panel()
	)

	tab_container.tab_changed.connect(ui_manager._on_tab_changed)
	_update_chest_sprite_by_level()
	chest.clicked.connect(_on_chest_clicked)

	vallisneria_base_scale = vallisneria.scale
	anubia_base_scale = anubia.scale

	if vallisneria.texture:
		vallisneria_ground_y = vallisneria.position.y + (vallisneria.texture.get_height() * abs(vallisneria.scale.y) * 0.5)

	if anubia.texture:
		anubia_ground_y = anubia.position.y + (anubia.texture.get_height() * abs(anubia.scale.y) * 0.5)

	_update_cps()
	ui_manager._update_ui()
	_actualizar_peces_desbloqueados_en_enciclopedia()
	_update_algas_sprite_by_level()
	_update_anubia_sprite_by_level()
	_update_tronco_visibility_by_level()

	inventory_panel.move_fish_to_inventory.connect(_on_move_fish_to_inventory)
	inventory_panel.move_fish_to_aquarium.connect(_on_move_fish_to_aquarium)
	inventory_panel.move_fish_within_aquarium.connect(_on_move_fish_within_aquarium)
	inventory_panel.habitat_changed.connect(_on_inventory_habitat_changed)
	
	options_panel.volume_slider_spam_detected.connect(func():
		achievements_manager.register_volume_slider_spam()
	)
	
	inventory_panel.close_requested.connect(func():
		ui_manager.play_ui_sfx(SFX_ICON_CLOSE)
		inventory_panel.visible = false
	)
	
	encyclopedia_panel.close_requested.connect(func():
		ui_manager.play_ui_sfx(SFX_ICON_CLOSE)
		encyclopedia_panel.visible = false
	)
	
	stats_panel.close_requested.connect(func():
		ui_manager.play_ui_sfx(SFX_ICON_CLOSE)
		stats_panel.visible = false
	)

	options_panel.close_requested.connect(func():
		ui_manager.play_ui_sfx(SFX_ICON_CLOSE)
		options_panel.visible = false
	)
	
	profile_panel.close_requested.connect(func():
		ui_manager.play_ui_sfx(SFX_ICON_CLOSE)
		profile_panel._close()
	)
	
	if game_start_date_string == "":
		var dt := Time.get_datetime_dict_from_system()
		game_start_date_string = "%02d/%02d/%04d" % [dt.day, dt.month, dt.year]

	await get_tree().process_frame  # asegura tamaños correctos

	shop_x_open = shop_panel.position.x
	shop_x_closed = shop_x_open + shop_panel.size.x + 20

	shop_panel.position.x = shop_x_closed
	shop_panel.visible = true
	shop_open = false
	
	# Guardado
	# Guardado: Solo conectamos el éxito de carga
	GlobalData.load_success.connect(save_manager.apply_save_state)
	
	# Intentamos cargar la partida inicial
	GlobalData.load_game() 
	
	# Añadimos al grupo al final
	add_to_group("main")

@warning_ignore("unused_parameter")
func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	@warning_ignore("unused_variable")
	var i: int;

func _input(event: InputEvent) -> void:
	fish_mode_manager.handle_input(event)
		

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
	ui_manager.play_ui_sfx(SFX_COFRE_CLICK)
	coins += click_power
	total_coins_earned += click_power
	lifetime_generated["cofre"] += click_power

	ui_manager._update_ui()
	_play_click_animation()
	_spawn_floating_text()
	_mostrar_monedas_y_burbujas()

	achievements_manager.check_achievements()

	if stats_panel.visible:
		stats_manager.refresh_stats_values_only()

func _spawn_floating_text() -> void:
	var t: Label = floating_text_scene.instantiate()
	add_child(t)

	t.text = "+" + str(click_power)

	var mouse_pos = get_viewport().get_mouse_position()
	t.position = mouse_pos + Vector2(-5, -20)
	t.z_index = 1000
		
func _update_cps() -> void:
	dps = get_total_passive_dps()
	ui_manager._update_dps_ui()

func get_total_passive_dps() -> float:
	var total: float = 0.0

	for key in ITEMS.keys():
		var id := String(key)
		var def: Dictionary = ITEMS[id]
		if String(def.get("kind", "")) == "passive":
			total += get_item_current_value(id)

	return total

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

	ui_manager._update_currency_ui()

	achievements_manager.process_achievement_timer(delta)

	if stats_panel.visible:
		stats_manager.refresh_stats_values_only()

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
		
	ui_manager.play_ui_sfx(SFX_BUY_ITEM)
	
	coins -= price
	if String(ITEMS[id].get("tab", "")) == "Estructuras":
		achievements_manager.register_structure_spent(price)
	apply_purchase(id)

	if fish_defs.has(id):
		var spawned_fish_id := id

		if randf() < 0.01 and fish_defs.has(id + "_shiny"):
			spawned_fish_id = id + "_shiny"
			achievements_manager.register_shiny_obtained()
			ui_manager.play_ui_sfx(SFX_SHINY)

		var slot_index := try_add_fish_to_aquarium(current_habitat, spawned_fish_id)

		if slot_index != -1:
			_spawn_fish(spawned_fish_id, current_habitat, slot_index)
		else:
			fish_inventory[spawned_fish_id] = int(fish_inventory.get(spawned_fish_id, 0)) + 1

	refresh_inventory_panel_data()
	ui_manager._update_ui()
	achievements_manager.check_achievements()

	if stats_panel.visible:
		stats_manager.refresh_stats_values_only()

func _on_unlock_pressed(id: String) -> void:
	if bool(unlocked.get(id, false)):
		return

	var unlock_price: int = int(ITEMS[id].get("unlock_price", 0))
	if coins < unlock_price:
		return

	coins -= unlock_price
	if String(ITEMS[id].get("tab", "")) == "Estructuras" and id != "cofre":
		achievements_manager.register_structure_spent(unlock_price)
	unlocked[id] = true

	match id:
		"vallisneria":
			_update_algas_sprite_by_level()
		"tronco":
			_update_tronco_visibility_by_level()

	ui_manager._update_ui()
	_actualizar_peces_desbloqueados_en_enciclopedia()
	achievements_manager.check_achievements()

	if stats_panel.visible:
		stats_manager.refresh_stats_values_only()

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
					achievements_manager.register_fish_annoyed()

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
