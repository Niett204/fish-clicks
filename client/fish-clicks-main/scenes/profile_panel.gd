extends Control

signal close_requested

# ── Nodos de la Interfaz ──────────────────────────────────────────────────
@onready var profile_view: VBoxContainer = $PanelContainer/VBox/ProfileView
@onready var auth_view:    VBoxContainer = $PanelContainer/VBox/AuthView

# Elementos del Perfil (Logueado)
@onready var user_photo:   TextureRect   = $PanelContainer/VBox/ProfileView/MarginProfile/Fields/PhotoFrame/UserPhoto
@onready var nick_label:   Label         = $PanelContainer/VBox/ProfileView/MarginProfile/Fields/NickLabel
@onready var email_label:  Label         = $PanelContainer/VBox/ProfileView/MarginProfile/Fields/EmailLabel
@onready var btn_logout:   Button        = $PanelContainer/VBox/ProfileView/MarginProfile/Fields/BtnLogout

# Elementos de Auth (No logueado)
@onready var tab_container: TabContainer = $PanelContainer/VBox/AuthView/TabContainer
@onready var nick_field:   LineEdit      = $PanelContainer/VBox/AuthView/TabContainer/Login/MarginLogin/Fields/NickField
@onready var pass_field:   LineEdit      = $PanelContainer/VBox/AuthView/TabContainer/Login/MarginLogin/Fields/PassField
@onready var btn_login:    Button        = $PanelContainer/VBox/AuthView/TabContainer/Login/MarginLogin/Fields/BtnLogin
@onready var login_error:  Label         = $PanelContainer/VBox/AuthView/TabContainer/Login/MarginLogin/Fields/ErrorLabel

@onready var reg_nick:     LineEdit      = $PanelContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/RegNick
@onready var reg_email:    LineEdit      = $PanelContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/RegEmail
@onready var reg_pass:     LineEdit      = $PanelContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/RegPass
@onready var reg_confirm:  LineEdit      = $PanelContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/RegConfirm
@onready var btn_register: Button        = $PanelContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/BtnRegister
@onready var reg_error:    Label         = $PanelContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/ErrorLabel
@onready var reg_ok:       Label         = $PanelContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/OkLabel

# Común (Botón cerrar - ahora con cruz.jpg)
@onready var btn_close: TextureButton = $PanelContainer/VBox/TopBar/BtnClose

# Cambio de foto de perfil
@onready var avatar_dialog: FileDialog = $AvatarDialog

var default_avatar = load("res://assets/ui/iconos/default_avatar.png")
func _ready() -> void:
	GlobalData.login_success.connect(_on_login_ok)
	GlobalData.login_failed.connect(_on_login_err)
	GlobalData.register_success.connect(_on_register_ok)
	GlobalData.register_failed.connect(_on_register_err)

	btn_close.pressed.connect(func(): close_requested.emit())
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
	
	user_photo.mouse_entered.connect(_on_photo_hover.bind(true))
	user_photo.mouse_exited.connect(_on_photo_hover.bind(false))
	user_photo.gui_input.connect(_on_photo_gui_input)
	
	avatar_dialog.file_selected.connect(_on_avatar_file_selected)

# ── Abrir / cerrar ─────────────────────────────────────────────────────────
func toggle() -> void:
	if visible: _close()
	else: _open()

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

# ── Lógica de Visualización ────────────────────────────────────────────────
func _refresh_view() -> void:
	if GlobalData.is_logged_in:
		nick_label.text  = "Hola, %s!" % GlobalData.user_nickname
		email_label.text = GlobalData.user_email
		_load_user_photo(GlobalData.user_photo_url) # Carga la foto desde la sesión
		profile_view.show()
		auth_view.hide()
	else:
		profile_view.hide()
		auth_view.show()

func _load_user_photo(photo_url: String) -> void:
	if photo_url == null or photo_url.is_empty():
		user_photo.texture = default_avatar
		return
	
	# Si la foto es un string de Base64 (empieza por "data:image")
	if photo_url.begins_with("data:image"):
		var base64_part = photo_url.split(",")[1]
		var buffer = Marshalls.base64_to_raw(base64_part)
		var img = Image.new()
		img.load_png_from_buffer(buffer)
		user_photo.texture = ImageTexture.create_from_image(img)
	elif photo_url.begins_with("res://"):
		user_photo.texture = load(photo_url)
	elif photo_url.begins_with("http"):
		_download_external_image(photo_url)

func _download_external_image(url: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(res, code, hdr, body):
		http.queue_free()
		if code == 200:
			var img = Image.new()
			var err = img.load_png_from_buffer(body) # Prueba PNG primero
			if err != OK: err = img.load_jpg_from_buffer(body)
			if err == OK: user_photo.texture = ImageTexture.create_from_image(img)
	)
	http.request(url)

# ── Login ──────────────────────────────────────────────────────────────────
func _do_login() -> void:
	var nick := nick_field.text.strip_edges()
	var pw   := pass_field.text
	if nick.is_empty() or pw.is_empty():
		_show_err(login_error, "Rellena todos los campos")
		return
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

# Cambia el tono de la foto a gris al pasar el ratón
func _on_photo_hover(is_hover: bool) -> void:
	if is_hover and GlobalData.is_logged_in:
		user_photo.modulate = Color(0.7, 0.7, 0.7) # Filtro gris
	else:
		user_photo.modulate = Color(1, 1, 1) # Normal

# Detecta el clic en la foto
func _on_photo_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if GlobalData.is_logged_in:
			avatar_dialog.popup_centered_ratio(0.5) # Abre la ventana

# Procesa la imagen elegida
func _on_avatar_file_selected(path: String) -> void:
	var img = Image.load_from_file(path)
	if img:
		# IMPORTANTE: Ajustar tamaño para que quepa en la base de datos
		img.resize(256, 256, Image.INTERPOLATE_LANCZOS)
		
		# Convertir a Base64 (Texto) para mandarlo al servidor
		var buffer = img.save_png_to_buffer()
		var base64_str = Marshalls.raw_to_base64(buffer)
		var final_data = "data:image/png;base64," + base64_str
		
		# Actualizar visualmente
		user_photo.texture = ImageTexture.create_from_image(img)
		
		# Guardar en la base de datos a través de GlobalData
		GlobalData.user_photo_url = final_data
		
		# Opcional: Si tienes una función para guardar la partida, llámala aquí
		# get_tree().call_group("main", "save_game_state")
