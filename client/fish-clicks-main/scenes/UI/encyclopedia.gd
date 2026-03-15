extends Control

@onready var http_request: HTTPRequest = $HTTPRequest
@onready var rareza_container: VBoxContainer = $FondoLibro/RarezaContainer

@onready var tag_bg_izq: TextureRect = $FondoLibro/ContenedorLibro/PaginaIzq/MarginIzq/VBoxIzq/tag_bg_izq
@onready var tag_rareza_izq: Label = $FondoLibro/ContenedorLibro/PaginaIzq/MarginIzq/VBoxIzq/tag_bg_izq/TagRarezaIzq
@onready var pez_izq: TextureRect = $FondoLibro/ContenedorLibro/PaginaIzq/MarginIzq/VBoxIzq/marco_pez_izq/PezIzq
@onready var nombre_izq: Label = $FondoLibro/ContenedorLibro/PaginaIzq/MarginIzq/VBoxIzq/NombrePezIzq
@onready var descripcion_izq: RichTextLabel = $FondoLibro/ContenedorLibro/PaginaIzq/MarginIzq/VBoxIzq/DescripcionIzq
@onready var stat_izq: Label = $FondoLibro/ContenedorLibro/PaginaIzq/MarginIzq/VBoxIzq/HBoxIzq/tag_bg_izq2/StatIzq
@onready var habitat_izq: Label = $FondoLibro/ContenedorLibro/PaginaIzq/MarginIzq/VBoxIzq/HBoxIzq/tag_bg_izq3/HabitatIzq


@onready var tag_bg_der: TextureRect = $FondoLibro/ContenedorLibro/PaginaDer/MarginDer/VBoxDer/tag_bg_der
@onready var tag_rareza_der: Label = $FondoLibro/ContenedorLibro/PaginaDer/MarginDer/VBoxDer/tag_bg_der/TagRarezaDer
@onready var pez_der: TextureRect = $FondoLibro/ContenedorLibro/PaginaDer/MarginDer/VBoxDer/marco_pez_der/PezDer
@onready var nombre_der: Label = $FondoLibro/ContenedorLibro/PaginaDer/MarginDer/VBoxDer/NombrePezDer
@onready var descripcion_der: RichTextLabel = $FondoLibro/ContenedorLibro/PaginaDer/MarginDer/VBoxDer/DescripcionDer
@onready var stat_der: Label = $FondoLibro/ContenedorLibro/PaginaDer/MarginDer/VBoxDer/HBoxDer/tag_bg_der2/StatDer
@onready var habitat_der: Label = $FondoLibro/ContenedorLibro/PaginaDer/MarginDer/VBoxDer/HBoxDer/tag_bg_der3/HabitatDer

@onready var btn_anterior: TextureButton = $BtnAnterior
@onready var btn_siguiente: TextureButton = $BtnSiguiente

var fishes: Array = []
var current_page: int = 0
var rareza_actual: String = ""
var rarezas_disponibles: Array = []

var pez_ids_desbloqueados: Array[int] = [1]

enum RequestMode {
	LOAD_ALL_FOR_RAREZAS,
	LOAD_FILTERED_FISHES
}

var request_mode: int = RequestMode.LOAD_ALL_FOR_RAREZAS


func _ready() -> void:
	visible = false

	http_request.request_completed.connect(_on_request_completed)
	btn_anterior.pressed.connect(_on_btn_anterior_pressed)
	btn_siguiente.pressed.connect(_on_btn_siguiente_pressed)

	cargar_rarezas_iniciales()


func cargar_rarezas_iniciales() -> void:
	request_mode = RequestMode.LOAD_ALL_FOR_RAREZAS
	hacer_request_peces()


func load_fishes(rareza: String = "") -> void:
	request_mode = RequestMode.LOAD_FILTERED_FISHES
	hacer_request_peces(rareza)


func hacer_request_peces(rareza: String = "") -> void:
	var url := "https://fish-clicks.onrender.com/enciclopedia/peces"

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

	var err := http_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		body_json
	)

	if err != OK:
		push_error("No se pudo lanzar la request de peces")


func _on_request_completed(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	print("Código:", response_code)
	print("Respuesta:", body.get_string_from_utf8())

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


func guardar_rarezas_disponibles(data: Array) -> void:
	rarezas_disponibles.clear()

	for pez in data:
		var rareza := str(pez.get("rareza", "")).to_lower()
		if rareza != "" and not rareza in rarezas_disponibles:
			rarezas_disponibles.append(rareza)


func crear_botones_rareza() -> void:
	for child in rareza_container.get_children():
		child.queue_free()

	var btn_todas := Button.new()
	btn_todas.text = "Todas"
	btn_todas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_todas.pressed.connect(func(): cambiar_rareza(""))
	rareza_container.add_child(btn_todas)

	for r in rarezas_disponibles:
		var btn := Button.new()
		btn.text = capitalizar_rareza(r)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): cambiar_rareza(r))
		rareza_container.add_child(btn)


func cambiar_rareza(nueva_rareza: String) -> void:
	if rareza_actual == nueva_rareza:
		return

	rareza_actual = nueva_rareza
	current_page = 0
	load_fishes(rareza_actual)


func update_book() -> void:
	var left_index := current_page * 2
	var right_index := left_index + 1

	_fill_page(left_index, true)
	_fill_page(right_index, false)

	btn_anterior.disabled = current_page == 0
	btn_siguiente.disabled = right_index >= fishes.size() - 1


func _fill_page(index: int, is_left: bool) -> void:
	if index >= fishes.size():
		limpiar_pagina(is_left)
		return

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
		nombre_izq.text = nombre
		descripcion_izq.text = descripcion
		stat_izq.text = efecto
		habitat_izq.text = habitat
		pez_izq.texture = get_fish_texture(int(fish.get("id", -1)))
	else:
		tag_rareza_der.text = rareza
		tag_bg_der.texture = get_rareza_texture(rareza_raw)
		nombre_der.text = nombre
		descripcion_der.text = descripcion
		stat_der.text = efecto
		habitat_der.text = habitat
		pez_der.texture = get_fish_texture(int(fish.get("id", -1)))


func limpiar_pagina(is_left: bool) -> void:
	if is_left:
		tag_rareza_izq.text = ""
		tag_bg_izq.texture = null
		nombre_izq.text = ""
		descripcion_izq.text = ""
		stat_izq.text = ""
		habitat_izq.text = ""
		pez_izq.texture = null
	else:
		tag_rareza_der.text = ""
		tag_bg_der.texture = null
		nombre_der.text = ""
		descripcion_der.text = ""
		stat_der.text = ""
		habitat_der.text = ""
		pez_der.texture = null


func _on_btn_anterior_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		update_book()


func _on_btn_siguiente_pressed() -> void:
	if (current_page + 1) * 2 < fishes.size():
		current_page += 1
		update_book()


func capitalizar_rareza(texto: String) -> String:
	if texto.is_empty():
		return ""
	return texto.substr(0, 1).to_upper() + texto.substr(1)


func get_fish_texture(fish_id: int) -> Texture2D:
	match fish_id:
		1:
			return load("res://assets/peces/doblon.png")
		_:
			return null

func get_rareza_texture(rareza: String) -> Texture2D:
	match rareza.to_lower():
		"comun":
			var tex = load("res://assets/ui/rarezas/tag_rareza_comun.png")
			print("TEXTURA COMUN: ", tex)
			return tex
		_:
			return null

func set_pez_ids_desbloqueados(ids: Array[int]) -> void:
	pez_ids_desbloqueados = ids


func open() -> void:
	visible = true


func close() -> void:
	visible = false


func toggle() -> void:
	visible = !visible
