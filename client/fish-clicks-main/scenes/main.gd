extends Node2D

@onready var coins_label: Label = $UI/HUD/DoblonesLabel
@onready var shop_panel: Control = $UI/TiendaPanel
@onready var toggle_button: Button = $UI/ToggleTiendaButton
@onready var chest: Area2D = $Cofre

@export var fish_scene: PackedScene
@onready var fish_layer = $PecesLayer

var dps: int = 0
var coins: int = 0
var click_power: int = 1
var fish_count: int = 0

func _ready() -> void:
	print("READY MAIN") #test
	shop_panel.visible = false
	toggle_button.text = "▼"

	print("Conectando cofre...")
	chest.clicked.connect(_on_chest_clicked)

	_update_ui()

func _on_chest_clicked() -> void:
	coins += click_power
	_update_ui()

func _update_ui() -> void:
	coins_label.text = "Doblones: " + str(coins)

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
		toggle_button.text = "▲"
	else:
		toggle_button.text = "▼"
		
func _update_cps() -> void:
	dps = fish_count * dps

func _process(delta):
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
