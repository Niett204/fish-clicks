extends TextureButton

# Ya no necesitamos buscar el panel aquí, solo la foto
@onready var nick_label: Label = get_node_or_null("NickLabel")
@onready var avatar_icon: TextureRect = $AvatarIcon/UserImage 

var default_avatar = preload("res://assets/ui/iconos/default_avatar.png")

func _ready() -> void:
	add_to_group("main_hud_buttons") 
	GlobalData.login_success.connect(_on_auth_changed)
	
	# IMPORTANTE: No conectamos la señal "pressed" aquí,
	# porque ya la conectaste en Main.gd
	
	_refresh_ui()

func _on_auth_changed(_data) -> void:
	_refresh_ui()

func _refresh_ui() -> void:
	_refresh_label()
	update_avatar()

func _refresh_label() -> void:
	if nick_label:
		nick_label.text = GlobalData.user_nickname if GlobalData.is_logged_in else "Perfil"

func update_avatar() -> void:
	if not avatar_icon: return
	var photo_url = GlobalData.user_photo_url
	
	if not GlobalData.is_logged_in or photo_url == "":
		avatar_icon.texture = default_avatar
		return
	
	if photo_url.begins_with("data:image"):
		var parts = photo_url.split(",")
		if parts.size() >= 2:
			var buffer = Marshalls.base64_to_raw(parts[1])
			var img = Image.new()
			var err = img.load_png_from_buffer(buffer)
			if err != OK: err = img.load_jpg_from_buffer(buffer)
			if err == OK:
				avatar_icon.texture = ImageTexture.create_from_image(img)
	elif photo_url.begins_with("res://"):
		avatar_icon.texture = load(photo_url)
