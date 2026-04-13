extends Node
class_name FishModeManager

var main: Node = null

var modo_pecera: bool = false
var arrastrando_pecera: bool = false
var drag_offset: Vector2i = Vector2i.ZERO


func setup(main_ref: Node) -> void:
	main = main_ref


func toggle_fish_mode() -> void:
	var w := main.get_window()
	var id := w.get_window_id()

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, id)

	var size_grande := Vector2i(1152, 648)
	var size_pequeno := Vector2i(384, 216)

	if modo_pecera:
		main.hud.visible = true
		main.btn_hide.visible = true
		main.pecera_blocker.visible = false
		w.borderless = false
		w.always_on_top = false
		DisplayServer.window_set_size(size_grande, id)

		var screen := DisplayServer.screen_get_usable_rect()
		var pos := Vector2i(
			int((screen.size.x - size_grande.x) / 2.0),
			int((screen.size.y - size_grande.y) / 2.0)
		)
		DisplayServer.window_set_position(pos, id)
	else:
		if main.options_panel.visible:
			main.options_panel.hide()

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

	modo_pecera = !modo_pecera


func handle_input(event: InputEvent) -> void:
	if not modo_pecera:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.double_click:
				arrastrando_pecera = false
				toggle_fish_mode()
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
