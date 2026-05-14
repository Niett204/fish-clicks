extends TextureButton

@onready var user_image: TextureRect = get_node_or_null("UserImage")
@onready var nick_label: Label = get_node_or_null("NickLabel")

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
		user_image.texture = load("res://assets/ui/iconos/default_avatar.png")
		user_image.show()
