extends Control

signal auth_success(token: String, user_id: String)
signal auth_error(message: String)

@export var backend_base_url: String = "http://localhost:8080"

@onready var email_input: LineEdit = $EmailInput
@onready var nickname_input: LineEdit = $NicknameInput
@onready var password_input: LineEdit = $PasswordInput
@onready var btn_login: Button = $BtnLogin
@onready var btn_register: Button = $BtnRegister
@onready var btn_close: Button = $BtnClose
@onready var lbl_status: Label = $LblStatus
@onready var http_request: HTTPRequest = $HTTPRequest

enum RequestMode { NONE, LOGIN, REGISTER }
var _request_mode: int = RequestMode.NONE

var token: String = ""
var user_id: String = ""

func _ready() -> void:
	visible = false
	lbl_status.text = ""
	password_input.secret = true

	btn_login.pressed.connect(_on_btn_login_pressed)
	btn_register.pressed.connect(_on_btn_register_pressed)
	btn_close.pressed.connect(_on_btn_close_pressed)
	http_request.request_completed.connect(_on_request_completed)

func open() -> void:
	visible = true
	lbl_status.text = ""
	password_input.text = ""
	email_input.grab_focus()

func close() -> void:
	visible = false

func toggle() -> void:
	visible = !visible
	if visible:
		open()

func is_logged_in() -> bool:
	return token != ""

func logout() -> void:
	token = ""
	user_id = ""
	lbl_status.text = "Sesion cerrada"

func _on_btn_login_pressed() -> void:
	var identifier := nickname_input.text.strip_edges()
	if identifier == "":
		identifier = email_input.text.strip_edges()

	var password := password_input.text
	if identifier == "" or password == "":
		_set_error("Pon nickname/email y contrasena")
		return

	var payload := {
		"nickname": identifier,
		"password": password
	}

	_request_mode = RequestMode.LOGIN
	_send_request("/auth/login", payload)

func _on_btn_register_pressed() -> void:
	var email := email_input.text.strip_edges()
	var nickname := nickname_input.text.strip_edges()
	var password := password_input.text

	if email == "" or nickname == "" or password == "":
		_set_error("Pon email, nickname y contrasena")
		return

	var payload := {
		"email": email,
		"nickname": nickname,
		"password": password
	}

	_request_mode = RequestMode.REGISTER
	_send_request("/auth/register", payload)

func _on_btn_close_pressed() -> void:
	close()

func _send_request(path: String, payload: Dictionary) -> void:
	lbl_status.text = "Enviando..."
	var url := backend_base_url + path
	var headers := PackedStringArray(["Content-Type: application/json"])
	var body := JSON.stringify(payload)

	var err := http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		_set_error("No se pudo enviar la peticion")

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var text := body.get_string_from_utf8()

	if response_code != 200:
		_set_error("Error %s" % response_code)
		if text != "":
			print("Auth error body: ", text)
		return

	var json := JSON.new()
	if json.parse(text) != OK:
		_set_error("Respuesta JSON invalida")
		return

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		_set_error("Respuesta inesperada")
		return

	var new_token := str(data.get("token", ""))
	var new_user_id := str(data.get("userId", ""))

	if new_token == "" or new_user_id == "":
		_set_error("Faltan token/userId")
		return

	token = new_token
	user_id = new_user_id
	lbl_status.text = "OK"

	emit_signal("auth_success", token, user_id)
	close()

func _set_error(msg: String) -> void:
	lbl_status.text = msg
	emit_signal("auth_error", msg)
