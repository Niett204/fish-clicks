extends Node
class_name FishModeManager

var main: Node = null

var modo_pecera: bool = false
var arrastrando_pecera: bool = false
var drag_offset: Vector2i = Vector2i.ZERO

var normal_window_size: Vector2i = Vector2i.ZERO
var normal_window_position: Vector2i = Vector2i.ZERO
var normal_window_borderless: bool = false
var normal_window_always_on_top: bool = false
var normal_window_mode: int = DisplayServer.WINDOW_MODE_WINDOWED
var normal_window_state_saved: bool = false


func setup(main_ref: Node) -> void:
	main = main_ref


func toggle_fish_mode() -> void:
	var w := main.get_window()
	var id := w.get_window_id()

	var size_pequeno := Vector2i(368, 207)

	if modo_pecera:
		main.hide_fish_mode_overlay()
		main.hud.visible = true
		main.btn_hide.visible = true
		main.pecera_blocker.visible = false
		main.apply_normal_mode_layout()

		w.borderless = normal_window_borderless
		w.always_on_top = normal_window_always_on_top

		if normal_window_state_saved:
			DisplayServer.window_set_mode(normal_window_mode, id)

			if normal_window_mode == DisplayServer.WINDOW_MODE_WINDOWED:
				DisplayServer.window_set_size(normal_window_size, id)
				DisplayServer.window_set_position(normal_window_position, id)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, id)
			DisplayServer.window_set_size(Vector2i(1152, 648), id)

			var screen := DisplayServer.screen_get_usable_rect()
			var pos := Vector2i(
				int((screen.size.x - 1152) / 2.0),
				int((screen.size.y - 648) / 2.0)
			)
			DisplayServer.window_set_position(pos, id)

	else:
		if main.options_panel.visible:
			main.options_panel.hide()

		# Guardamos estado actual ANTES de pasar a modo pecera
		normal_window_mode = DisplayServer.window_get_mode(id)
		normal_window_borderless = w.borderless
		normal_window_always_on_top = w.always_on_top
		normal_window_state_saved = true

		# Solo tiene sentido guardar size/position si estaba en windowed
		if normal_window_mode == DisplayServer.WINDOW_MODE_WINDOWED:
			normal_window_size = DisplayServer.window_get_size(id)
			normal_window_position = DisplayServer.window_get_position(id)

		# Entramos en modo pecera
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, id)
		w.borderless = true
		w.always_on_top = true
		DisplayServer.window_set_size(size_pequeno, id)

		var screen := DisplayServer.screen_get_usable_rect()
		var pos := Vector2i(
			0,
			screen.size.y - size_pequeno.y
		)
		DisplayServer.window_set_position(pos, id)

		main.hud.visible = false
		main.btn_hide.visible = false
		main.pecera_blocker.visible = true
		main.apply_fish_mode_layout()

	modo_pecera = !modo_pecera


func handle_input(event: InputEvent) -> void:
	if not modo_pecera:
		return

	if main.fish_mode_overlay.visible:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var button_rect: Rect2 = main.btn_expand_fish_mode.get_global_rect()
			var mouse_pos: Vector2 = main.get_viewport().get_mouse_position()

			if not button_rect.has_point(mouse_pos):
				main.hide_fish_mode_overlay()
				main.get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.double_click:
				arrastrando_pecera = false
				main.show_fish_mode_overlay()
				main.get_viewport().set_input_as_handled()
				return

			arrastrando_pecera = true
			var mouse_pos := DisplayServer.mouse_get_position()
			var window_pos := DisplayServer.window_get_position()
			drag_offset = mouse_pos - window_pos
		else:
			arrastrando_pecera = false

	elif event is InputEventMouseMotion and arrastrando_pecera:
		var mouse_pos := DisplayServer.mouse_get_position()
		var new_pos := mouse_pos - drag_offset
		DisplayServer.window_set_position(new_pos)
