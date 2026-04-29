extends Node

# ── Sesión ──────────────────────────────────────────
var user_token: String = ""
var user_id: String = ""      # UUID del backend (era int, cambiado a String)
var user_email: String = ""
var user_nickname: String = ""
var is_logged_in: bool = false

const SESSION_FILE = "user://fish_clicks_session.save"
#const BASE_URL = "http://127.0.0.1:8080"
const BASE_URL = "https://fish-clicks.onrender.com"

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
	# 1) Error de red (Capa física/transporte)
	if result != HTTPRequest.RESULT_SUCCESS:
		return _http_result_to_text(result)

	# 2) Intentar obtener el mensaje específico del servidor si existe
	var raw := body.get_string_from_utf8()
	var data = JSON.parse_string(raw)
	var server_detail = ""
	
	if data is Dictionary:
		# Buscamos en las claves comunes de error de los frameworks de backend
		server_detail = data.get("message", data.get("error", data.get("detail", "")))

	# 3) Mapeo de errores por Código HTTP
	match code:
		400:
			return "Solicitud inválida. Revisa los datos introducidos."
		401:
			return "La contraseña es incorrecta."
		403:
			return "No tienes permiso para acceder a este recurso."
		404:
			return "El nombre de usuario no existe."
		409:
			# Generalmente usado en el registro para duplicados
			return "El nombre de usuario o el email ya están en uso."
		422:
			return "Datos no procesables (posible formato de email incorrecto)."
		500, 502, 503, 504:
			return "El servidor tiene problemas técnicos. Inténtalo más tarde."
	
	# 4) Fallback: Si el servidor envió un texto útil, lo usamos, si no, el default
	if server_detail != "":
		return str(server_detail)
		
	return "%s (Error %d)" % [default_msg, code]



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
	var raw_body = body.get_string_from_utf8()
	var data = JSON.parse_string(raw_body)

	if result == HTTPRequest.RESULT_SUCCESS and code == 200 and data is Dictionary:
		
		# Forzamos que los valores sean String para evitar el error de tipo Nil
		var token = str(data.get("token", ""))
		var uid = str(data.get("userId", ""))
		var nick = str(data.get("nickname", nickname))
		var email = str(data.get("email", ""))
		var foto = str(data.get("foto", ""))
		var ext = str(data.get("extension", "png")) # Si es nulo, ponemos "png" por defecto

		set_user_session(token, uid, nick, email, foto, ext)
		
		login_success.emit(data)
		load_game()
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
var user_photo_extension: String = ""


func set_user_session(token: String, uid: String, nickname: String, email: String, photo: String, extension: String) -> void:
	user_token = token
	user_id = uid
	user_nickname = nickname
	user_email = email
	user_photo_url = photo
	user_photo_extension = extension if not extension.is_empty() else "png"
	is_logged_in = true
	_save_session()
	# No hace falta emitir aquí si ya lo haces en _on_login_done

func clear_session() -> void:
	user_token    = ""
	user_id       = ""
	user_email    = ""
	user_nickname = ""
	user_photo_url = ""
	is_logged_in  = false
	if FileAccess.file_exists(SESSION_FILE):
		DirAccess.remove_absolute(SESSION_FILE)

	if get_tree().has_group("main_hud_buttons"):
		get_tree().call_group("main_hud_buttons", "update_avatar")

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
			"photo":    user_photo_url,
			"extension": user_photo_extension
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
				user_photo_url = d.get("photo",    "")
				user_photo_extension = d.get("extension", "png")
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

func upload_user_photo(base64_data: String, extension: String) -> void:
	if not is_logged_in: return

	var http := HTTPRequest.new()
	add_child(http)

	# Ahora enviamos tanto la foto como la extensión en el JSON
	var body = JSON.stringify({
		"foto": base64_data,
		"extension": extension
	})
	
	var headers = [
		"Content-Type: application/json",
		"Authorization: " + get_auth_header()
	]

	http.request(BASE_URL + "/auth/update-photo", headers, HTTPClient.METHOD_POST, body)

	# ACTUALIZACIÓN LOCAL
	user_photo_url = base64_data
	user_photo_extension = extension # Guardamos la extensión para que BtnProfile sepa qué cargar
	_save_session()
	
# --- RANKING ---
signal ranking_received(type: String, data: Array)
signal ranking_failed(error: String)

func fetch_ranking(type: String) -> void:
	var url = BASE_URL + "/ranking?type=" + type
	var headers = ["Content-Type: application/json"]
	
	# Solo añadimos el token si el usuario está logueado
	if is_logged_in:
		headers.append("Authorization: " + get_auth_header())
	
	# Realizamos la petición HTTP normal
	var http := HTTPRequest.new()
	add_child(http)
	
	http.request_completed.connect(func(result, code, headers, body):
		http.queue_free()
		if code == 200:
			var data = JSON.parse_string(body.get_string_from_utf8())
			if data is Array:
				ranking_received.emit(type, data)
		else:
			ranking_failed.emit("Error servidor: " + str(code))
	)
	http.request(url, headers, HTTPClient.METHOD_GET)

var pending_runtime_state: Dictionary = {}
var pending_alien_result: Dictionary = {}
var pending_abducted_fish_snapshots: Array[Dictionary] = []

func set_pending_abducted_fish_snapshots(snapshots: Array[Dictionary]) -> void:
	pending_abducted_fish_snapshots = snapshots.duplicate(true)

func consume_pending_abducted_fish_snapshots() -> Array[Dictionary]:
	var out := pending_abducted_fish_snapshots.duplicate(true)
	pending_abducted_fish_snapshots.clear()
	return out

func set_pending_runtime_state(state: Dictionary) -> void:
	pending_runtime_state = state.duplicate(true)

func consume_pending_runtime_state() -> Dictionary:
	var out := pending_runtime_state.duplicate(true)
	pending_runtime_state.clear()
	return out

func set_pending_alien_result(result: Dictionary) -> void:
	pending_alien_result = result.duplicate(true)

func consume_pending_alien_result() -> Dictionary:
	var out := pending_alien_result.duplicate(true)
	pending_alien_result.clear()
	return out

var pending_abduct_return_origin: Vector2 = Vector2.ZERO
var alien_last_minigame_trigger_unix: float = -1.0

func set_pending_abduct_return_origin(origin: Vector2) -> void:
	pending_abduct_return_origin = origin

func consume_pending_abduct_return_origin() -> Vector2:
	var out := pending_abduct_return_origin
	pending_abduct_return_origin = Vector2.ZERO
	return out

var pending_minigame_display_fish_data: Array[Dictionary] = []
var pending_auspezio_level: int = 0

func set_pending_minigame_display_fish_data(data: Array[Dictionary]) -> void:
	pending_minigame_display_fish_data = data.duplicate(true)

func consume_pending_minigame_display_fish_data() -> Array[Dictionary]:
	var data := pending_minigame_display_fish_data.duplicate(true)
	pending_minigame_display_fish_data.clear()
	return data

func set_pending_auspezio_level(level: int) -> void:
	pending_auspezio_level = level


func consume_pending_auspezio_level() -> int:
	var level := pending_auspezio_level
	pending_auspezio_level = 0
	return level
