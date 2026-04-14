extends TextureButton

# 1. Asegúrate de que el nombre coincida exactamente con el nodo en tu escena
@onready var user_image: TextureRect = get_node_or_null("UserImage")
@onready var nick_label: Label = get_node_or_null("NickLabel")

func _ready() -> void:
	# 2. Vital: Esto permite que el ProfilePanel le envíe la nueva foto
	add_to_group("main_hud_buttons") 
	
	pressed.connect(_on_pressed)
	GlobalData.login_success.connect(_on_auth_changed)
	
	# 3. Intentar cargar la foto al arrancar
	update_avatar()

func _on_pressed() -> void:
	var main = get_tree().current_scene
	var panel = main.get_node_or_null("UI/Root/HUD/ProfilePanel")
	
	if panel:
		# Animación y registro de click
		if main.ui_manager: main.ui_manager.play_squish(self)
		if main.achievements_manager: main.achievements_manager.register_profile_click()
		
		# Sonido y apertura
		var sfx = main.SFX_ICON_OPEN if not panel.visible else main.SFX_ICON_CLOSE
		main.ui_sfx_player.stream = sfx
		main.ui_sfx_player.play()
		
		panel.toggle()

func _on_auth_changed(_data) -> void:
	update_avatar()

# Esta función es la que recibe la orden del grupo "main_hud_buttons"
func update_avatar() -> void:
	if nick_label:
		nick_label.text = GlobalData.user_nickname if GlobalData.is_logged_in else "Perfil"
	
	if not user_image: return
	
	# CASO 1: Usuario logueado con foto personalizada
	if GlobalData.is_logged_in and not GlobalData.user_photo_url.is_empty():
		var img = Image.new()
		var raw_data = Marshalls.base64_to_raw(GlobalData.user_photo_url)
		var err = img.load_png_from_buffer(raw_data)
		if err != OK: err = img.load_jpg_from_buffer(raw_data)
			
		if err == OK:
			user_image.texture = ImageTexture.create_from_image(img)
			user_image.show()
			return # Salimos de la función si todo fue bien

	# CASO 2: Fallback (Si no hay login o no hay foto, ponemos la default)
	# Reemplaza 'default_avatar' con tu preload si lo tienes, o déjalo en null para que se vea el marco vacío
	user_image.texture = load("res://assets/ui/iconos/default_avatar.png") 
	user_image.show()
