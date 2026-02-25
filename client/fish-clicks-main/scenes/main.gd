extends Node2D

@export var floating_text_scene: PackedScene
@export var fish_scene: PackedScene
@export var dps_per_fish: float = 1.0

@onready var coins_label: Label = $UI/HUD/DoblonesLabel
@onready var shop_panel: Control = $UI/TiendaPanel
@onready var toggle_button: Button = $UI/ToggleTiendaButton
@onready var chest: Area2D = $Cofre
@onready var chest_sprite: Sprite2D = $Cofre/Sprite2D
@onready var fish_layer = $PecesLayer
@onready var dps_label: Label = $UI/HUD/DpsLabel

var dps: float = 0.0
var coins: float = 0.0
var click_power: int = 1
var fish_count: int = 0
var chest_base_scale: Vector2

func _ready() -> void:
	shop_panel.visible = false
	chest_base_scale = chest_sprite.scale
	toggle_button.text = "▼"

	chest.clicked.connect(_on_chest_clicked)

	_update_cps()
	_update_ui()

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
