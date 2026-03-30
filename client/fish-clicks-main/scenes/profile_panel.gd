extends Control
# res://scenes/profile_panel.gd

# ── Vista perfil (logueado) ────────────────────────────────────────────────
@onready var profile_view: VBoxContainer = $PanelContainer/VBox/ProfileView
@onready var nick_label:   Label         = $PanelContainer/VBox/ProfileView/MarginProfile/Fields/NickLabel
@onready var email_label:  Label         = $PanelContainer/VBox/ProfileView/MarginProfile/Fields/EmailLabel
@onready var btn_logout:   Button        = $PanelContainer/VBox/ProfileView/MarginProfile/Fields/BtnLogout

# ── Vista auth (no logueado) ───────────────────────────────────────────────
@onready var auth_view:    VBoxContainer = $PanelContainer/VBox/AuthView
@onready var tab_container: TabContainer = $PanelContainer/VBox/AuthView/TabContainer

@onready var nick_field:   LineEdit = $PanelContainer/VBox/AuthView/TabContainer/Login/MarginLogin/Fields/NickField
@onready var pass_field:   LineEdit = $PanelContainer/VBox/AuthView/TabContainer/Login/MarginLogin/Fields/PassField
@onready var btn_login:    Button   = $PanelContainer/VBox/AuthView/TabContainer/Login/MarginLogin/Fields/BtnLogin
@onready var login_error:  Label    = $PanelContainer/VBox/AuthView/TabContainer/Login/MarginLogin/Fields/ErrorLabel

@onready var reg_nick:     LineEdit = $PanelContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/RegNick
@onready var reg_email:    LineEdit = $PanelContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/RegEmail
@onready var reg_pass:     LineEdit = $PanelContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/RegPass
@onready var reg_confirm:  LineEdit = $PanelContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/RegConfirm
@onready var btn_register: Button   = $PanelContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/BtnRegister
@onready var reg_error:    Label    = $PanelContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/ErrorLabel
@onready var reg_ok:       Label    = $PanelContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/OkLabel

# ── Común ──────────────────────────────────────────────────────────────────
@onready var btn_close: Button = $PanelContainer/VBox/TopBar/BtnClose


func _ready() -> void:
	GlobalData.login_success.connect(_on_login_ok)
	GlobalData.login_failed.connect(_on_login_err)
	GlobalData.register_success.connect(_on_register_ok)
	GlobalData.register_failed.connect(_on_register_err)

	btn_close.pressed.connect(_close)
	btn_login.pressed.connect(_do_login)
	btn_register.pressed.connect(_do_register)
	btn_logout.pressed.connect(_do_logout)

	pass_field.secret   = true
	reg_pass.secret     = true
	reg_confirm.secret  = true

	login_error.hide()
	reg_error.hide()
	reg_ok.hide()

	pass_field.text_submitted.connect(func(_t): _do_login())
	reg_confirm.text_submitted.connect(func(_t): _do_register())

	hide()


# ── Abrir / cerrar ─────────────────────────────────────────────────────────
func toggle() -> void:
	if visible:
		_close()
	else:
		_open()


func _open() -> void:
	_refresh_view()
	show()
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.15)


func _close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.12)
	tw.finished.connect(hide)


# ── Decide qué vista mostrar ───────────────────────────────────────────────
func _refresh_view() -> void:
	if GlobalData.is_logged_in:
		nick_label.text  = "Hola, %s!" % GlobalData.user_nickname
		email_label.text = GlobalData.user_email
		profile_view.show()
		auth_view.hide()
	else:
		profile_view.hide()
		auth_view.show()


# ── Login ──────────────────────────────────────────────────────────────────
func _do_login() -> void:
	var nick := nick_field.text.strip_edges()
	var pw   := pass_field.text
	if nick.is_empty() or pw.is_empty():
		_show_err(login_error, "Rellena todos los campos")
		return
	GlobalData.user_nickname = nick
	btn_login.disabled = true
	btn_login.text = "Entrando..."
	login_error.hide()
	GlobalData.login(nick, pw)


func _on_login_ok(_data: Dictionary) -> void:
	btn_login.disabled = false
	btn_login.text = "Entrar"
	_refresh_view()


func _on_login_err(err: String) -> void:
	btn_login.disabled = false
	btn_login.text = "Entrar"
	_show_err(login_error, err)


# ── Registro ───────────────────────────────────────────────────────────────
func _do_register() -> void:
	var nick    := reg_nick.text.strip_edges()
	var email   := reg_email.text.strip_edges()
	var pw      := reg_pass.text
	var confirm := reg_confirm.text

	if nick.is_empty() or email.is_empty() or pw.is_empty():
		_show_err(reg_error, "Rellena todos los campos")
		return
	if pw != confirm:
		_show_err(reg_error, "Las contrasenas no coinciden")
		return
	if not ("@" in email and "." in email.split("@")[-1]):
		_show_err(reg_error, "Email no valido")
		return

	GlobalData.user_nickname = nick
	btn_register.disabled = true
	btn_register.text = "Creando cuenta..."
	reg_error.hide()
	reg_ok.hide()
	GlobalData.register(email, nick, pw)


func _on_register_ok() -> void:
	btn_register.disabled = false
	btn_register.text = "Crear cuenta"
	reg_ok.text = "Cuenta creada! Inicia sesion."
	reg_ok.show()
	await get_tree().create_timer(1.5).timeout
	tab_container.current_tab = 0
	nick_field.text = reg_nick.text


func _on_register_err(err: String) -> void:
	btn_register.disabled = false
	btn_register.text = "Crear cuenta"
	_show_err(reg_error, err)


# ── Logout ─────────────────────────────────────────────────────────────────
func _do_logout() -> void:
	GlobalData.clear_session()
	_refresh_view()


# ── Utilidades ─────────────────────────────────────────────────────────────
func _show_err(lbl: Label, msg: String) -> void:
	lbl.text = msg
	lbl.show()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close()
