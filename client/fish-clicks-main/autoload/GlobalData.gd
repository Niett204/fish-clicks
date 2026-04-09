extends Node

# ── Sesión ──────────────────────────────────────────
var user_token: String = ""
var user_id: String = ""      # UUID del backend (era int, cambiado a String)
var user_email: String = ""
var user_nickname: String = ""
var is_logged_in: bool = false

const SESSION_FILE = "user://fish_clicks_session.save"
const BASE_URL = "http://127.0.0.1:8080"

signal login_success(data: Dictionary)
signal login_failed(error: String)
signal register_success
signal register_failed(error: String)

func _http_result_to_text(result: int) -> String:
	match result:
		HTTPRequest.RESULT_SUCCESS:
			return ""
		HTTPRequest.RESULT_CANT_CONNECT:
			return "No se puede conectar con el servidor"
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "No se puede resolver el dominio del servidor"
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return "Error de conexion con el servidor"
		HTTPRequest.RESULT_TIMEOUT:
			return "Tiempo de espera agotado al conectar con el servidor"
		_:
			return "Error de red (codigo %d)" % result


func _build_error_message(result: int, code: int, body: PackedByteArray, default_msg: String) -> String:
	# 1) Error de red (no llego respuesta HTTP valida)
	if result != HTTPRequest.RESULT_SUCCESS:
		return _http_result_to_text(result)

	# 2) Intentar leer JSON del backend
	var raw := body.get_string_from_utf8()
	var data = JSON.parse_string(raw)

	if data is Dictionary:
		# Prioridad: message -> error -> detail
		var message := str(data.get("message", "")).strip_edges()
		if message != "":
			return "%s (HTTP %d)" % [message, code]

		var error_text := str(data.get("error", "")).strip_edges()
		if error_text != "":
			return "%s (HTTP %d)" % [error_text, code]

		var detail := str(data.get("detail", "")).strip_edges()
		if detail != "":
			return "%s (HTTP %d)" % [detail, code]

	# 3) Fallback por codigo HTTP
	match code:
		400:
			return "Datos invalidos (HTTP 400)"
		401:
			return "Credenciales incorrectas (HTTP 401)"
		403:
			return "Acceso denegado (HTTP 403)"
		404:
			return "Endpoint no encontrado (HTTP 404)"
		409:
			return "El usuario o email ya existe (HTTP 409)"
		422:
			return "No se pudo procesar la solicitud (HTTP 422)"
		500:
			return "Error interno del servidor (HTTP 500)"
		502, 503, 504:
			return "Servidor no disponible temporalmente (HTTP %d)" % code
		_:
			return "%s (HTTP %d)" % [default_msg, code]



func _ready() -> void:
	_load_session()


# ── HTTP: Login ─────────────────────────────────────
# POST /auth/login  { nickname, password }
# Respuesta: { token, userId }
func login(nickname: String, password: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_login_done.bind(http, nickname))
	var body := JSON.stringify({"nickname": nickname, "password": password})
	http.request(BASE_URL + "/auth/login", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)

func _on_login_done(result, code: int, _headers, body: PackedByteArray, http: HTTPRequest, nickname: String) -> void:
	http.queue_free()
	var data = JSON.parse_string(body.get_string_from_utf8())

	if result == HTTPRequest.RESULT_SUCCESS and code == 200 and data is Dictionary:
		set_user_session(
			data.get("token", ""), 
			data.get("userId", ""), 
			data.get("nickname", nickname),
			data.get("email", ""),
			data.get("foto", "")
		)
		login_success.emit(data)
	else:
		var msg := _build_error_message(result, code, body, "No se pudo iniciar sesion")
		login_failed.emit(msg)



# ── HTTP: Register ──────────────────────────────────
# POST /auth/register  { email, nickname, password }
# Respuesta: { token, userId }
func register(email: String, nickname: String, password: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_register_done.bind(http))
	var body := JSON.stringify({"email": email, "nickname": nickname, "password": password})
	http.request(BASE_URL + "/auth/register", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)

func _on_register_done(result, code: int, _headers, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	var data = JSON.parse_string(body.get_string_from_utf8())

	if result == HTTPRequest.RESULT_SUCCESS and code in [200, 201] and data is Dictionary:
		# Si quieres auto-login tras registro:
		# set_user_session(data.get("token", ""), data.get("userId", ""), "")
		register_success.emit()
	else:
		var msg := _build_error_message(result, code, body, "No se pudo completar el registro")
		register_failed.emit(msg)



# ── Sesión ──────────────────────────────────────────
var user_photo_url: String = ""

func set_user_session(token: String, uid: String, nickname: String, email: String, photo: String) -> void:
	user_token    = token
	user_id       = uid
	user_nickname = nickname
	user_email    = email
	user_photo_url = photo # Asegúrate de tener esta variable declarada arriba
	is_logged_in  = true
	_save_session()

func clear_session() -> void:
	user_token    = ""
	user_id       = ""
	user_email    = ""
	user_nickname = ""
	is_logged_in  = false
	if FileAccess.file_exists(SESSION_FILE):
		DirAccess.remove_absolute(SESSION_FILE)

func get_auth_header() -> String:
	return "Bearer " + user_token

func _save_session() -> void:
	var file := FileAccess.open(SESSION_FILE, FileAccess.WRITE)
	if file:
		file.store_var({
			"token":    user_token,
			"user_id":  user_id,
			"email":    user_email,
			"nickname": user_nickname,
			"photo":    user_photo_url # Guardamos la foto en el disco
		})

func _load_session() -> void:
	if FileAccess.file_exists(SESSION_FILE):
		var file := FileAccess.open(SESSION_FILE, FileAccess.READ)
		if file:
			var d = file.get_var()
			if d and d.has("token") and not d["token"].is_empty():
				user_token    = d.get("token",    "")
				user_id       = d.get("user_id",  "")
				user_email    = d.get("email",    "")
				user_nickname = d.get("nickname", "")
				user_photo_url = d.get("photo",    "") # Cargamos la foto guardada
				is_logged_in  = true


# ── GUARDADO DE PARTIDA ─────────────────────────────────────────────────────
# POST /partida/guardar  (requiere JWT)
# Body: { "state": { ...json del juego... } }

signal save_success
signal save_failed(error: String)
signal load_success(state: Dictionary)
signal load_failed(error: String)


func save_game(state: Dictionary) -> void:
	print("Token JWT:", user_token)
	if not is_logged_in:
		save_failed.emit("Debes iniciar sesión para guardar")
		return

	var http := HTTPRequest.new()
	# Necesitamos un nodo en el árbol — usamos el autoload mismo
	add_child(http)
	http.request_completed.connect(_on_save_done.bind(http))

	var body := JSON.stringify(state)
	var headers := [
		"Content-Type: application/json",
		"Authorization: " + get_auth_header()
	]
	http.request(BASE_URL + "/partida/guardar", headers, HTTPClient.METHOD_POST, body)


func _on_save_done(_result, code: int, _headers, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if code in [200, 201]:
		save_success.emit()
	else:
		print("HTTP Error Code: ", code)
		print("Response body: ", body.get_string_from_utf8())
		var data = JSON.parse_string(body.get_string_from_utf8())
		var msg := "Error al guardar"
		if data is Dictionary:
			msg = data.get("message", msg)
		save_failed.emit(msg)


func load_game() -> void:
	if not is_logged_in:
		load_failed.emit("Debes iniciar sesión para cargar")
		return

	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_load_done.bind(http))

	var headers := [
		"Content-Type: application/json",
		"Authorization: " + get_auth_header()
	]
	http.request(BASE_URL + "/partida/cargar", headers, HTTPClient.METHOD_GET)


func _on_load_done(_result, code: int, _headers, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if code == 200:
		var data = JSON.parse_string(body.get_string_from_utf8())
		if data is Dictionary and data.has("state"):
			# IMPORTANTE: El state llega como String desde el backend, 
			# debemos convertirlo a Diccionario antes de enviarlo al juego.
			var raw_state = data["state"]
			var parsed_state = raw_state
			
			if raw_state is String:
				parsed_state = JSON.parse_string(raw_state)
			
			if parsed_state is Dictionary:
				load_success.emit(parsed_state)
			else:
				load_failed.emit("Error: El estado de la partida no es un JSON válido")
		else:
			load_failed.emit("Respuesta inesperada del servidor")
	elif code == 404:
		load_failed.emit("No hay partida guardada")
	else:
		load_failed.emit("Error al cargar la partida")
