extends Control

signal close_requested

@export var row_scene: PackedScene 
var default_avatar = load("res://assets/ui/iconos/default_avatar.png")

# --- Nodos ---
@onready var btn_close: TextureButton = $BtnClose
@onready var btn_tab_money: TextureButton = $BtnTabMoney   # Fuera del VBox
@onready var btn_tab_clicks: TextureButton = $BtnTabClicks # Fuera del VBox

@onready var my_user_row = $MyUserRow 
@onready var items_container: VBoxContainer = $MarginContainer/MarginContainer/VBoxMain/ListSection/ScrollContainer/ItemsContainer
@onready var scroll_container: ScrollContainer = $MarginContainer/MarginContainer/VBoxMain/ListSection/ScrollContainer
@onready var header_value_label: Label = $MarginContainer/MarginContainer/VBoxMain/ListSection/Header/ValueLabel

@onready var podium_nodes = {
	1: {"photo": $MarginContainer/MarginContainer/VBoxMain/PodiumSection/Winner1/Photo1, "name": $MarginContainer/MarginContainer/VBoxMain/PodiumSection/Winner1/Name1},
	2: {"photo": $MarginContainer/MarginContainer/VBoxMain/PodiumSection/Winner2/Photo2, "name": $MarginContainer/MarginContainer/VBoxMain/PodiumSection/Winner2/Name2},
	3: {"photo": $MarginContainer/MarginContainer/VBoxMain/PodiumSection/Winner3/Photo3, "name": $MarginContainer/MarginContainer/VBoxMain/PodiumSection/Winner3/Name3}
}

func _ready() -> void:
	visible = false
	if GlobalData.has_signal("ranking_received"):
		GlobalData.ranking_received.connect(_on_ranking_data)
	
	# Configuración Botón Cerrar (con Pivot al centro para el escalado)
	btn_close.pivot_offset = btn_close.size / 2
	btn_close.mouse_entered.connect(_on_btn_close_mouse_entered)
	btn_close.mouse_exited.connect(_on_btn_close_mouse_exited)
	btn_close.pressed.connect(_on_btn_close_pressed)
	
	# Configuración Botones de Pestaña
	btn_tab_money.pressed.connect(func(): _cambiar_categoria("money"))
	btn_tab_clicks.pressed.connect(func(): _cambiar_categoria("clicks"))
	
	my_user_row.hide()
	my_user_row.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _open() -> void:
	show()
	modulate.a = 0.0
	my_user_row.hide()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.15)
	
	# Por defecto carga Doblones
	_cambiar_categoria("money")

func _cambiar_categoria(tipo: String):
	# Efecto de salto en el botón seleccionado
	var main = get_tree().get_first_node_in_group("main")
	if main and main.ui_manager:
		var btn = btn_tab_money if tipo == "money" else btn_tab_clicks
		main.ui_manager.play_squish(btn)
	
	# Actualizamos el texto de la cabecera del ranking
	if header_value_label:
		header_value_label.text = "Doblones" if tipo == "money" else "Clicks"
	
	_request_ranking_data(tipo)

func _request_ranking_data(type: String):
	_clear_ui()
	GlobalData.fetch_ranking(type)

func _on_ranking_data(_type: String, data: Array):
	_clear_ui()
	var my_nickname = GlobalData.user_nickname if GlobalData.is_logged_in else ""
	var main = get_tree().get_first_node_in_group("main")
	
	for i in range(data.size()):
		var entry = data[i]
		var score_val = int(entry.get("score", 0))
		
		# Formateamos el número (con puntos de millar si tienes la función)
		var score_text = str(score_val)
		if main and main.has_method("format_with_separator"):
			score_text = main.format_with_separator(score_val)
		
		# Podio (1-3)
		if i < 3:
			var p_nodes = podium_nodes[i + 1]
			p_nodes.name.text = str(entry.get("nickname", "???"))
			_load_external_photo(entry.get("foto", ""), p_nodes.photo)
		
		# Crear fila en la lista
		var row = row_scene.instantiate()
		items_container.add_child(row)
		row.set_data(i + 1, entry.get("nickname", "???"), score_text, entry.get("foto", ""))
		
		# Fila flotante de mi usuario
		if my_nickname != "" and entry.get("nickname") == my_nickname:
			my_user_row.set_data(i + 1, my_nickname, score_text, entry.get("foto", ""))
			my_user_row.modulate = Color(1, 1, 0, 1) # Amarillo
			my_user_row.show()

func _clear_ui():
	my_user_row.hide()
	my_user_row.get_node("NameLabel").text = "" 
	for i in range(1, 4):
		podium_nodes[i].name.text = ""
		podium_nodes[i].photo.texture = default_avatar
	for child in items_container.get_children():
		child.queue_free()

# --- Animaciones Botón Cerrar ---
func _on_btn_close_pressed() -> void:
	var main = get_tree().get_first_node_in_group("main")
	if main and main.ui_manager:
		main.ui_manager.play_squish(btn_close)
	_close()

func _close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.12)
	tw.finished.connect(func(): hide(); close_requested.emit())

func _on_btn_close_mouse_entered() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(btn_close, "scale", Vector2(1.08, 1.08), 0.08)
	tween.parallel().tween_property(btn_close, "modulate", Color(0.85, 0.85, 0.85, 1.0), 0.08)

func _on_btn_close_mouse_exited() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(btn_close, "scale", Vector2.ONE, 0.08)
	tween.parallel().tween_property(btn_close, "modulate", Color(1, 1, 1, 1), 0.08)

# (Mantenemos _update_sticky_row_visibility y _load_external_photo igual)
func _process(_delta: float) -> void:
	if visible: _update_sticky_row_visibility()

func _update_sticky_row_visibility():
	var my_nickname = GlobalData.user_nickname
	if my_user_row.get_node("NameLabel").text == "": return
	var is_me_visible_in_scroll = false
	for child in items_container.get_children():
		if child.has_node("NameLabel") and child.get_node("NameLabel").text == my_nickname:
			var row_y = child.global_position.y
			var scroll_y = scroll_container.global_position.y
			var scroll_h = scroll_container.size.y
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
