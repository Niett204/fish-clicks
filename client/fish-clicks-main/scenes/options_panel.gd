extends Control

signal close_requested
signal volume_slider_spam_detected
signal modo_pecera_requested
const TutorialData = preload("res://scripts/data/bloques_tutorial.gd")
const FONT_TITLE = preload("res://assets/fuentes/PirataOne-Regular.ttf")
const FONT_BODY = preload("res://assets/fuentes/PirataOne-Regular.ttf")

@onready var btn_close: TextureButton = $CenterContainer/PanelRoot/BtnCerrar
@onready var btn_modo_pecera: Button = $CenterContainer/PanelRoot/BtnsArriba/BtnModoPecera
@onready var btn_tutorial: Button = $CenterContainer/PanelRoot/BtnsArriba/BtnTutorial
@onready var btn_salir: Button = $CenterContainer/PanelRoot/ButtonsRowBottom/BtnSalir
@onready var panel_sonido: Control = $CenterContainer/PanelRoot/PanelSonido

# Panel Tutorial
@onready var tutorial_overlay: Control = $TutorialOverlay
@onready var btn_cerrar_tutorial: TextureButton = $TutorialOverlay/CenterContainer/PanelTutorial/BtnCerrarTutorial
@onready var contenido_tutorial: VBoxContainer = $TutorialOverlay/CenterContainer/PanelTutorial/ScrollContainer/ContenidoTutorial
@onready var scroll_tutorial: ScrollContainer = $TutorialOverlay/CenterContainer/PanelTutorial/ScrollContainer
var tutorial_blocks: Array = TutorialData.TUTORIAL_BLOCKS

# Barra Sonido General
@onready var SliderGeneral: HSlider = $CenterContainer/PanelRoot/PanelSonido/MarginContainer/Content/RowGeneral/SliderWrapGeneral/SliderGeneral
@onready var FondoGeneral: ColorRect = $CenterContainer/PanelRoot/PanelSonido/MarginContainer/Content/RowGeneral/SliderWrapGeneral/FondoBarraGeneral
@onready var FillGeneral: ColorRect = $CenterContainer/PanelRoot/PanelSonido/MarginContainer/Content/RowGeneral/SliderWrapGeneral/FillBarraGeneral
@onready var LabelGeneral: Label = $CenterContainer/PanelRoot/PanelSonido/MarginContainer/Content/RowGeneral/SliderWrapGeneral/PorcentajeGeneral

# Barra Sonido Música
@onready var SliderMusica: HSlider = $CenterContainer/PanelRoot/PanelSonido/MarginContainer/Content/RowMusica/SliderWrapMusica/SliderMusica
@onready var FondoMusica: ColorRect = $CenterContainer/PanelRoot/PanelSonido/MarginContainer/Content/RowMusica/SliderWrapMusica/FondoBarraMusica
@onready var FillMusica: ColorRect = $CenterContainer/PanelRoot/PanelSonido/MarginContainer/Content/RowMusica/SliderWrapMusica/FillBarraMusica
@onready var LabelMusica: Label = $CenterContainer/PanelRoot/PanelSonido/MarginContainer/Content/RowMusica/SliderWrapMusica/PorcentajeMusica

# Barra Sonido Efectos
@onready var SliderEfectos: HSlider = $CenterContainer/PanelRoot/PanelSonido/MarginContainer/Content/RowEfectos/SliderWrapEfectos/SliderEfectos
@onready var FondoEfectos: ColorRect = $CenterContainer/PanelRoot/PanelSonido/MarginContainer/Content/RowEfectos/SliderWrapEfectos/FondoBarraEfectos
@onready var FillEfectos: ColorRect = $CenterContainer/PanelRoot/PanelSonido/MarginContainer/Content/RowEfectos/SliderWrapEfectos/FillBarraEfectos
@onready var LabelEfectos: Label = $CenterContainer/PanelRoot/PanelSonido/MarginContainer/Content/RowEfectos/SliderWrapEfectos/PorcentajeEfectos
@onready var fish_preview_player: AudioStreamPlayer = $FishPreviewPlayer

@onready var btn_guardar: Button = $CenterContainer/PanelRoot/ButtonsRowBottom/BtnGuardar
#@onready var lbl_save_status: Label = $CenterContainer/PanelRoot/ButtonsRowBottom/LblSaveStatus 

var slider_items: Array[Dictionary] = []
var _general_last_value: float = -1.0
var _general_last_direction: int = 0
var _general_direction_changes: int = 0
var _general_total_distance: float = 0.0
var _general_activity_start_time: float = -1.0
var _general_last_change_time: float = -1.0

const VOLUME_SPAM_REQUIRED_DURATION: float = 5.0
const VOLUME_SPAM_REQUIRED_DISTANCE: float = 250.0
const VOLUME_SPAM_REQUIRED_DIRECTION_CHANGES: int = 6
const VOLUME_SPAM_IDLE_RESET_TIME: float = 0.8
const VOLUME_SPAM_MIN_DELTA: float = 3.0

func _ready() -> void:
	visible = false

	fish_preview_player.stream = preload("res://assets/audio/peces/bubble.WAV")
	_configure_slider(SliderGeneral)
	_configure_slider(SliderMusica)
	_configure_slider(SliderEfectos)
	
	# Inicializar las Sliders a un valor predeterminado
	SliderGeneral.value = 15
	SliderMusica.value = 20
	SliderEfectos.value = 25

	_apply_all_slider_audio()
	
	# Creamos una imagen transparente para sustituir el grabber predeterminado del Slider
	var transparent_tex := _create_transparent_texture()

	# Asignamos la imagen transparente al grabber 
	_remove_slider_grabber(SliderGeneral, transparent_tex)
	_remove_slider_grabber(SliderMusica, transparent_tex)
	_remove_slider_grabber(SliderEfectos, transparent_tex)

	# Las labels inicialmente no son visibles hasta que haya interacción con el slider
	LabelGeneral.visible = false
	LabelMusica.visible = false
	LabelEfectos.visible = false

	slider_items = [
		{
			"slider": SliderGeneral,
			"fondo": FondoGeneral,
			"fill": FillGeneral,
			"label": LabelGeneral
		},
		{
			"slider": SliderMusica,
			"fondo": FondoMusica,
			"fill": FillMusica,
			"label": LabelMusica
		},
		{
			"slider": SliderEfectos,
			"fondo": FondoEfectos,
			"fill": FillEfectos,
			"label": LabelEfectos
		}
	]

	for item in slider_items:
		var slider: HSlider = item["slider"]
		
		slider.value_changed.connect(_on_slider_value_changed.bind(item))
		slider.gui_input.connect(_on_slider_gui_input.bind(item))
	
	await get_tree().process_frame

	for item in slider_items:
		_update_slider_visuals(item)

	# Efectos visuales botón cerrar
	btn_close.pressed.connect(_on_btn_close_pressed)
	btn_close.mouse_entered.connect(_on_btn_close_mouse_entered)
	btn_close.mouse_exited.connect(_on_btn_close_mouse_exited)
	btn_close.button_down.connect(_on_btn_close_button_down)
	btn_close.button_up.connect(_on_btn_close_button_up)

	# Botón modo pecera
	btn_modo_pecera.pressed.connect(_on_btn_modo_pecera_pressed)
	
	# Botón salir
	btn_salir.pressed.connect(_on_btn_salir_pressed)
	
	# Botón guardado
	btn_guardar.pressed.connect(_on_btn_guardar_pressed)
	GlobalData.save_success.connect(_on_save_ok)
	GlobalData.save_failed.connect(_on_save_err)
	
	# Botón Tutorial
	tutorial_overlay.visible = false
	btn_tutorial.pressed.connect(_on_btn_tutorial_pressed)
	btn_cerrar_tutorial.pressed.connect(_on_btn_cerrar_tutorial_pressed)
	_build_tutorial()

func _on_slider_value_changed(_value: float, item: Dictionary) -> void:
	_update_slider_visuals(item)
	_apply_slider_audio(item)

	var slider: HSlider = item["slider"]
	if slider == SliderGeneral:
		_register_general_slider_change(slider.value)

func _on_slider_gui_input(event: InputEvent, item: Dictionary) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_slider_button_down(item)
		else:
			_on_slider_button_up(item)
				
func _configure_slider(slider: HSlider) -> void:
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.editable = true
	slider.mouse_filter = Control.MOUSE_FILTER_STOP

# Crea una imagen transparente 
func _create_transparent_texture() -> Texture2D:
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)

# Cambia el grabber del slider
func _remove_slider_grabber(slider: HSlider, tex: Texture2D) -> void:
	slider.add_theme_icon_override("grabber", tex)
	slider.add_theme_icon_override("grabber_highlight", tex)
	slider.add_theme_icon_override("grabber_disabled", tex)
	slider.add_theme_icon_override("grabber_pressed", tex)

# Asocia el valor del volumen del slider al bus de audio 
func _set_bus_volume_linear(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	if value <= 0.001:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
		
# Actualiza la barra en cada interacción 
func _update_slider_visuals(item: Dictionary) -> void:
	var slider: HSlider = item["slider"]
	var fondo: Control = item["fondo"]
	var fill: Control = item["fill"]
	var label: Label = item["label"]

	var ratio := 0.0
	if slider.max_value > slider.min_value:
		ratio = (slider.value - slider.min_value) / (slider.max_value - slider.min_value)

	var ancho_total := fondo.size.x
	var fill_width := ancho_total * ratio

	# Relleno visual de la barra
	fill.size.x = fill_width

	# Texto del porcentaje
	label.text = "%d%%" % int(round(slider.value))
	label.reset_size()

	# Colocamos la label siguiendo la posición actual del valor
	var label_x := fill_width - label.size.x / 2.0
	label.position.x = clamp(label_x, 0.0, ancho_total - label.size.x)
	label.position.y = -28

# Inicializa las sliders a un valor predeterminado al inicio del juego 
func _apply_all_slider_audio() -> void:
	_apply_slider_audio({"slider": SliderGeneral})
	_apply_slider_audio({"slider": SliderMusica})
	_apply_slider_audio({"slider": SliderEfectos})
	
# Al cambiar el volumen en el slider, llamamos a la función para cambiar el valor de su correspondiente bus
func _apply_slider_audio(item: Dictionary) -> void:
	var slider: HSlider = item["slider"]
	var linear_value := slider.value / 100.0

	if slider == SliderGeneral:
		_set_bus_volume_linear("Master", linear_value)
	elif slider == SliderMusica:
		_set_bus_volume_linear("Musica", linear_value)
	elif slider == SliderEfectos:
		_set_bus_volume_linear("Efectos", linear_value)
		
# Al clicar en el slider
func _on_slider_button_down(item: Dictionary) -> void:
	var label: Label = item["label"]
	label.visible = true
	_update_slider_visuals(item)

# Al soltar el slider se esconde el label y suenda un preview del volumen
func _on_slider_button_up(item: Dictionary) -> void:
	var label: Label = item["label"]
	label.visible = false
	
	var slider: HSlider = item["slider"]
	
	if slider == SliderEfectos:
		_play_fish_volume_preview()

# Reproducir sonido de preview de la Slider	
func _play_fish_volume_preview() -> void:
	if fish_preview_player.stream == null:
		return

	if fish_preview_player.playing:
		fish_preview_player.seek(0)
	else:
		fish_preview_player.play()
		
# Funciones Botón X Close
func _on_btn_close_pressed() -> void:
	tutorial_overlay.visible = false
	close_requested.emit()

func _on_btn_close_mouse_entered() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(btn_close, "scale", Vector2(1.08, 1.08), 0.08)
	tween.parallel().tween_property(btn_close, "modulate", Color(0.85, 0.85, 0.85, 1.0), 0.08)

func _on_btn_close_mouse_exited() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(btn_close, "scale", Vector2.ONE, 0.08)
	tween.parallel().tween_property(btn_close, "modulate", Color(1, 1, 1, 1), 0.08)

func _on_btn_close_button_down() -> void:
	var tween := create_tween()
	tween.tween_property(btn_close, "scale", Vector2(0.94, 0.94), 0.05)
	btn_close.modulate = Color(0.7, 0.7, 0.7, 1.0)

func _on_btn_close_button_up() -> void:
	var hover := btn_close.get_global_rect().has_point(get_global_mouse_position())
	var target_scale := Vector2(1.08, 1.08) if hover else Vector2.ONE
	var target_modulate := Color(0.85, 0.85, 0.85, 1.0) if hover else Color(1, 1, 1, 1)

	var tween := create_tween()
	tween.tween_property(btn_close, "scale", target_scale, 0.06)
	tween.parallel().tween_property(btn_close, "modulate", target_modulate, 0.06)

func _on_btn_modo_pecera_pressed() -> void:
	modo_pecera_requested.emit()
	
# Al clicar en el botón salir se cierra el juego
func _on_btn_salir_pressed() -> void:
	get_tree().quit()

func _reset_general_slider_spam_tracking() -> void:
	_general_last_value = -1.0
	_general_last_direction = 0
	_general_direction_changes = 0
	_general_total_distance = 0.0
	_general_activity_start_time = -1.0
	_general_last_change_time = -1.0

func _register_general_slider_change(current_value: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0

	if _general_last_change_time >= 0.0 and now - _general_last_change_time > VOLUME_SPAM_IDLE_RESET_TIME:
		_reset_general_slider_spam_tracking()

	if _general_activity_start_time < 0.0:
		_general_activity_start_time = now

	if _general_last_value < 0.0:
		_general_last_value = current_value
		_general_last_change_time = now
		return

	var delta: float = current_value - _general_last_value
	var abs_delta: float = abs(delta)

	if abs_delta < VOLUME_SPAM_MIN_DELTA:
		return

	var direction: int = 1 if delta > 0.0 else -1

	if _general_last_direction != 0 and direction != _general_last_direction:
		_general_direction_changes += 1

	_general_last_direction = direction
	_general_total_distance += abs_delta
	_general_last_value = current_value
	_general_last_change_time = now

	var active_duration: float = now - _general_activity_start_time

	if (
		active_duration >= VOLUME_SPAM_REQUIRED_DURATION
		and _general_total_distance >= VOLUME_SPAM_REQUIRED_DISTANCE
		and _general_direction_changes >= VOLUME_SPAM_REQUIRED_DIRECTION_CHANGES
	):
		_reset_general_slider_spam_tracking()
		volume_slider_spam_detected.emit()


# Funciones de guardado
func _on_btn_guardar_pressed() -> void:
	if not GlobalData.is_logged_in:
		# Muestra feedback de que necesita sesión
		_show_save_status("Inicia sesión para guardar")
		return

	btn_guardar.disabled = true
	btn_guardar.text = "Guardando..."

	# Recoge el estado del juego desde main
	var main = get_tree().get_first_node_in_group("main")
	if main and main.save_manager:
		GlobalData.save_game(main.save_manager.get_save_state())
	else:
		push_error("No se encontró save_manager")
		btn_guardar.disabled = false


func _on_save_ok() -> void:
	btn_guardar.disabled = false
	btn_guardar.text = "Guardar"
	_show_save_status("Partida guardada!")


func _on_save_err(error: String) -> void:
	btn_guardar.disabled = false
	btn_guardar.text = "Guardar"
	_show_save_status("Error: " + error)


func _show_save_status(msg: String) -> void:
	# Si tienes un Label de feedback en el panel, úsalo
	# Si no, simplemente imprime por ahora
	print(msg)
	# lbl_save_status.text = msg  # descomenta si añades el Label
	
# Panel Tutorial
func _on_btn_tutorial_pressed() -> void:
	tutorial_overlay.visible = true
	tutorial_overlay.move_to_front()
	scroll_tutorial.scroll_vertical = 0

func _on_btn_cerrar_tutorial_pressed() -> void:
	tutorial_overlay.visible = false

func _build_tutorial() -> void:
	for child in contenido_tutorial.get_children():
		child.queue_free()

	for block in tutorial_blocks:
		contenido_tutorial.add_child(_create_tutorial_block(block))


func _create_tutorial_block(block: Dictionary) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.custom_minimum_size = Vector2(420, 0)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 10)

	var image := TextureRect.new()
	if block.has("image") and block["image"] != null:
		image.texture = block["image"]

	image.custom_minimum_size = Vector2(460, 230)
	image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var title := Label.new()
	title.text = block["title"]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#a9502b"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var text := RichTextLabel.new()
	text.text = block["text"]
	text.fit_content = true
	text.scroll_active = false
	text.custom_minimum_size = Vector2(420, 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_font_override("normal_font", FONT_BODY)
	text.add_theme_font_size_override("normal_font_size", 18)
	text.add_theme_color_override("default_color", Color("#6f4a2d"))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 35)

	container.add_child(image)
	container.add_child(title)
	container.add_child(text)
	container.add_child(spacer)

	return container

func close_panel() -> void:
	tutorial_overlay.visible = false
	visible = false
