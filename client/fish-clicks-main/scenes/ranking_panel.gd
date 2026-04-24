extends Control

signal close_requested

@export var row_scene: PackedScene 
var default_avatar = load("res://assets/ui/iconos/default_avatar.png")

@onready var btn_close: TextureButton = $BtnClose

# Aquí ya tienes las referencias directas
@onready var podium_nodes = {
	1: {"photo": $MarginContainer/MarginContainer/VBoxMain/PodiumSection/Winner1/Photo1, "name": $MarginContainer/MarginContainer/VBoxMain/PodiumSection/Winner1/Name1},
	2: {"photo": $MarginContainer/MarginContainer/VBoxMain/PodiumSection/Winner2/Photo2, "name": $MarginContainer/MarginContainer/VBoxMain/PodiumSection/Winner2/Name2},
	3: {"photo": $MarginContainer/MarginContainer/VBoxMain/PodiumSection/Winner3/Photo3, "name": $MarginContainer/MarginContainer/VBoxMain/PodiumSection/Winner3/Name3}
}

@onready var items_container: VBoxContainer = $MarginContainer/MarginContainer/VBoxMain/ListSection/ScrollContainer/ItemsContainer

func _ready() -> void:
	visible = false
	if GlobalData.has_signal("ranking_received"):
		GlobalData.ranking_received.connect(_on_ranking_data)
	btn_close.pressed.connect(_on_btn_close_pressed)

func _open() -> void:
	show()
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.15)
	_request_ranking_data("money")

func _close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.12)
	tw.finished.connect(func(): 
		hide()
		close_requested.emit()
	)

func _on_btn_close_pressed() -> void:
	_close()

func _request_ranking_data(type: String):
	_clear_ui()
	GlobalData.fetch_ranking(type)

func _clear_ui():
	for i in range(1, 4):
		podium_nodes[i].name.text = ""
		podium_nodes[i].photo.texture = default_avatar
	for child in items_container.get_children():
		child.queue_free()

func _on_ranking_data(type: String, data: Array):
	_clear_ui()
	
	# 1. Podio
	for i in range(min(data.size(), 3)):
		var entry = data[i]
		var nodes = podium_nodes[i + 1]
		
		# Obtenemos el valor de 'score' del JSON
		var valor_score = entry.get("score", 0)
		
		# Formatear el texto (Doblones si es money)
		var suffix = " Doblones" if type == "money" else " Clicks"
		nodes.name.text = str(entry.get("nickname", "???")) + "\n" + str(valor_score) + suffix
		
		_load_external_photo(entry.get("foto", ""), nodes.photo)

	# 2. Lista
	for i in range(data.size()):
		var entry = data[i]
		if row_scene:
			var row = row_scene.instantiate()
			items_container.add_child(row)
			
			# Formatear el valor para la fila
			var valor_score = entry.get("score", 0)
			var score_text = str(valor_score) + (" Doblones" if type == "money" else " Clicks")
			
			row.set_data(i + 1, entry.get("nickname", "???"), score_text, "")
			
			
# Función con seguridad para evitar errores de Base64
func _load_external_photo(base64_str: String, rect: TextureRect):
	# 1. Filtro de seguridad inicial
	if base64_str == null or base64_str.length() < 100: 
		rect.texture = default_avatar
		return
		
	# 2. Limpieza de prefijos (por si acaso el Base64 trae metadatos)
	var b64_limpio = base64_str.strip_edges()
	if b64_limpio.contains(","):
		b64_limpio = b64_limpio.split(",")[1]

	# 3. Convertir a buffer de bytes
	var raw_data = Marshalls.base64_to_raw(b64_limpio)
	if raw_data.is_empty():
		rect.texture = default_avatar
		return

	var image = Image.new()
	var err = -1 # Valor de error por defecto

	# 4. ESCUDO: Solo llamar a Godot si la cabecera es válida
	# PNG: empieza por [137, 80, 78, 71] | JPG: empieza por [255, 216]
	if raw_data.size() > 4 and raw_data[0] == 137 and raw_data[1] == 80:
		err = image.load_png_from_buffer(raw_data)
	elif raw_data.size() > 2 and raw_data[0] == 255 and raw_data[1] == 216:
		err = image.load_jpg_from_buffer(raw_data)
	else:
		# Si no es ninguna, salimos en silencio SIN lanzar error al log
		rect.texture = default_avatar
		return

	# 5. Aplicar textura si todo fue OK
	if err == OK:
		rect.texture = ImageTexture.create_from_image(image)
	else:
		rect.texture = default_avatar
