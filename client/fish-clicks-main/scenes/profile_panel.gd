extends Control

signal close_requested

# ── Nodos de la Interfaz ──────────────────────────────────────────────────
@onready var profile_view: VBoxContainer = $PanelContainer/MarginContainer/VBox/ProfileView
@onready var auth_view:    VBoxContainer = $PanelContainer/MarginContainer/VBox/AuthView

# Elementos del Perfil (Logueado)
@onready var user_photo:   TextureRect   = $PanelContainer/MarginContainer/VBox/ProfileView/MarginProfile/Fields/PhotoFrame/UserPhoto
@onready var nick_label:   Label         = $PanelContainer/MarginContainer/VBox/ProfileView/MarginProfile/Fields/NickLabel
@onready var email_label:  Label         = $PanelContainer/MarginContainer/VBox/ProfileView/MarginProfile/Fields/EmailLabel
@onready var btn_logout:   Button        = $PanelContainer/MarginContainer/VBox/ProfileView/MarginProfile/Fields/BtnLogout

# Elementos de Auth (No logueado)
@onready var tab_container: TabContainer = $PanelContainer/MarginContainer/VBox/AuthView/TabContainer
@onready var nick_field:   LineEdit      = $PanelContainer/MarginContainer/VBox/AuthView/TabContainer/Login/MarginLogin/Fields/NickField
@onready var pass_field:   LineEdit      = $PanelContainer/MarginContainer/VBox/AuthView/TabContainer/Login/MarginLogin/Fields/PassField
@onready var btn_login:    Button        = $PanelContainer/MarginContainer/VBox/AuthView/TabContainer/Login/MarginLogin/Fields/BtnLogin
@onready var login_error:  Label         = $PanelContainer/MarginContainer/VBox/AuthView/TabContainer/Login/MarginLogin/Fields/ErrorLabel

@onready var reg_nick:     LineEdit      = $PanelContainer/MarginContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/RegNick
@onready var reg_email:    LineEdit      = $PanelContainer/MarginContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/RegEmail
@onready var reg_pass:     LineEdit      = $PanelContainer/MarginContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/RegPass
@onready var reg_confirm:  LineEdit      = $PanelContainer/MarginContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/RegConfirm
@onready var btn_register: Button        = $PanelContainer/MarginContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/BtnRegister
@onready var reg_error:    Label         = $PanelContainer/MarginContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/ErrorLabel
@onready var reg_ok:       Label         = $PanelContainer/MarginContainer/VBox/AuthView/TabContainer/Registro/MarginReg/Fields/OkLabel

# Común (Botón cerrar - ahora con cruz.jpg)
@onready var btn_close: TextureButton = $BtnClose

# Foto de perfil
@onready var avatar_dialog: FileDialog = $AvatarDialog

var default_avatar = load("res://assets/ui/iconos/default_avatar.png")
func _ready() -> void:
	GlobalData.login_success.connect(_on_login_ok)
	GlobalData.login_failed.connect(_on_login_err)
	GlobalData.register_success.connect(_on_register_ok)
	GlobalData.register_failed.connect(_on_register_err)
	GlobalData.login_success.connect(func(_d): _refresh_view())
	
	tab_container.tab_changed.connect(_on_tab_changed)
	btn_close.position.y = 96.0 if tab_container.current_tab == 0 else 116.0

	if not GlobalData.profile_updated.is_connected(_refresh_view):
		GlobalData.profile_updated.connect(_refresh_view)

	btn_close.pressed.connect(_on_btn_close_pressed)
	btn_close.mouse_entered.connect(_on_btn_close_mouse_entered)
	btn_close.mouse_exited.connect(_on_btn_close_mouse_exited)
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
	if user_photo:
		# Habilitamos que el ratón no traspase la imagen
		user_photo.mouse_filter = Control.MOUSE_FILTER_STOP 
		
		# EFECTO GRISÁCEO
		user_photo.mouse_entered.connect(func():
			user_photo.modulate = Color(0.6, 0.6, 0.6, 1.0) # Tinte oscuro
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		)
		user_photo.mouse_exited.connect(func():
			user_photo.modulate = Color.WHITE # Color normal
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		)
		
		# CLIC PARA CAMBIAR FOTO
		user_photo.gui_input.connect(_on_photo_gui_input)

	if avatar_dialog:
		avatar_dialog.file_selected.connect(_on_avatar_selected)

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
	hide()
	close_requested.emit()

# ── Lógica de Visualización ────────────────────────────────────────────────
func _refresh_view() -> void:
	if GlobalData.is_logged_in:
		nick_label.text = "Hola, %s!" % GlobalData.user_nickname
		email_label.text = GlobalData.user_email

		var photo := "" if GlobalData.user_photo_url == null else str(GlobalData.user_photo_url)
		_load_user_photo(photo)

		profile_view.show()
		auth_view.hide()
	else:
		profile_view.hide()
		auth_view.show()

func _load_user_photo(photo_url: String) -> void:
	if photo_url == null or photo_url.is_empty():
		user_photo.texture = default_avatar
		return
	
	if photo_url.begins_with("res://"):
		user_photo.texture = load(photo_url)
	elif photo_url.begins_with("http"):
		_download_external_image(photo_url)
	else:
		var raw_data = Marshalls.base64_to_raw(photo_url)
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
				# Si por alguna razón la extensión falla, intentamos ambos (fallback)
				err = img.load_png_from_buffer(raw_data)
				if err != OK: err = img.load_jpg_from_buffer(raw_data)
			# ------------------------------------------------
			
			if err == OK:
				img.convert(Image.FORMAT_RGBA8) 
				user_photo.texture = ImageTexture.create_from_image(img)
				return
		
		user_photo.texture = default_avatar

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
	if get_tree().has_group("main"):
		get_tree().call_group("main", "reset_local_state")

# ── Utilidades ─────────────────────────────────────────────────────────────
func _show_err(lbl: Label, msg: String) -> void:
	lbl.text = msg
	lbl.modulate = Color.INDIAN_RED # Cambia a un rojo suave
	lbl.show()
	
	# Pequeña animación de "sacudida" para llamar la atención
	var tw = create_tween()
	var original_pos = lbl.position
	tw.tween_property(lbl, "position:x", original_pos.x + 5, 0.05)
	tw.tween_property(lbl, "position:x", original_pos.x - 5, 0.1)
	tw.tween_property(lbl, "position:x", original_pos.x, 0.05)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close()
		
func _on_photo_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if avatar_dialog:
			avatar_dialog.popup_centered_ratio(0.5)

func _on_btn_close_pressed() -> void:
	# Buscamos la escena principal (Main) para usar su ui_manager
	var main = get_tree().get_first_node_in_group("main")
	if main and main.ui_manager:
		main.ui_manager.play_squish(btn_close) # <--- Aquí ocurre el "salto"
	
	_close() # Ejecuta tu animación de desvanecimiento


func _on_avatar_selected(path: String) -> void:
	var img = Image.load_from_file(path)
	if img:
		img.convert(Image.FORMAT_RGBA8)
		img.resize(128, 128, Image.INTERPOLATE_LANCZOS)
		
		var ext = path.get_extension().to_lower()
		if ext != "png" and ext != "jpg" and ext != "jpeg":
			ext = "png" # Fallback por seguridad
			
		var buffer = img.save_png_to_buffer() if ext == "png" else img.save_jpg_to_buffer()
		var b64 = Marshalls.raw_to_base64(buffer)
		
		# Enviamos ambos datos al servidor
		GlobalData.upload_user_photo(b64, ext)

func _on_btn_close_mouse_entered() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(btn_close, "scale", Vector2(1.08, 1.08), 0.08)
	tween.parallel().tween_property(btn_close, "modulate", Color(0.85, 0.85, 0.85, 1.0), 0.08)

func _on_btn_close_mouse_exited() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(btn_close, "scale", Vector2.ONE, 0.08)
	tween.parallel().tween_property(btn_close, "modulate", Color(1, 1, 1, 1), 0.08)

func _on_tab_changed(tab: int) -> void:
	# 0 es Login, 1 es Registro
	btn_close.position.y = 96.0 if tab == 0 else 116.0
