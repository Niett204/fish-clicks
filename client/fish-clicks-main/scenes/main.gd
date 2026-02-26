extends Node2D

@export var floating_text_scene: PackedScene
@export var fish_scene: PackedScene
@export var dps_per_fish: float = 1.0
@export var shop_item_card_scene: PackedScene

@onready var coins_label: Label = $UI/Root/HUD/DoblonesLabel
@onready var shop_panel: Control = $UI/Root/TiendaPanel
@onready var toggle_button: Button = $UI/Root/ToggleTiendaButton
@onready var chest: Area2D = $Cofre
@onready var chest_sprite: Sprite2D = $Cofre/Sprite2D
@onready var fish_layer = $PecesLayer
@onready var dps_label: Label = $UI/Root/HUD/DpsLabel
@onready var tab_container: TabContainer = $UI/Root/TiendaPanel/TabContainer
@onready var list_peces: VBoxContainer = $UI/Root/TiendaPanel/TabContainer/Peces/ScrollContainer/ListPeces
@onready var list_estructuras: VBoxContainer = $UI/Root/TiendaPanel/TabContainer/Estructuras/ScrollContainer/ListEstructuras

var dps: float = 0.0
var coins: float = 0.0
var click_power: int = 1
var fish_count: int = 0
var chest_base_scale: Vector2

func _ready() -> void:
	shop_panel.visible = false
	chest_base_scale = chest_sprite.scale
	toggle_button.text = "▼"

	tab_container.tab_changed.connect(_on_tab_changed)

	chest.clicked.connect(_on_chest_clicked)

	_update_cps()
	_update_ui()

func _on_tab_changed(tab: int) -> void:
	var tab_name := tab_container.get_tab_title(tab)

	if tab_name == "Peces" and list_peces.get_child_count() == 0:
		add_fish_card()

	if tab_name == "Estructuras" and list_estructuras.get_child_count() == 0:
		add_cofre_card()

	update_shop_cards() # <--- para refrescar al entrar

	if tab_name == "Peces" and list_peces.get_child_count() == 0:
		add_fish_card()

	if tab_name == "Estructuras" and list_estructuras.get_child_count() == 0:
		add_cofre_card()

func add_fish_card():
	var card = shop_item_card_scene.instantiate()
	list_peces.add_child(card)

	var icon_tex: Texture2D = null
	var icon_path := "res://assets/peces/doblon.png"

	if ResourceLoader.exists(icon_path):
		icon_tex = load(icon_path)

	card.setup(
		"fish_basic",
		"Pez Común",
		"Precio: 25",
		"DPS +1",
		str(fish_count),
		icon_tex,
		25, # price
		25  # unlock_price (ajústalo a lo que quieras)
	)

	card.buy_pressed.connect(_on_buy_pressed)

func _on_buy_pressed(id: String) -> void:
	match id:
		"fish_basic":
			_on_compra_pez_button_pressed()
		"cofre":
			_on_mejora_cofre_button_pressed()

func _on_chest_clicked() -> void:
	coins += click_power
	_update_ui()
	_play_click_animation()
	_spawn_floating_text()

func _spawn_floating_text() -> void:
	var t: Label = floating_text_scene.instantiate()
	add_child(t)

	t.text = "+" + str(click_power)

	var mouse_pos = get_viewport().get_mouse_position()
	t.position = mouse_pos + Vector2(-5, -20)
	t.z_index = 1000

func _update_ui() -> void:
	coins_label.text = "Doblones: " + str(int(coins))
	update_shop_cards()

func _on_mejora_cofre_button_pressed() -> void:
	var price := 10  # precio fijo por ahora
	
	if coins < price:
		return
	
	coins -= price
	click_power += 1
	
	print("Nuevo click power:", click_power)  # debug opcional
	
	_update_ui()
	
func _on_toggle_tienda_button_pressed() -> void:
	shop_panel.visible = !shop_panel.visible
	
	if shop_panel.visible:
		_on_tab_changed($UI/Root/TiendaPanel/TabContainer.current_tab)
		toggle_button.text = "▲"
	else:
		toggle_button.text = "▼"
		
func _update_cps() -> void:
	dps = fish_count * dps_per_fish
	_update_dps_ui()

func _update_dps_ui() -> void:
	dps_label.text = "DPS: " + str(snapped(dps, 0.01))

func _process(delta: float) -> void:
	coins += dps * delta
	_update_ui()

func _on_compra_pez_button_pressed() -> void:
	var price := 25
	
	if coins < price:
		return
	
	coins -= price
	fish_count += 1
	
	# Crear pez
	var fish = fish_scene.instantiate()
	fish_layer.add_child(fish)
	fish.position = Vector2(
		randi_range(200, 1000),
		randi_range(300, 600)
	)
	
	_update_cps()
	_update_ui()
	
func _play_click_animation() -> void:
	var tween = create_tween()
	tween.tween_property(chest_sprite, "scale", chest_base_scale * 1.08, 0.06)
	tween.tween_property(chest_sprite, "scale", chest_base_scale, 0.08)
	
func add_cofre_card():
	var card = shop_item_card_scene.instantiate()
	list_estructuras.add_child(card)

	var icon_tex: Texture2D = null
	var icon_path := "res://assets/estructuras/cofre1.png" # o tu icono del cofre

	if ResourceLoader.exists(icon_path):
		icon_tex = load(icon_path)

	card.setup(
		"cofre",
		"Cofre",
		"Precio: 10",
		"+1 Click",
		str(click_power),
		icon_tex,
		10, # price
		0   # unlock_price
	)

	card.buy_pressed.connect(_on_buy_pressed)

func update_shop_cards() -> void:
	for card in list_peces.get_children():
		card.update_state(coins)
	for card in list_estructuras.get_children():
		card.update_state(coins)
