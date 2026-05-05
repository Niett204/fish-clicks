extends Node2D
# ------------------- NODOS DE SERVICIO -------------------
@onready var http_request: HTTPRequest = $HTTPRequest

# ------------------- DATA -------------------
const ItemData = preload("res://scripts/data/item_data.gd")
const FishData = preload("res://scripts/data/fish_data.gd")
const HabitatData = preload("res://scripts/data/habitat_data.gd")
const EncyclopediaData = preload("res://scripts/data/encyclopedia_data.gd")

const ENCYCLOPEDIA_FISH_IDS = EncyclopediaData.ENCYCLOPEDIA_FISH_IDS
const ITEMS = ItemData.ITEMS
const HABITATS = HabitatData.HABITATS
var fish_defs = FishData.FISH_DEFS.duplicate(true)
const FISH_LOSS_DEBUFF_DURATION: float = 120.0

# ------------------- EXPORTED -------------------
@export var floating_text_scene: PackedScene
@export var fish_scene: PackedScene
@export var dps_per_fish: float = 1.0
@export var shop_item_card_scene: PackedScene

# ------------------- NODOS UI -------------------
@onready var pecera_blocker: Control = $UI/Root/PeceraBlocker
@onready var top_bar: Control = $UI/Root/HUD/TopBar
@onready var shop_panel: Control = $UI/Root/HUD/TiendaPanel
@onready var btn_shop_icon: TextureButton = $UI/Root/HUD/TopBar/RightGroup/BtnShop
@onready var encyclopedia_panel: Control = $UI/Root/HUD/EncyclopediaPanel
@onready var btn_encyclopedia_icon: TextureButton = $UI/Root/HUD/TopBar/RightGroup/BtnEncyclopedia
@onready var inventory_panel: Control = $UI/Root/HUD/Inventario
@onready var btn_inventory_icon: TextureButton = $UI/Root/HUD/TopBar/RightGroup/BtnInventory
@onready var options_panel: Control = $UI/Root/HUD/OptionsPannel
@onready var btn_options_icon: TextureButton = $UI/Root/HUD/TopBar/LeftGroup/BtnOptions
@onready var btn_stats_icon: TextureButton = $UI/Root/HUD/TopBar/LeftGroup/BtnStats
@onready var btn_profile_icon: TextureButton = $UI/Root/HUD/TopBar/LeftGroup/BtnProfile
@onready var btn_hide: TextureButton = $UI/Root/BtnHideHUD
@onready var marco_pecera: TextureRect = $UI/Root/MarcoPecera
@onready var cleaning_event_layer: Control = $UI/Root/CleaningEventLayer
@onready var hud: Control = $UI/Root/HUD
@onready var ui_root: Control = $UI/Root
@onready var info_panel: Control = $UI/Root/HUD/InfoExtraPanel
@onready var left_info_panel: Control = $UI/Root/HUD/LeftInfoPanel
@onready var profile_panel: Control = $UI/Root/HUD/ProfilePanel
@onready var stats_panel: Control = $UI/Root/HUD/StatsPanel
@onready var tab_container: TabContainer = $UI/Root/HUD/TiendaPanel/TabContainer
@onready var list_peces: VBoxContainer = $UI/Root/HUD/TiendaPanel/TabContainer/Peces/ScrollContainer/ListPeces
@onready var list_estructuras: VBoxContainer = $UI/Root/HUD/TiendaPanel/TabContainer/Estructuras/ScrollContainer/ListEstructuras
@onready var list_unicos: VBoxContainer = $UI/Root/HUD/TiendaPanel/TabContainer/Únicos/ScrollContainer/ListUnicos
@onready var coins_label: Label = $UI/Root/HUD/LeftInfoPanel/VBoxContainer/HBoxContainer/DoblonesLabel
@onready var dps_label: Label = $UI/Root/HUD/LeftInfoPanel/VBoxContainer2/DpsLabel
@onready var unidades_label: Label = $UI/Root/HUD/LeftInfoPanel/VBoxContainer/UnidadesLabel
@onready var btn_ranking_icon: TextureButton = $UI/Root/HUD/TopBar/LeftGroup/BtnRanking
@onready var ranking_panel: Control = $UI/Root/HUD/RankingPanel
@onready var fish_mode_overlay: Control = $UI/Root/FishModeOverlay
@onready var fish_mode_dark_bg: ColorRect = $UI/Root/FishModeOverlay/DarkBg
@onready var btn_expand_fish_mode: Control = $UI/Root/FishModeOverlay/BtnExpand
@onready var btn_world_icon: TextureButton = $UI/Root/HUD/TopBar/RightGroup/BtnWorld

# ------------------- NODOS DE MUNDO -------------------
@onready var content_pecera: Node2D = $ContentPecera
@onready var chest: Area2D = $ContentPecera/Cofre
@onready var chest_sprite: Sprite2D = $ContentPecera/Cofre/Sprite2D
@onready var fish_layer = $ContentPecera/PecesLayer
@onready var bg: Sprite2D = $ContentPecera/BG
@onready var swim_area: Node2D = $ContentPecera/SwimArea
@onready var swim_area_collision: CollisionShape2D = $ContentPecera/SwimArea/CollisionShape2D
# ------------------- ESTRUCTURAS MUNDO 1 -------------------
@onready var vallisneria: Sprite2D = $ContentPecera/EstructurasLayer/Vallisneria
@onready var anubia: Sprite2D = $ContentPecera/EstructurasLayer/Anubia
@onready var tronco_1: Sprite2D = $ContentPecera/EstructurasLayer/Tronco
@onready var tronco_2: Sprite2D = $ContentPecera/EstructurasLayer/Tronco2
@onready var tronco_3: Sprite2D = $ContentPecera/EstructurasLayer/Tronco3
# ------------------- ESTRUCTURAS MUNDO 2 -------------------
@onready var coral: Sprite2D = $ContentPecera/EstructurasLayer/Coral
@onready var piedra: Sprite2D = $ContentPecera/EstructurasLayer/Piedra
@onready var iceberg: Sprite2D = $ContentPecera/EstructurasLayer/Iceberg
@onready var barco: Sprite2D = $ContentPecera/EstructurasLayer/Barco

# ------------------- AUDIO -------------------
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var ui_sfx_player: AudioStreamPlayer = $UiSfxPlayer
@onready var achievement_sfx_player: AudioStreamPlayer = $AchievementSfxPlayer

const SFX_ICON_OPEN := preload("res://assets/audio/UI/abrir_icono.wav")
const SFX_ICON_CLOSE := preload("res://assets/audio/UI/cerrar_icono.wav")
const SFX_COFRE_CLICK := preload("res://assets/audio/UI/pulsar_cofre.wav")
const SFX_BUY_ITEM := preload("res://assets/audio/UI/comprar.wav")
const SFX_SHINY := preload("res://assets/audio/UI/shiny.wav")
const SFX_CAMBIAR_TAB := preload("res://assets/audio/UI/cambiar_tab.wav")
const SFX_PASA_PAGINA := preload("res://assets/audio/UI/pasa_pagina.wav")
const SFX_CAMBIAR_CATEGORIA := preload("res://assets/audio/UI/cambiar_tab.wav")
const SFX_ACHIEVEMENT := preload("res://assets/audio/UI/shiny.wav")
const SFX_BOTTLE := preload("res://assets/audio/UI/cambiar_tab.wav")

# ------------------- ASSETS VISUALES -------------------
const TEX_CHEST_CLOSED := preload("res://assets/estructuras/cofre_cerrado_arena.png")
const TEX_CHEST_EMPTY := preload("res://assets/estructuras/cofre_abierto_vacio_arena.png")
const TEX_CHEST_MID := preload("res://assets/estructuras/cofre_abierto_medio_arena.png")
const TEX_CHEST_FULL := preload("res://assets/estructuras/cofre_abierto_lleno_arena.png")
const TEX_CHEST2_CLOSED := preload("res://assets/estructuras/cofre_cerrado_antartida.png")
const TEX_CHEST2_EMPTY := preload("res://assets/estructuras/cofre_abierto_vacio_antartida.png")
const TEX_CHEST2_MID := preload("res://assets/estructuras/cofre_abierto_medio_antartida.png")
const TEX_CHEST2_FULL := preload("res://assets/estructuras/cofre_abierto_lleno_antartida.png")
const TEX_ALGAS_0 := preload("res://assets/estructuras/vallisneria/vallisneria_mini.png")
const TEX_ALGAS_1 := preload("res://assets/estructuras/vallisneria/vallisneria_small.png")
const TEX_ALGAS_2 := preload("res://assets/estructuras/vallisneria/vallisneria_medium.png")
const TEX_ALGAS_3 := preload("res://assets/estructuras/vallisneria/vallisneria_large.png")
const TEX_ANUBIA_0 := preload("res://assets/estructuras/anubia/anubia_mini.png")
const TEX_ANUBIA_1 := preload("res://assets/estructuras/anubia/anubia_small.png")
const TEX_ANUBIA_2 := preload("res://assets/estructuras/anubia/anubia_medium.png")
const TEX_ANUBIA_3 := preload("res://assets/estructuras/anubia/anubia_large.png")
const TEX_CORAL_0 := preload("res://assets/estructuras/coral/coral_small.png")
const TEX_CORAL_1 := preload("res://assets/estructuras/coral/coral_medium.png")
const TEX_CORAL_2 := preload("res://assets/estructuras/coral/coral_large.png")
const TEX_PIEDRA_0 := preload("res://assets/estructuras/piedra/piedra_small.png")
const TEX_PIEDRA_1 := preload("res://assets/estructuras/piedra/piedra_medium.png")
const TEX_PIEDRA_2 := preload("res://assets/estructuras/piedra/piedra_large.png")
const TEX_ICEBERG_0 := preload("res://assets/estructuras/iceberg/iceberg_small.png")
const TEX_ICEBERG_1 := preload("res://assets/estructuras/iceberg/iceberg_medium.png")
const TEX_ICEBERG_2 := preload("res://assets/estructuras/iceberg/iceberg_large.png")
const TEX_BARCO_0 := preload("res://assets/estructuras/barco/barco_small.png")
const TEX_BARCO_1 := preload("res://assets/estructuras/barco/barco_medium.png")
const TEX_BARCO_2 := preload("res://assets/estructuras/barco/barco_large.png")
const ICON_HIDE = preload("res://assets/ui/iconos/icono_hud_abierto.png")
const ICON_SHOW = preload("res://assets/ui/iconos/icono_hud_cerrado.png")

# ------------------- ESTADO DEL JUEGO -------------------
var aquarium_data := {
	"habitat_1": [null, null, null, null, null, null, null, null, null, null],
	"habitat_2": [null, null, null, null, null, null, null, null, null, null]
}
var fish_inventory := {}

var unlocked: Dictionary = {}
var levels: Dictionary = {}
var lifetime_generated: Dictionary = {
	"doblon": 0.0,
	"sobrasada": 0.0,
	"espuma": 0.0,
	"rufinus": 0.0,
	"cofre": 0.0,
	"vallisneria": 0.0
}

var total_clicks: int = 0
var session_time_seconds: float = 0.0
var game_start_date_string: String = ""
var dps: float = 0.0
var coins: float = 10000.0
var total_coins_earned: float = 0.0
var click_power: int = 1
var hud_visible := true
var shop_open := false
var shop_tween: Tween
var shop_x_open: float
var shop_x_closed: float
var fish_loss_debuff_active: bool = false
var fish_loss_debuff_time_left: float = 0.0
var alien_minigame_wins: int = 0
var alien_minigame_losses: int = 0

# ------------------- ESTADO VISUAL -------------------
var chest_base_scale: Vector2
var vallisneria_ground_y: float = 0.0
var anubia_ground_y: float = 0.0
var vallisneria_base_scale: Vector2
var anubia_base_scale: Vector2
var coral_ground_y: float = 0.0
var coral_base_scale: Vector2
var barco_base_scale: Vector2
var barco_base_position: Vector2
# --- para el modo pecera ---
var content_pecera_normal_position: Vector2
var content_pecera_normal_scale: Vector2
var swim_area_normal_position: Vector2
var swim_area_normal_size: Vector2

# ------------------- MANAGERS -------------------
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

const AquariumManagerScript = preload("res://scripts/main/aquarium_manager.gd")
var aquarium_manager: AquariumManager

const ShopManagerScript = preload("res://scripts/main/shop_manager.gd")
var shop_manager: ShopManager

const AlienManagerScript = preload("res://scripts/main/alien_manager.gd")
var alien_manager: AlienManager

const HabitatManagerScript = preload("res://scripts/main/habitat_manager.gd")
var habitat_manager: HabitatManager

const CleaningManagerScript = preload("res://scripts/main/cleaning_manager.gd")
var cleaning_manager: CleaningManager

const EggManagerScript = preload("res://scripts/main/egg_manager.gd")
var egg_manager: EggManager

# ------------------- FUNCIONES -------------------

# --------- De Ciclo de Vida ---------
func _ready() -> void:
	add_to_group("main")
	
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
	
	aquarium_manager = AquariumManagerScript.new()
	add_child(aquarium_manager)
	aquarium_manager.setup(self)
	
	shop_manager = ShopManagerScript.new()
	add_child(shop_manager)
	shop_manager.setup(self)
	
	alien_manager = AlienManagerScript.new()
	add_child(alien_manager)
	alien_manager.setup(self)
	
	cleaning_manager = CleaningManagerScript.new()
	add_child(cleaning_manager)
	cleaning_manager.setup(self)

	habitat_manager = HabitatManagerScript.new()
	add_child(habitat_manager)
	habitat_manager.setup(self)
	
	egg_manager = EggManagerScript.new()
	add_child(egg_manager)
	egg_manager.setup(self)

	http_request.request_completed.connect(_on_request_completed)

	var url := "https://fish-clicks.onrender.com/api/test"
	http_request.request(url)

	# Cargar sonidos música y efectos
	music_player.stream = preload("res://assets/audio/fondo/fondo1.ogg")
	music_player.play()

	for k in ITEMS.keys():
		var id := String(k)
		levels[id] = 0
		unlocked[id] = _is_item_unlocked_by_default(id)
		lifetime_generated[id] = 0.0

	shop_panel.visible = false
	encyclopedia_panel.visible = false
	profile_panel.visible = false
	btn_world_icon.visible = false
	chest_base_scale = chest_sprite.scale
	
	shop_panel.z_index = 1
	encyclopedia_panel.z_index = 20
	inventory_panel.z_index = 20
	stats_panel.z_index = 20
	barco_base_scale = barco.scale
	barco_base_position = barco.position
	bg.z_index = -100
	barco.z_index = 0
	coral.z_index = 2
	piedra.z_index = 2
	iceberg.z_index = 3
	chest.z_index = 5

	btn_hide.pressed.connect(func():
		ui_manager.play_squish(btn_hide)
		ui_manager._toggle_hud()
	)

	btn_shop_icon.pressed.connect(func():
		if alien_manager.is_event_blocking_achievement_popups():
			return

		ui_manager.play_squish(btn_shop_icon)
		ui_manager.toggle_shop()
	)

	btn_ranking_icon.pressed.connect(func():
		ui_manager.play_squish(btn_ranking_icon)
		# Si el panel está oculto, lo abrimos y cargamos datos
		if not ranking_panel.visible:
			ranking_panel._open() 
		else:
			ranking_panel._close() # O simplemente ranking_panel.visible = false
	)

	btn_encyclopedia_icon.pressed.connect(func():
		ui_manager.play_squish(btn_encyclopedia_icon)
		ui_manager.toggle_encyclopedia()
	)
	
	#btn_profile_icon.pressed.connect(func():
		#achievements_manager.register_profile_click()
		#ui_manager.play_squish(btn_profile_icon)
		#ui_manager.toggle_profile()
	#)

	btn_inventory_icon.pressed.connect(func():
		if alien_manager.is_event_blocking_achievement_popups():
			return

		ui_manager.play_squish(btn_inventory_icon)
		ui_manager.toggle_inventario()
	)

	btn_world_icon.pressed.connect(func():
		if alien_manager.is_event_blocking_achievement_popups():
			return

		habitat_manager.update_habitat_unlocks()

		if not habitat_manager.can_change_habitat():
			ui_manager.play_squish(btn_world_icon)
			return

		ui_manager.play_squish(btn_world_icon)

		habitat_manager.cycle_habitat()

		refresh_habitat_structures()
		_update_chest_sprite_by_level()
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

	btn_expand_fish_mode.pressed.connect(func():
		hide_fish_mode_overlay()
		fish_mode_manager.toggle_fish_mode()
	)

	tab_container.tab_changed.connect(ui_manager._on_tab_changed)
	_update_chest_sprite_by_level()
	chest.clicked.connect(_on_chest_clicked)

	vallisneria_base_scale = vallisneria.scale
	anubia_base_scale = anubia.scale
	coral_base_scale = coral.scale
	barco_base_scale = barco.scale

	content_pecera_normal_position = content_pecera.position
	content_pecera_normal_scale = content_pecera.scale

	swim_area_normal_position = swim_area_collision.position
	var swim_shape: RectangleShape2D = swim_area_collision.shape as RectangleShape2D
	swim_area_normal_size = swim_shape.size

	marco_pecera.visible = false
	fish_mode_overlay.visible = false

	if vallisneria.texture:
		vallisneria_ground_y = vallisneria.position.y + (vallisneria.texture.get_height() * abs(vallisneria.scale.y) * 0.5)

	if anubia.texture:
		anubia_ground_y = anubia.position.y + (anubia.texture.get_height() * abs(anubia.scale.y) * 0.5)

	if coral.texture:
		coral_ground_y = coral.position.y + (coral.texture.get_height() * abs(coral.scale.y) * 0.5)
	
	shop_manager.update_cps()
	ui_manager._update_ui()
	habitat_manager.apply_current_habitat()
	refresh_habitat_structures()
	_actualizar_peces_desbloqueados_en_enciclopedia()
	update_world_button_visibility()

	inventory_panel.move_fish_to_inventory.connect(aquarium_manager.on_move_fish_to_inventory)
	inventory_panel.move_fish_to_aquarium.connect(aquarium_manager.on_move_fish_to_aquarium)
	inventory_panel.move_fish_within_aquarium.connect(aquarium_manager.on_move_fish_within_aquarium)
	inventory_panel.habitat_changed.connect(aquarium_manager.on_inventory_habitat_changed)
	
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
	
	encyclopedia_panel.page_changed.connect(func():
		ui_manager.play_ui_sfx(SFX_PASA_PAGINA)
	)
	
	encyclopedia_panel.category_changed.connect(func():
		ui_manager.play_ui_sfx(SFX_CAMBIAR_CATEGORIA)
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
	
	ranking_panel.close_requested.connect(func():
		ui_manager.play_ui_sfx(SFX_ICON_CLOSE)
		ranking_panel.visible = false
	)

	left_info_panel.bottle_clicked.connect(func():
		ui_manager.play_ui_sfx(SFX_BOTTLE)
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
	GlobalData.load_success.connect(_on_save_loaded)
	alien_manager.check_alien_event_unlock()

	var runtime_state := GlobalData.consume_pending_runtime_state()
	var alien_return_data := GlobalData.consume_pending_alien_result()
	var abducted_fish_snapshots := GlobalData.consume_pending_abducted_fish_snapshots()
	var abduct_return_origin := GlobalData.consume_pending_abduct_return_origin()

	if not runtime_state.is_empty():
		save_manager.apply_save_state(runtime_state, false)

		habitat_manager.update_habitat_unlocks()
		update_world_button_visibility()

		_update_chest_sprite_by_level()
		refresh_habitat_structures()
		shop_manager.update_cps()
		ui_manager._update_ui()
		_actualizar_peces_desbloqueados_en_enciclopedia()

		if not alien_return_data.is_empty():
			alien_manager.abducted_fish_snapshots = abducted_fish_snapshots
			alien_manager.abduct_return_origin = abduct_return_origin
			_resume_alien_after_runtime_restore(alien_return_data)
	else:
		GlobalData.load_game()
	
	# Añadimos al grupo al final
	add_to_group("main")
	
func update_world_button_visibility() -> void:
	habitat_manager.update_habitat_unlocks()
	btn_world_icon.visible = habitat_manager.can_change_habitat()
		
func _is_item_unlocked_by_default(id: String) -> bool:
	if id == "chupete_jr" or id == "auspezio":
		return false

	return int(ITEMS[id].get("unlock_price", 0)) == 0 
	
func _resume_alien_after_runtime_restore(alien_return_data: Dictionary) -> void:
	alien_manager.resume_after_minigame(alien_return_data)

func _on_save_loaded(save_data: Dictionary) -> void:
	save_manager.apply_save_state(save_data)

	habitat_manager.update_habitat_unlocks()
	update_world_button_visibility()
	_update_chest_sprite_by_level()
	refresh_habitat_structures()
	shop_manager.update_cps()
	ui_manager._update_ui()
	_actualizar_peces_desbloqueados_en_enciclopedia()
	

func _process(delta: float) -> void:
	session_time_seconds += delta

	var passive_multiplier := 1.0
	if cleaning_manager != null:
		# Los ingresos pasivos se ven afectados durante el minijuego de limpieza
		passive_multiplier = cleaning_manager.get_coin_penalty_multiplier()

	var total_generated: float = shop_manager.get_total_passive_dps() * passive_multiplier * delta
	coins += total_generated
	total_coins_earned += total_generated

	for id in ITEMS.keys():
		var item_id := String(id)
		var def: Dictionary = ITEMS[item_id]

		if String(def.get("kind", "")) == "passive":
			lifetime_generated[item_id] += shop_manager.get_item_current_value(item_id) * delta

	ui_manager._update_currency_ui()

	achievements_manager.process_achievement_timer(delta)

	if stats_panel.visible:
		stats_manager.refresh_stats_values_only()
	
	if fish_loss_debuff_active:
		fish_loss_debuff_time_left = max(fish_loss_debuff_time_left - delta, 0.0)

		if fish_loss_debuff_time_left <= 0.0:
			clear_fish_loss_debuff()

	if alien_manager != null:
		alien_manager.check_alien_event_unlock()

		if alien_manager.can_trigger_alien_event():
			alien_manager.try_start_alien_event()

func _input(event: InputEvent) -> void:
	fish_mode_manager.handle_input(event)

	# Detectar cualquier click y reiniciar inactividad
	if event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			if cleaning_manager != null and cleaning_manager.should_count_inactivity():
				cleaning_manager.register_player_activity()

	if event is InputEventKey and event.pressed and event.keycode == KEY_K:
		if alien_manager != null:
			alien_manager.start_alien_event()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos: Vector2 = get_viewport().get_mouse_position()

		# Asusta peces cercanos al click
		for fish in fish_layer.get_children():
			if fish.has_method("scare_from"):
				if fish.global_position.distance_to(click_pos) < 120:
					fish.scare_from(click_pos)
					achievements_manager.register_fish_annoyed()

# --------- Callbacks/Requests ---------
@warning_ignore("unused_parameter")
func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	@warning_ignore("unused_variable")
	var i: int;
	
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
		
func reset_local_state() -> void:
	# 1. Reseteo de variables numéricas y progreso
	coins = 0.0
	total_coins_earned = 0.0
	total_clicks = 0
	session_time_seconds = 0.0
	click_power = 1
	alien_minigame_wins = 0
	alien_minigame_losses = 0
	# El DPS se pondrá a 0 automáticamente al llamar a update_cps() más abajo

	# 2. Limpieza de diccionarios e inventario
	levels.clear()
	unlocked.clear()
	fish_inventory.clear()

	# Re-inicializamos los objetos gratuitos según la base de datos (como el cofre)
	for k in ITEMS.keys():
		var id := String(k)
		levels[id] = 0
		unlocked[id] = int(ITEMS[id].get("unlock_price", 0)) == 0

	# 3. Reseteo de Logros y contadores del AchievementsManager
	achievements_manager.achievements_unlocked.clear()
	for achievement_id in achievements_manager.ACHIEVEMENT_DEFS.keys():
		achievements_manager.achievements_unlocked[achievement_id] = false

	achievements_manager.random_tick_unlocked = false
	achievements_manager.volume_slider_spam_unlocked = false
	achievements_manager.total_shinies_ever = 0
	achievements_manager.total_structures_spent = 0.0
	achievements_manager.alien_clicked_count = 0
	achievements_manager.profile_clicks_count = 0
	achievements_manager.annoyed_fish_count = 0
	achievements_manager.achievement_check_accum = 0.0
	achievements_manager.alien_no_hit_unlocked = false
	achievements_manager.alien_egg_obtained = false
	
	# 3.1. Reseteo de limpieza
	if cleaning_manager != null:
		cleaning_manager.inactivity_time = 0.0
		cleaning_manager.cleaning_event_available = false
		cleaning_manager.total_dirt_spots_cleaned = 0
		cleaning_manager.cleaning_events_completed = 0
	
	# 3.2 Reset del alien
	if alien_manager != null:
		alien_manager.alien_event_state = AlienManager.AlienEventState.IDLE
		alien_manager.alien_event_available = false
		alien_manager.alien_event_done = false
		alien_manager.abducted_fish_snapshots.clear()
		alien_manager.abduct_return_origin = Vector2.ZERO
		alien_manager.alien_escape_fx_active = false

		if alien_manager.alien_instance != null and is_instance_valid(alien_manager.alien_instance):
			alien_manager.alien_instance.queue_free()

		if egg_manager != null:
			egg_manager.clear_active_egg()
		
		for child in content_pecera.get_children():
			if child is AlienEgg:
				child.queue_free()

		alien_manager.alien_instance = null

	# 4. Limpieza física de Acuarios (Peces nadando)
	for habitat_id in aquarium_data.keys():
		var empty_slots := []
		empty_slots.resize(10)
		empty_slots.fill(null)
		aquarium_data[habitat_id] = empty_slots

	for child in fish_layer.get_children():
		child.queue_free()

	# 5. ACTUALIZACIÓN VISUAL Y RECALCULO (Lo que faltaba para resetear DPS y estructuras)
	# Recalcular el DPS (dará 0 porque no hay niveles)
	shop_manager.update_cps()
	
	# Forzar a los sprites del escenario a ocultarse/actualizarse al nivel 0
	_update_chest_sprite_by_level()
	_update_algas_sprite_by_level()
	_update_tronco_visibility_by_level()
	_update_anubia_sprite_by_level()
	_update_coral_sprite_by_level()
	_update_piedra_sprite_by_level()
	_update_iceberg_sprite_by_level()
	_update_barco_sprite_by_level()
	
	# Actualizar la interfaz de usuario completa (etiquetas de doblones, botellas, etc.)
	ui_manager._update_ui()
	
	if stats_panel.visible:
		stats_manager.refresh_stats_panel_full()
	
	# Limpiar la foto de perfil en el Singleton Global
	GlobalData.user_photo_url = ""

func _on_btn_hide_hud_pressed() -> void:
	pass # Replace with function body.

# --------- Helpers para UI ---------
func get_list_for_category(category: String) -> VBoxContainer:
	match category:
		"Peces":
			return list_peces
		"Estructuras":
			return list_estructuras
		_:
			return list_peces
			
# --------- Animaciones ---------
func _play_click_animation() -> void:
	var tween = create_tween()
	tween.tween_property(chest_sprite, "scale", chest_base_scale * 1.08, 0.06)
	tween.tween_property(chest_sprite, "scale", chest_base_scale, 0.08)
	
func _spawn_floating_text() -> void:
	var t: Label = floating_text_scene.instantiate()
	add_child(t)

	t.text = "+" + str(click_power)

	var mouse_pos = get_viewport().get_mouse_position()
	t.position = mouse_pos + Vector2(-5, -20)
	t.z_index = 1000

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

func _chest_level_up_fx() -> void:
	var t := create_tween()
	t.tween_property(chest_sprite, "scale", chest_base_scale * 1.12, 0.08)
	t.tween_property(chest_sprite, "scale", chest_base_scale, 0.10)

# --------- Enciclopedia ---------
func _actualizar_peces_desbloqueados_en_enciclopedia() -> void:
	var ids_desbloqueados: Array[int] = []

	for item_id in ENCYCLOPEDIA_FISH_IDS.keys():
		if bool(unlocked.get(item_id, false)):
			ids_desbloqueados.append(int(ENCYCLOPEDIA_FISH_IDS[item_id]))

	if encyclopedia_panel.has_method("set_pez_ids_desbloqueados"):
		encyclopedia_panel.set_pez_ids_desbloqueados(ids_desbloqueados)

# --------- Escenario ---------
func refresh_habitat_structures() -> void:
	_update_algas_sprite_by_level()
	_update_anubia_sprite_by_level()
	_update_tronco_visibility_by_level()

	_update_coral_sprite_by_level()
	_update_piedra_sprite_by_level()
	_update_iceberg_sprite_by_level()
	_update_barco_sprite_by_level()

func _update_chest_sprite_by_level() -> void:
	var chest_level: int = shop_manager.get_level("cofre")
	var is_habitat_2: bool = habitat_manager.current_habitat == "habitat_2"

	if chest_level <= 0:
		chest_sprite.texture = TEX_CHEST2_CLOSED if is_habitat_2 else TEX_CHEST_CLOSED
	elif chest_level <= 3:
		chest_sprite.texture = TEX_CHEST2_EMPTY if is_habitat_2 else TEX_CHEST_EMPTY
	elif chest_level <= 7:
		chest_sprite.texture = TEX_CHEST2_MID if is_habitat_2 else TEX_CHEST_MID
	else:
		chest_sprite.texture = TEX_CHEST2_FULL if is_habitat_2 else TEX_CHEST_FULL

func _update_algas_sprite_by_level() -> void:
	var algas_level: int = shop_manager.get_level("vallisneria")
	var algas_unlocked: bool = bool(unlocked.get("vallisneria", false))
	var is_current_habitat := habitat_manager.current_habitat == "habitat_1"

	if not is_current_habitat or not algas_unlocked or algas_level <= 0:
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
	var level: int = shop_manager.get_level("anubia")
	var is_current_habitat := habitat_manager.current_habitat == "habitat_1"

	if not is_current_habitat or not bool(unlocked.get("anubia", false)) or level <= 0:
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

func _update_tronco_visibility_by_level() -> void:
	var level: int = shop_manager.get_level("tronco")
	var is_unlocked: bool = bool(unlocked.get("tronco", false))
	var is_current_habitat := habitat_manager.current_habitat == "habitat_1"

	tronco_1.visible = false
	tronco_2.visible = false
	tronco_3.visible = false

	if not is_current_habitat or not is_unlocked or level <= 0:
		return

	if level <= 5:
		tronco_3.visible = true
	elif level <= 10:
		tronco_2.visible = true
	else:
		tronco_1.visible = true

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


# --------- Escenario (Segundo Mundo) ---------
func _update_coral_sprite_by_level() -> void:
	var level: int = shop_manager.get_level("coral")
	var is_unlocked: bool = bool(unlocked.get("coral", false))
	var is_current_habitat := habitat_manager.current_habitat == "habitat_2"

	if not is_current_habitat or not is_unlocked or level <= 0:
		coral.visible = false
		return

	coral.visible = true

	if level <= 5:
		_set_coral_texture(TEX_CORAL_0, 0.8)
	elif level <= 10:
		_set_coral_texture(TEX_CORAL_1, 1.0)
	else:
		_set_coral_texture(TEX_CORAL_2, 1.4)


func _update_piedra_sprite_by_level() -> void:
	var level: int = shop_manager.get_level("piedra")
	var is_unlocked: bool = bool(unlocked.get("piedra", false))
	var is_current_habitat := habitat_manager.current_habitat == "habitat_2"

	if not is_current_habitat or not is_unlocked or level <= 0:
		piedra.visible = false
		return

	piedra.visible = true

	if level <= 5:
		piedra.texture = TEX_PIEDRA_0
	elif level <= 10:
		piedra.texture = TEX_PIEDRA_1
	else:
		piedra.texture = TEX_PIEDRA_2


func _update_iceberg_sprite_by_level() -> void:
	var level: int = shop_manager.get_level("iceberg")
	var is_unlocked: bool = bool(unlocked.get("iceberg", false))
	var is_current_habitat := habitat_manager.current_habitat == "habitat_2"

	if not is_current_habitat or not is_unlocked or level <= 0:
		iceberg.visible = false
		return

	iceberg.visible = true

	if level <= 5:
		iceberg.texture = TEX_ICEBERG_0
	elif level <= 10:
		iceberg.texture = TEX_ICEBERG_1
	else:
		iceberg.texture = TEX_ICEBERG_2
		
func _update_barco_sprite_by_level() -> void:
	var level: int = shop_manager.get_level("barco")
	var is_unlocked: bool = bool(unlocked.get("barco", false))
	var is_current_habitat := habitat_manager.current_habitat == "habitat_2"

	if not is_current_habitat or not is_unlocked or level <= 0:
		barco.visible = false
		return

	barco.visible = true

	if level <= 5:
		_set_barco_texture(TEX_BARCO_0, 0.8, 0)
	elif level <= 10:
		_set_barco_texture(TEX_BARCO_1, 1.2, -40)
	else:
		_set_barco_texture(TEX_BARCO_2, 1.7, -70)
		

func _set_coral_texture(tex: Texture2D, scale_mult: float = 1.0) -> void:
	if tex == null:
		return

	coral.texture = tex
	coral.scale = coral_base_scale * scale_mult

	var tex_height: float = tex.get_height() * abs(coral.scale.y)

	if coral.centered:
		coral.position.y = coral_ground_y - tex_height * 0.5
	else:
		coral.position.y = coral_ground_y - tex_height
		
func _set_barco_texture(tex: Texture2D, scale_mult: float = 1.0, extra_y: float = 0.0) -> void:
	if tex == null:
		return

	barco.texture = tex
	barco.scale = barco_base_scale * scale_mult
	barco.position = barco_base_position + Vector2(0, extra_y)
	barco.z_index = 0

# --------- Formateo/Utils ---------

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

func apply_normal_mode_layout() -> void:
	content_pecera.position = content_pecera_normal_position
	content_pecera.scale = content_pecera_normal_scale

	swim_area_collision.position = swim_area_normal_position
	var swim_shape: RectangleShape2D = swim_area_collision.shape as RectangleShape2D
	swim_shape.size = swim_area_normal_size

	refresh_fishes_swim_rect()

	marco_pecera.visible = false

func apply_fish_mode_layout() -> void:
	content_pecera.position = Vector2(26, 24)
	content_pecera.scale = Vector2(0.96, 0.96)

	swim_area_collision.position = Vector2(577, 330)
	var swim_shape: RectangleShape2D = swim_area_collision.shape as RectangleShape2D
	swim_shape.size = Vector2(1022, 490)

	refresh_fishes_swim_rect()

	marco_pecera.visible = true

func refresh_fishes_swim_rect() -> void:
	for fish in fish_layer.get_children():
		if fish.has_method("_update_swim_rect"):
			fish._update_swim_rect()

func show_fish_mode_overlay() -> void:
	fish_mode_overlay.visible = true

func hide_fish_mode_overlay() -> void:
	fish_mode_overlay.visible = false

func start_fish_loss_debuff(duration: float = FISH_LOSS_DEBUFF_DURATION) -> void:
	fish_loss_debuff_active = true
	fish_loss_debuff_time_left = duration
	_refresh_all_fish_debuff_visuals()

func clear_fish_loss_debuff() -> void:
	fish_loss_debuff_active = false
	fish_loss_debuff_time_left = 0.0
	_refresh_all_fish_debuff_visuals()

func is_fish_loss_debuff_active() -> bool:
	return fish_loss_debuff_active

func _refresh_all_fish_debuff_visuals() -> void:
	for fish in fish_layer.get_children():
		if fish != null and is_instance_valid(fish) and fish.has_method("update_debuff_visual"):
			fish.update_debuff_visual()

func update_ui_block_state() -> void:
	var blocked := alien_manager.is_event_blocking_achievement_popups()

	var blocked_color := Color(0.5, 1.0, 0.7, 0.85)
	var normal_color := Color(1, 1, 1, 1)

	btn_shop_icon.modulate = blocked_color if blocked else normal_color
	btn_inventory_icon.modulate = blocked_color if blocked else normal_color
	btn_world_icon.modulate = blocked_color if blocked else normal_color
