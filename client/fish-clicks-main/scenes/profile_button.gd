extends TextureButton

@export var login_panel_scene: PackedScene

func _ready():
	# Conectar la señal del botón
	pressed.connect(_on_pressed)

	# Si no especificaste la escena, cargarla dinámicamente
	if not login_panel_scene:
		login_panel_scene = load("res://scenes/LoginPanel.tscn")

func _on_pressed():
	# Crear instancia del panel de login
	if login_panel_scene:
		var login_panel = login_panel_scene.instantiate()
		get_parent().get_parent().get_parent().add_child(login_panel)
	else:
		push_error("LoginPanel scene no está asignado en el inspector")

