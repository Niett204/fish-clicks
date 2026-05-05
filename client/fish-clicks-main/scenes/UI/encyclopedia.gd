extends Control
signal close_requested
signal page_changed
signal category_changed

@onready var http_request: HTTPRequest = $HTTPRequest
@onready var rareza_container: VBoxContainer = $FondoLibro/RarezaPanel/RarezaContainer

@onready var tag_bg_izq: TextureRect = $FondoLibro/ContenedorLibro/PaginaIzq/MarginIzq/VBoxIzq/tag_bg_izq
@onready var tag_rareza_izq: Label = $FondoLibro/ContenedorLibro/PaginaIzq/MarginIzq/VBoxIzq/tag_bg_izq/TagRarezaIzq
@onready var pez_izq: TextureRect = $FondoLibro/ContenedorLibro/PaginaIzq/MarginIzq/VBoxIzq/marco_pez_izq/PezIzq
@onready var nombre_izq: Label = $FondoLibro/ContenedorLibro/PaginaIzq/MarginIzq/VBoxIzq/NombrePezIzq
@onready var descripcion_izq: RichTextLabel = $FondoLibro/ContenedorLibro/PaginaIzq/MarginIzq/VBoxIzq/DescripcionIzq
@onready var stat_izq: Label = $FondoLibro/ContenedorLibro/PaginaIzq/MarginIzq/VBoxIzq/HBoxIzq/tag_bg_izq2/StatIzq
@onready var habitat_izq: Label = $FondoLibro/ContenedorLibro/PaginaIzq/MarginIzq/VBoxIzq/HBoxIzq/tag_bg_izq3/HabitatIzq
@onready var marco_pez_izq: TextureRect = $FondoLibro/ContenedorLibro/PaginaIzq/MarginIzq/VBoxIzq/marco_pez_izq
@onready var tag_bg_izq2: TextureRect = $FondoLibro/ContenedorLibro/PaginaIzq/MarginIzq/VBoxIzq/HBoxIzq/tag_bg_izq2
@onready var tag_bg_izq3: TextureRect = $FondoLibro/ContenedorLibro/PaginaIzq/MarginIzq/VBoxIzq/HBoxIzq/tag_bg_izq3

@onready var tag_bg_der: TextureRect = $FondoLibro/ContenedorLibro/PaginaDer/MarginDer/VBoxDer/tag_bg_der
@onready var tag_rareza_der: Label = $FondoLibro/ContenedorLibro/PaginaDer/MarginDer/VBoxDer/tag_bg_der/TagRarezaDer
@onready var pez_der: TextureRect = $FondoLibro/ContenedorLibro/PaginaDer/MarginDer/VBoxDer/marco_pez_der/PezDer
@onready var nombre_der: Label = $FondoLibro/ContenedorLibro/PaginaDer/MarginDer/VBoxDer/NombrePezDer
@onready var descripcion_der: RichTextLabel = $FondoLibro/ContenedorLibro/PaginaDer/MarginDer/VBoxDer/DescripcionDer
@onready var stat_der: Label = $FondoLibro/ContenedorLibro/PaginaDer/MarginDer/VBoxDer/HBoxDer/tag_bg_der2/StatDer
@onready var habitat_der: Label = $FondoLibro/ContenedorLibro/PaginaDer/MarginDer/VBoxDer/HBoxDer/tag_bg_der3/HabitatDer
@onready var marco_pez_der: TextureRect = $FondoLibro/ContenedorLibro/PaginaDer/MarginDer/VBoxDer/marco_pez_der
@onready var tag_bg_der2: TextureRect = $FondoLibro/ContenedorLibro/PaginaDer/MarginDer/VBoxDer/HBoxDer/tag_bg_der2
@onready var tag_bg_der3: TextureRect = $FondoLibro/ContenedorLibro/PaginaDer/MarginDer/VBoxDer/HBoxDer/tag_bg_der3

@onready var btn_anterior: TextureButton = $BtnAnterior
@onready var btn_siguiente: TextureButton = $BtnSiguiente
@onready var btn_salir: TextureButton = $BtnSalir

@onready var pagina_izq_contenido: VBoxContainer = $FondoLibro/ContenedorLibro/PaginaIzq/MarginIzq/VBoxIzq
@onready var pagina_der_contenido: VBoxContainer = $FondoLibro/ContenedorLibro/PaginaDer/MarginDer/VBoxDer

const BUTTON_MODULATE_NORMAL := Color(1.0, 1.0, 1.0, 1.0)
const BUTTON_MODULATE_HOVER := Color(0.85, 0.85, 0.85, 1.0)
const BUTTON_MODULATE_PRESSED := Color(0.65, 0.65, 0.65, 1.0)

const NAV_HOVER_OFFSET := 6.0
const NAV_PRESSED_OFFSET := 2.0

var fishes: Array = []
var current_page: int = 0
var rareza_actual: String = ""
var rarezas_disponibles: Array = []

var pez_ids_desbloqueados: Array[int] = []

enum RequestMode {
	LOAD_ALL_FOR_RAREZAS,
	LOAD_FILTERED_FISHES
}

var request_mode: int = RequestMode.LOAD_ALL_FOR_RAREZAS
var request_en_curso: bool = false

func _ready() -> void:
	visible = false

	http_request.request_completed.connect(_on_request_completed)
	btn_anterior.pressed.connect(_on_btn_anterior_pressed)
	btn_siguiente.pressed.connect(_on_btn_siguiente_pressed)

	_configurar_boton_navegacion(btn_anterior, -1)
	_configurar_boton_navegacion(btn_siguiente, 1)

	btn_salir.pressed.connect(_on_btn_salir_pressed)
	_configurar_boton_salir(btn_salir)

	limpiar_pagina(true)
	limpiar_pagina(false)
	_set_pagina_visible(true, false)
	_set_pagina_visible(false, false)
	btn_anterior.visible = false
	btn_siguiente.visible = false
	
func _on_btn_salir_pressed() -> void:
	close_requested.emit()
	
func _configurar_boton_salir(btn: TextureButton) -> void:
	var pos_original: Vector2 = btn.position

	btn.modulate = BUTTON_MODULATE_NORMAL

	btn.mouse_entered.connect(func():
		btn.modulate = BUTTON_MODULATE_HOVER
		btn.position = pos_original + Vector2(0, -3)
	)

	btn.mouse_exited.connect(func():
		btn.modulate = BUTTON_MODULATE_NORMAL
		btn.position = pos_original
	)

	btn.button_down.connect(func():
		btn.modulate = BUTTON_MODULATE_PRESSED
		btn.position = pos_original + Vector2(0, -1)
	)

	btn.button_up.connect(func():
		if btn.get_rect().has_point(btn.get_local_mouse_position()):
			btn.modulate = BUTTON_MODULATE_HOVER
			btn.position = pos_original + Vector2(0, -3)
		else:
			btn.modulate = BUTTON_MODULATE_NORMAL
			btn.position = pos_original
	)

func cargar_rarezas_iniciales() -> void:
	request_mode = RequestMode.LOAD_ALL_FOR_RAREZAS
	hacer_request_peces()


func load_fishes(rareza: String = "") -> void:
	request_mode = RequestMode.LOAD_FILTERED_FISHES
	hacer_request_peces(rareza)


func hacer_request_peces(rareza: String = "") -> void:
	if request_en_curso:
		return
	
	#var url := "https://fish-clicks.onrender.com/enciclopedia/peces"
	var url := "http://127.0.0.1:8080/enciclopedia/peces"

	var query_params: Array[String] = []

	if rareza != "":
		query_params.append("rareza=%s" % rareza.uri_encode())

	if query_params.size() > 0:
		url += "?" + "&".join(query_params)

	var body_dict := {
		"peces": pez_ids_desbloqueados
	}

	var body_json := JSON.stringify(body_dict)
	var headers := ["Content-Type: application/json"]
	
	if GlobalData.is_logged_in:
		headers.append("Authorization: " + GlobalData.get_auth_header())

	request_en_curso = true

	var err := http_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		body_json
	)

	if err != OK:
		request_en_curso = false
		push_error("No se pudo lanzar la request de peces")


func _on_request_completed(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	request_en_curso = false

	if response_code != 200:
		push_error("Error cargando peces: %s" % response_code)
		return

	var json := JSON.new()
	var parse_result := json.parse(body.get_string_from_utf8())
	if parse_result != OK:
		push_error("JSON inválido")
		return

	var data = json.data

	if typeof(data) != TYPE_ARRAY:
		push_error("La API no ha devuelto un array")
		return

	data.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("id", 0)) < int(b.get("id", 0))
	)

	match request_mode:
		RequestMode.LOAD_ALL_FOR_RAREZAS:
			guardar_rarezas_disponibles(data)
			crear_botones_rareza()

			rareza_actual = ""
			fishes = data
			current_page = 0
			update_book()

		RequestMode.LOAD_FILTERED_FISHES:
			fishes = data
			current_page = 0
			update_book()
			
func _configurar_boton_navegacion(btn: TextureButton, direccion: int) -> void:
	var pos_original: Vector2 = btn.position

	btn.modulate = BUTTON_MODULATE_NORMAL

	btn.mouse_entered.connect(func():
		btn.modulate = BUTTON_MODULATE_HOVER
		btn.position = pos_original + Vector2(NAV_HOVER_OFFSET * direccion, 0)
	)

	btn.mouse_exited.connect(func():
		btn.modulate = BUTTON_MODULATE_NORMAL
		btn.position = pos_original
	)

	btn.button_down.connect(func():
		btn.modulate = BUTTON_MODULATE_PRESSED
		btn.position = pos_original + Vector2(NAV_PRESSED_OFFSET * direccion, 0)
	)

	btn.button_up.connect(func():
		if btn.get_rect().has_point(btn.get_local_mouse_position()):
			btn.modulate = BUTTON_MODULATE_HOVER
			btn.position = pos_original + Vector2(NAV_HOVER_OFFSET * direccion, 0)
		else:
			btn.modulate = BUTTON_MODULATE_NORMAL
			btn.position = pos_original
	)


func guardar_rarezas_disponibles(data: Array) -> void:
	rarezas_disponibles.clear()

	for pez in data:
		var rareza := str(pez.get("rareza", "")).to_lower()
		if rareza != "" and not rareza in rarezas_disponibles:
			rarezas_disponibles.append(rareza)


func crear_botones_rareza() -> void:
	for child in rareza_container.get_children():
		child.queue_free()

	if rarezas_disponibles.is_empty():
		return

	_anadir_tab_todos()

	for r in rarezas_disponibles:
		_anadir_tab_rareza(r)


func _anadir_tab_rareza(rareza: String) -> void:
	var btn := TextureButton.new()

	var textura := get_boton_rareza_texture(rareza)
	if textura == null:
		return

	btn.texture_normal = textura
	btn.texture_hover = textura
	btn.texture_pressed = textura

	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_SCALE
	btn.custom_minimum_size = Vector2(40, 30)

	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	btn.pressed.connect(func(): cambiar_rareza(rareza))

	_configurar_estados_boton(btn)

	rareza_container.add_child(btn)
	
func _configurar_estados_boton(btn: TextureButton) -> void:
	btn.modulate = BUTTON_MODULATE_NORMAL

	btn.mouse_entered.connect(func():
		if btn.button_pressed:
			btn.modulate = BUTTON_MODULATE_PRESSED
		else:
			btn.modulate = BUTTON_MODULATE_HOVER
	)

	btn.mouse_exited.connect(func():
		btn.modulate = BUTTON_MODULATE_NORMAL
	)

	btn.button_down.connect(func():
		btn.modulate = BUTTON_MODULATE_PRESSED
	)

	btn.button_up.connect(func():
		if btn.get_rect().has_point(btn.get_local_mouse_position()):
			btn.modulate = BUTTON_MODULATE_HOVER
		else:
			btn.modulate = BUTTON_MODULATE_NORMAL
	)
	
func get_boton_rareza_texture(rareza: String) -> Texture2D:
	match rareza.to_lower():
		"comun":
			return load("res://assets/ui/tags/tag_comun_vertical_OK.png")
		"raro":
			return load("res://assets/ui/tags/tag_raro_vertical_OK.png")
		"epico":
			return load("res://assets/ui/tags/tag_epico_vertical_OK.png")
		"mitico":
			return load("res://assets/ui/tags/tag_mitico_vertical_OK.png")
		"ancestral":
			return load("res://assets/ui/tags/tag_ancestral_vertical_OK.png")
		_:
			return null
			
func _anadir_tab_todos() -> void:
	var btn := TextureButton.new()

	var textura := load("res://assets/ui/tags/tag_todos_vertical_OK.png")
	if textura == null:
		return

	btn.texture_normal = textura
	btn.texture_hover = textura
	btn.texture_pressed = textura

	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_SCALE
	btn.custom_minimum_size = Vector2(40, 30)

	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	btn.pressed.connect(func(): cambiar_rareza(""))

	_configurar_estados_boton(btn)

	rareza_container.add_child(btn)

func cambiar_rareza(nueva_rareza: String) -> void:
	if request_en_curso:
		return

	if rareza_actual == nueva_rareza:
		return

	rareza_actual = nueva_rareza
	current_page = 0
	category_changed.emit()
	load_fishes(rareza_actual)


func update_book() -> void:
	var max_page := maxi(0, int(ceil(fishes.size() / 2.0)) - 1)
	current_page = clamp(current_page, 0, max_page)

	var left_index := current_page * 2
	var right_index := left_index + 1

	_fill_page(left_index, true)
	_fill_page(right_index, false)

	var has_fishes := fishes.size() > 0
	var can_go_previous := has_fishes and current_page > 0
	var can_go_next := has_fishes and ((current_page + 1) * 2 < fishes.size())

	btn_anterior.visible = can_go_previous
	btn_siguiente.visible = can_go_next

	btn_anterior.disabled = not can_go_previous
	btn_siguiente.disabled = not can_go_next


func _fill_page(index: int, is_left: bool) -> void:
	if index >= fishes.size():
		limpiar_pagina(is_left)
		_set_pagina_visible(is_left, false)
		return

	_set_pagina_visible(is_left, true)

	var fish: Dictionary = fishes[index]

	var rareza_raw := str(fish.get("rareza", ""))
	var rareza := capitalizar_rareza(rareza_raw)
	var nombre := str(fish.get("nombre", ""))
	var descripcion := str(fish.get("descripcion", ""))
	var efecto := str(fish.get("efectoDescripcion", ""))
	var habitat := str(fish.get("habitat", ""))

	if is_left:
		tag_rareza_izq.text = rareza
		tag_bg_izq.texture = get_rareza_texture(rareza_raw)

		marco_pez_izq.texture = get_marco_pez_texture()
		pez_izq.texture = get_fish_texture(int(fish.get("id", -1)))

		nombre_izq.text = nombre
		descripcion_izq.text = descripcion

		tag_bg_izq2.texture = get_tag_info_texture()
		stat_izq.text = efecto

		tag_bg_izq3.texture = get_tag_info_texture()
		habitat_izq.text = habitat
	else:
		tag_rareza_der.text = rareza
		tag_bg_der.texture = get_rareza_texture(rareza_raw)

		marco_pez_der.texture = get_marco_pez_texture()
		pez_der.texture = get_fish_texture(int(fish.get("id", -1)))

		nombre_der.text = nombre
		descripcion_der.text = descripcion

		tag_bg_der2.texture = get_tag_info_texture()
		stat_der.text = efecto

		tag_bg_der3.texture = get_tag_info_texture()
		habitat_der.text = habitat

func _set_pagina_visible(is_left: bool, value: bool) -> void:
	if is_left:
		pagina_izq_contenido.visible = value
	else:
		pagina_der_contenido.visible = value
		
func limpiar_pagina(is_left: bool) -> void:
	if is_left:
		tag_rareza_izq.text = ""
		tag_bg_izq.texture = null

		marco_pez_izq.texture = null
		pez_izq.texture = null

		nombre_izq.text = ""
		descripcion_izq.text = ""

		tag_bg_izq2.texture = null
		stat_izq.text = ""

		tag_bg_izq3.texture = null
		habitat_izq.text = ""
	else:
		tag_rareza_der.text = ""
		tag_bg_der.texture = null

		marco_pez_der.texture = null
		pez_der.texture = null

		nombre_der.text = ""
		descripcion_der.text = ""

		tag_bg_der2.texture = null
		stat_der.text = ""

		tag_bg_der3.texture = null
		habitat_der.text = ""
		
func get_marco_pez_texture() -> Texture2D:
	return load("res://assets/ui/marco_peces.png")

func get_tag_info_texture() -> Texture2D:
	return load("res://assets/ui/rarezas/tag_rareza_default.png")


func _on_btn_anterior_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		update_book()
		page_changed.emit()


func _on_btn_siguiente_pressed() -> void:
	if (current_page + 1) * 2 < fishes.size():
		current_page += 1
		update_book()
		page_changed.emit()


func capitalizar_rareza(texto: String) -> String:
	if texto.is_empty():
		return ""
	return texto.substr(0, 1).to_upper() + texto.substr(1)


func get_fish_texture(fish_id: int) -> Texture2D:
	match fish_id:
		1:
			return load("res://assets/peces/doblon.png")
		2:
			return load("res://assets/peces/sobrasada.png")
		3:
			return load("res://assets/peces/espuma.png")
		4:
			return load("res://assets/peces/rufinus.png")
		5:
			return load("res://assets/peces/chupete_jr.png")
		6:
			return load("res://assets/peces/auspezio.png")
		7:
			return load("res://assets/peces/barbacoa.png")
		8:
			return load("res://assets/peces/angeles.png")
		9:
			return load("res://assets/peces/jigou.png")
		10:
			return load("res://assets/peces/leonardo.png")
		_:
			return null
			
func get_rareza_texture(rareza: String) -> Texture2D:
	match rareza.to_lower():
		"comun":
			var tex = load("res://assets/ui/rarezas/tag_rareza_comun.png")
			return tex
		"raro":
			var tex = load("res://assets/ui/rarezas/tag_rareza_raro.png")
			return tex
		"epico":
			var tex = load("res://assets/ui/rarezas/tag_rareza_epico.png")
			return tex
		"mitico":
			var tex = load("res://assets/ui/rarezas/tag_rareza_mitico.png")
			return tex
		"ancestral":
			var tex = load("res://assets/ui/rarezas/tag_rareza_ancestral.png")
			return tex
		_:
			return null

func set_pez_ids_desbloqueados(ids: Array[int]) -> void:
	pez_ids_desbloqueados = ids
	cargar_rarezas_iniciales()


func open() -> void:
	visible = true


func close() -> void:
	visible = false


func toggle() -> void:
	visible = !visible
