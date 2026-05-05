extends Control

signal close_requested

@export var row_scene: PackedScene 
var default_avatar = load("res://assets/ui/iconos/default_avatar.png")

@onready var btn_close: TextureButton = $BtnClose
# Asegúrate de que MyUserRow sea hijo directo del Panel para que flote
@onready var my_user_row = $MyUserRow 

@onready var podium_nodes = {
	1: {"photo": $MarginContainer/MarginContainer/VBoxMain/PodiumSection/Winner1/Photo1, "name": $MarginContainer/MarginContainer/VBoxMain/PodiumSection/Winner1/Name1},
	2: {"photo": $MarginContainer/MarginContainer/VBoxMain/PodiumSection/Winner2/Photo2, "name": $MarginContainer/MarginContainer/VBoxMain/PodiumSection/Winner2/Name2},
	3: {"photo": $MarginContainer/MarginContainer/VBoxMain/PodiumSection/Winner3/Photo3, "name": $MarginContainer/MarginContainer/VBoxMain/PodiumSection/Winner3/Name3}
}

@onready var items_container: VBoxContainer = $MarginContainer/MarginContainer/VBoxMain/ListSection/ScrollContainer/ItemsContainer
@onready var scroll_container: ScrollContainer = $MarginContainer/MarginContainer/VBoxMain/ListSection/ScrollContainer

func _ready() -> void:
	visible = false
	if GlobalData.has_signal("ranking_received"):
		GlobalData.ranking_received.connect(_on_ranking_data)
	btn_close.pressed.connect(_on_btn_close_pressed)
	my_user_row.hide()
	# IMPORTANTE: Haz que MyUserRow ignore el ratón para que no bloquee el scroll
	my_user_row.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	# Solo actualizamos si el panel es visible y tenemos datos de nuestro usuario
	if visible and my_user_row.visible == false or my_user_row.visible == true:
		_update_sticky_row_visibility()

func _open() -> void:
	show()
	modulate.a = 0.0
	my_user_row.hide()
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
	# 1. Buscamos la referencia a la escena principal
	var main = get_tree().get_first_node_in_group("main")
	if main and main.ui_manager:
		# 2. Ejecutamos la animación de salto en el botón 'btn_close'
		main.ui_manager.play_squish(btn_close)
	
	# 3. Llamamos a la función de cierre que ya tienes
	_close()

func _request_ranking_data(type: String):
	_clear_ui()
	GlobalData.fetch_ranking(type)

func _clear_ui():
	my_user_row.hide()
	# Reseteamos el texto para saber que no hay datos aún
	my_user_row.get_node("NameLabel").text = "" 
	for i in range(1, 4):
		if podium_nodes.has(i):
			podium_nodes[i].name.text = ""
			podium_nodes[i].photo.texture = default_avatar
	for child in items_container.get_children():
		child.queue_free()

func _on_ranking_data(type: String, data: Array):
	_clear_ui()
	var my_nickname = GlobalData.user_nickname
	
	for i in range(data.size()):
		var entry = data[i]
		var score_text = str(int(entry.get("score", 0)))
		
		if i < 3:
			var p_nodes = podium_nodes[i + 1]
			# Ahora solo asignamos el apodo:
			p_nodes.name.text = str(entry.get("nickname", "???")) 
			_load_external_photo(entry.get("foto", ""), p_nodes.photo)
		
		var row = row_scene.instantiate()
		items_container.add_child(row)
		row.set_data(i + 1, entry.get("nickname", "???"), score_text, entry.get("foto", ""))
		
		# Si soy yo, guardamos los datos en la fila pegajosa
		if entry.get("nickname") == my_nickname:
			my_user_row.set_data(i + 1, my_nickname, score_text, entry.get("foto", ""))
			# Le damos el color amarillo
			my_user_row.modulate = Color(1, 1, 0, 1) 

func _update_sticky_row_visibility():
	var my_nickname = GlobalData.user_nickname
	# Si no hemos cargado nuestro nombre aún, no hacemos nada
	if my_user_row.get_node("NameLabel").text == "": return
	
	var is_me_visible_in_scroll = false
	
	for child in items_container.get_children():
		if child.has_node("NameLabel") and child.get_node("NameLabel").text == my_nickname:
			# Calculamos límites visuales
			var row_y = child.global_position.y
			var scroll_y = scroll_container.global_position.y
			var scroll_h = scroll_container.size.y
			
			# Margen de seguridad para que no parpadee
			if row_y >= scroll_y - 5 and (row_y + child.size.y) <= (scroll_y + scroll_h + 5):
				is_me_visible_in_scroll = true
			break
	
	my_user_row.visible = !is_me_visible_in_scroll

func _load_external_photo(base64_str: String, rect: TextureRect):
	if base64_str == null or base64_str.length() < 100: 
		rect.texture = default_avatar
		return
	var b64_limpio = base64_str.strip_edges()
	if b64_limpio.contains(","): b64_limpio = b64_limpio.split(",")[1]
	var raw_data = Marshalls.base64_to_raw(b64_limpio)
	if raw_data.is_empty(): return
	var image = Image.new()
	var err = -1
	if raw_data.size() > 4 and raw_data[0] == 137: err = image.load_png_from_buffer(raw_data)
	elif raw_data.size() > 2 and raw_data[0] == 255: err = image.load_jpg_from_buffer(raw_data)
	if err == OK: rect.texture = ImageTexture.create_from_image(image)
