extends TextureButton

@onready var nick_label: Label = get_node_or_null("NickLabel")

func _ready() -> void:
	pressed.connect(_on_pressed)
	GlobalData.login_success.connect(_on_auth_changed)
	if GlobalData.is_logged_in:
		_refresh_label()

func _on_pressed() -> void:
	var panel = get_tree().current_scene.get_node_or_null("UI/Root/HUD/ProfilePanel")
	if panel:
		panel.toggle()
	else:
		push_error("ProfilePanel no encontrado")

func _on_auth_changed(_data) -> void:
	_refresh_label()

func _refresh_label() -> void:
	if not nick_label:
		return
	nick_label.text = GlobalData.user_nickname if GlobalData.is_logged_in else "Perfil"
