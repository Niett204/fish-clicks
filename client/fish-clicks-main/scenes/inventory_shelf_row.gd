extends Control

@onready var shelf_board: TextureRect = $ShelfBoard
@onready var items_margin: MarginContainer = $ItemsMargin
@onready var items_row: HBoxContainer = $ItemsMargin/ItemsRow

func _ready() -> void:
	custom_minimum_size = Vector2(0, 120)
