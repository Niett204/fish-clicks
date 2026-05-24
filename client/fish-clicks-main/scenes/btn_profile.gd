extends TextureButton

@onready var user_image: TextureRect = get_node_or_null("UserImage")
@onready var nick_label: Label = get_node_or_null("NickLabel")

var default_avatar = preload("res://assets/ui/iconos/default_avatar.png")

func _ready() -> void:
	add_to_group("main_hud_buttons")

	GlobalData.login_success.connect(_on_auth_changed)

	if not GlobalData.profile_updated.is_connected(update_avatar):
		GlobalData.profile_updated.connect(update_avatar)

	update_avatar()

func _on_auth_changed(_data) -> void:
	update_avatar()

func update_avatar() -> void:
	if nick_label:
		nick_label.text = GlobalData.user_nickname if GlobalData.is_logged_in else "Perfil"

	if user_image:
		user_image.show()
		
		# Comprobamos si está logueado y tiene una foto guardada
		if GlobalData.is_logged_in and GlobalData.user_photo_url != "":
			_load_user_photo(GlobalData.user_photo_url)
		else:
			# Si no, ponemos la de defecto
			user_image.texture = default_avatar

# --- Lógica de decodificación (Extraída de tu ProfilePanel) ---
func _load_user_photo(photo_str: String) -> void:
	if photo_str.begins_with("res://"):
		user_image.texture = load(photo_str)
		return
		
	var raw_data = Marshalls.base64_to_raw(photo_str)
	if raw_data.size() > 100: 
		var img = Image.new()
		var err = OK
		var ext = GlobalData.user_photo_extension.to_lower()
		
		if ext == "png":
			err = img.load_png_from_buffer(raw_data)
		elif ext == "jpg" or ext == "jpeg":
			err = img.load_jpg_from_buffer(raw_data)
		else:
			# Fallback
			err = img.load_png_from_buffer(raw_data)
			if err != OK: err = img.load_jpg_from_buffer(raw_data)
		
		if err == OK:
			img.convert(Image.FORMAT_RGBA8) 
			user_image.texture = ImageTexture.create_from_image(img)
			return
	
	# Si algo falla en la decodificación, ponemos la de por defecto
	user_image.texture = default_avatar
