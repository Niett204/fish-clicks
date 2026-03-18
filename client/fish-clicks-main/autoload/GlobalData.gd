extends Node

# Variables de sesión del usuario
var user_token: String = ""
var user_id: int = 0
var user_email: String = ""
var is_logged_in: bool = false

# Ruta del archivo de sesión (opcional - para persistencia)
const SESSION_FILE = "user://fish_clicks_session.save"

func _ready():
	# Cargar sesión guardada si existe
	_load_session()

# Establecer la sesión del usuario después del login
func set_user_session(token: String, user_id: int, email: String) -> bool:
	if token.is_empty() or user_id <= 0 or email.is_empty():
		return false

	self.user_token = token
	self.user_id = user_id
	self.user_email = email
	self.is_logged_in = true

	# Guardar sesión (opcional)
	_save_session()

	return true

# Limpiar sesión al cerrar sesión
func clear_session():
	user_token = ""
	user_id = 0
	user_email = ""
	is_logged_in = false

	# Borrar archivo de sesión
	if ResourceLoader.exists(SESSION_FILE):
		DirAccess.remove_absolute(SESSION_FILE)

# Obtener el header de autorización para las peticiones
func get_auth_header() -> String:
	return "Bearer " + user_token

# Guardar sesión en disco
func _save_session():
	var session_data = {
		"token": user_token,
		"user_id": user_id,
		"user_email": user_email
	}

	var file = FileAccess.open(SESSION_FILE, FileAccess.WRITE)
	if file:
		file.store_var(session_data)

# Cargar sesión desde disco
func _load_session():
	if ResourceLoader.exists(SESSION_FILE):
		var file = FileAccess.open(SESSION_FILE, FileAccess.READ)
		if file:
			var session_data = file.get_var()
			if session_data and session_data.has("token"):
				user_token = session_data.get("token", "")
				user_id = session_data.get("user_id", 0)
				user_email = session_data.get("user_email", "")
				is_logged_in = not user_token.is_empty()

