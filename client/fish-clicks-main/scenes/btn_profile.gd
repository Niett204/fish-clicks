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

func update_avatar() -> void:
	if nick_label:
		nick_label.text = GlobalData.user_nickname if GlobalData.is_logged_in else "Perfil"
	
	if not user_image: return
	
	if GlobalData.is_logged_in and not GlobalData.user_photo_url.is_empty():
		var raw_data = Marshalls.base64_to_raw(GlobalData.user_photo_url)
		
		if raw_data.size() > 100: 
			var img = Image.new()
			var err = OK
			
			# --- CAMBIO AQUÍ: Usamos la extensión guardada ---
			var ext = GlobalData.user_photo_extension.to_lower()
			
			if ext == "png":
				err = img.load_png_from_buffer(raw_data)
			elif ext == "jpg" or ext == "jpeg":
				err = img.load_jpg_from_buffer(raw_data)
			else:
				err = img.load_png_from_buffer(raw_data)
				if err != OK: err = img.load_jpg_from_buffer(raw_data)
			# ------------------------------------------------
				
			if err == OK:
				img.convert(Image.FORMAT_RGBA8)
				user_image.texture = ImageTexture.create_from_image(img)
				user_image.show()
				return 

	user_image.texture = load("res://assets/ui/iconos/default_avatar.png") 
	user_image.show()
