extends Node

# Este es un archivo de EJEMPLO mostrando cómo usar GlobalData en otros scripts
# Cópialo y adáptalo según tus necesidades

@onready var http_request: HTTPRequest = HTTPRequest.new()

func _ready():
	add_child(http_request)
	http_request.request_completed.connect(_on_http_request_completed)

	# Ejemplo 1: Verificar si el usuario está logueado
	if GlobalData.is_logged_in:
		print("✓ Usuario logueado: ", GlobalData.user_email)
		print("✓ ID Usuario: ", GlobalData.user_id)
	else:
		print("✗ No hay sesión activa")

# Ejemplo 2: Hacer una petición autenticada al backend
func fetch_user_profile():
	if not GlobalData.is_logged_in:
		print("Error: No hay sesión activa")
		return

	var url = "http://localhost:8080/api/user/profile"
	var headers = [
		"Content-Type: application/json",
		"Authorization: " + GlobalData.get_auth_header()
	]

	print("Obteniendo perfil del usuario...")
	http_request.request(url, headers, HTTPClient.METHOD_GET)

# Ejemplo 3: Obtener datos de la tienda (probablemente protegido)
func fetch_shop_items():
	if not GlobalData.is_logged_in:
		print("Error: Debes iniciar sesión para acceder a la tienda")
		return

	var url = "http://localhost:8080/api/shop/items"
	var headers = [
		"Content-Type: application/json",
		"Authorization: " + GlobalData.get_auth_header()
	]

	print("Obteniendo items de la tienda...")
	http_request.request(url, headers, HTTPClient.METHOD_GET)

# Ejemplo 4: Cerrar sesión del usuario
func logout():
	print("Cerrando sesión...")
	GlobalData.clear_session()
	print("✓ Sesión cerrada")
	# Opcionalmente, recargar la escena principal
	# get_tree().reload_current_scene()

# Manejar respuestas HTTP
func _on_http_request_completed(result, response_code, headers, body):
	var response_text = body.get_string_from_utf8()

	print("Respuesta del servidor:")
	print("  Código: ", response_code)
	print("  Cuerpo: ", response_text)

	match response_code:
		200:
			# Éxito
			var data = JSON.parse_string(response_text)
			print("✓ Respuesta exitosa: ", data)
		401:
			# Token expirado o inválido
			print("✗ Error de autenticación")
			print("✗ Token expirado, necesita login de nuevo")
			GlobalData.clear_session()
		404:
			# No encontrado
			print("✗ Recurso no encontrado")
		500:
			# Error del servidor
			print("✗ Error del servidor")
		_:
			# Otros errores
			print("✗ Error desconocido: ", response_code)

# Ejemplo 5: Guardar datos del usuario localmente
func save_user_data():
	if GlobalData.is_logged_in:
		var user_data = {
			"email": GlobalData.user_email,
			"user_id": GlobalData.user_id,
			"last_login": Time.get_ticks_msec()
		}
		print("Datos guardados: ", user_data)

# Ejemplo 6: Verificar si el token es válido antes de hacer una petición
func is_session_valid() -> bool:
	if not GlobalData.is_logged_in:
		return false

	if GlobalData.user_token.is_empty():
		return false

	if GlobalData.user_id <= 0:
		return false

	return true

# Ejemplo 7: Mostrar el token (solo para debugging)
func debug_show_token():
	if GlobalData.is_logged_in:
		print("Token actual: ", GlobalData.user_token)
		print("Auth Header: ", GlobalData.get_auth_header())
	else:
		print("No hay token")

