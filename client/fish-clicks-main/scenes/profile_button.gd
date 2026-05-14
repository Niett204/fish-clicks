extends TextureButton

@export var login_panel_scene: PackedScene

func _ready():
	# Si no especificaste la escena, cargarla dinámicamente
	if not login_panel_scene:
		login_panel_scene = load("res://scenes/LoginPanel.tscn")
