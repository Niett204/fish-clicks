extends Control

@onready var email_input: LineEdit = $PergaminoPanel/MarginContainer/VBoxContainer/EmailContainer/EmailInput
@onready var password_input: LineEdit = $PergaminoPanel/MarginContainer/VBoxContainer/PasswordContainer/PasswordInput
@onready var status_label: Label = $PergaminoPanel/MarginContainer/VBoxContainer/StatusLabel
@onready var btn_login: Button = $PergaminoPanel/MarginContainer/VBoxContainer/ButtonContainer/BtnLogin
@onready var http_request: HTTPRequest = $HTTPRequest

# Cambiar a tu IP/dominio del servidor
const BACKEND_URL = "http://localhost:8080/auth/login"

var login_in_progress: bool = false

func _ready():
	# Conectar señales
	http_request.request_completed.connect(_on_http_request_completed)

	# Hacer que se cierre con ESC
	get_tree().root.gui_embed_subwindows = false

func _on_btn_login_pressed():
	if login_in_progress:
		return

	var email = email_input.text.strip_edges()
	var password = password_input.text

	# Validaciones básicas
	if email.is_empty():
		_show_error("Por favor ingresa un correo")
		return

	if password.is_empty():
		_show_error("Por favor ingresa una contraseña")
		return

	# Preparar solicitud HTTP
	login_in_progress = true
	btn_login.disabled = true
	status_label.text = "Conectando..."
	status_label.modulate = Color.YELLOW

	var headers = ["Content-Type: application/json"]
	var body = {
		"email": email,
		"password": password
	}

	var json_string = JSON.stringify(body)

	http_request.request(BACKEND_URL, headers, HTTPClient.METHOD_POST, json_string)

func _on_btn_cancel_pressed():
	if not login_in_progress:
		queue_free()

func _on_http_request_completed(result, response_code, headers, body):
	login_in_progress = false
	btn_login.disabled = false

	if response_code == 200:
		# Éxito en el login
		var response_string = body.get_string_from_utf8()
		var json = JSON.new()
		var response_data = json.parse_string(response_string)

		if response_data:
			var token = response_data.get("token", "")
			var user_id = response_data.get("userId", 0)

			# Guardar datos en memoria (puedes usar un Autoload)
			if GlobalData.set_user_session(token, user_id, email_input.text):
				_show_success("¡Inicio de sesión exitoso!")
				await get_tree().create_timer(1.0).timeout
				queue_free()
			else:
				_show_error("Error al guardar sesión")
		else:
			_show_error("Respuesta inválida del servidor")
	else:
		# Error en el login
		var error_message = body.get_string_from_utf8()

		if response_code == 500:
			_show_error("Usuario no encontrado o contraseña incorrecta")
		elif response_code == 0:
			_show_error("No se pudo conectar con el servidor")
		else:
			_show_error("Error: Código %d" % response_code)

		# Limpiar campos de contraseña
		password_input.text = ""

func _show_error(message: String):
	status_label.text = message
	status_label.modulate = Color.RED

func _show_success(message: String):
	status_label.text = message
	status_label.modulate = Color.GREEN

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if not login_in_progress:
				queue_free()
				get_tree().root.set_input_as_handled()
		elif event.keycode == KEY_ENTER:
			if not login_in_progress and not email_input.text.is_empty() and not password_input.text.is_empty():
				_on_btn_login_pressed()
				get_tree().root.set_input_as_handled()

