extends Node
class_name UiManager

var main: Node = null
var _block_info_hover: bool = false

func setup(main_ref: Node) -> void:
	main = main_ref

func play_ui_sfx(stream: AudioStream) -> void:
	if stream == null:
		return

	main.ui_sfx_player.stream = stream
	main.ui_sfx_player.stop()
	main.ui_sfx_player.play()

func play_achievement_sfx(stream: AudioStream) -> void:
	if stream == null:
		return

	main.achievement_sfx_player.stream = stream
	main.achievement_sfx_player.stop()
	main.achievement_sfx_player.play()

func play_squish(node: Control) -> void:
	var t := main.create_tween()
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	node.scale = Vector2(1, 1)
	t.tween_property(node, "scale", Vector2(0.92, 0.88), 0.06)
	t.tween_property(node, "scale", Vector2(1.02, 1.02), 0.08)
	t.tween_property(node, "scale", Vector2(1, 1), 0.08)


func _close_overlay_panels(except_panel: Control = null) -> void:
	if main.shop_panel != except_panel:
		main.shop_open = false

		if main.shop_tween:
			main.shop_tween.kill()

		main.shop_panel.position.x = main.shop_x_closed

	if main.encyclopedia_panel != except_panel:
		main.encyclopedia_panel.visible = false

	if main.inventory_panel != except_panel:
		main.inventory_panel.visible = false

	if main.stats_panel != except_panel:
		main.stats_panel.visible = false

	if main.profile_panel != except_panel:
		if main.profile_panel.has_method("force_close"):
			main.profile_panel.force_close()
		else:
			main.profile_panel.visible = false

	if main.ranking_panel != except_panel:
		if main.ranking_panel.has_method("_close"):
			main.ranking_panel._close()
		main.ranking_panel.visible = false

	if main.options_panel != except_panel:
		if main.options_panel.has_method("close_panel"):
			main.options_panel.close_panel()
		else:
			main.options_panel.visible = false

func _toggle_hud() -> void:
	main.hud_visible = !main.hud_visible
	main.hud.visible = main.hud_visible

	if main.hud.visible:
		main.btn_hide.texture_normal = main.ICON_HIDE
	else:
		main.btn_hide.texture_normal = main.ICON_SHOW


func toggle_shop() -> void:
	main.shop_open = !main.shop_open

	if main.shop_open:
		_close_overlay_panels(main.shop_panel)

	if not main.shop_open and main.info_panel:
		main.info_panel.request_hide()

	if main.shop_tween:
		main.shop_tween.kill()

	main.shop_tween = main.create_tween()
	main.shop_tween.set_trans(Tween.TRANS_QUAD)
	main.shop_tween.set_ease(Tween.EASE_OUT)

	var target_x: float = main.shop_x_open if main.shop_open else main.shop_x_closed
	main.shop_tween.tween_property(main.shop_panel, "position:x", target_x, 0.25)

	if main.shop_open:
		play_ui_sfx(main.SFX_ICON_OPEN)
		await _refresh_current_shop_tab(main.tab_container.current_tab)
	else:
		play_ui_sfx(main.SFX_ICON_CLOSE)


func toggle_encyclopedia() -> void:
	var will_open: bool = not main.encyclopedia_panel.visible

	if will_open:
		_close_overlay_panels(main.encyclopedia_panel)
		play_ui_sfx(main.SFX_ICON_OPEN)
		main.encyclopedia_panel.visible = true
		main._actualizar_peces_desbloqueados_en_enciclopedia()

		if main.info_panel:
			main.info_panel.request_hide()
	else:
		main.encyclopedia_panel.visible = false
		play_ui_sfx(main.SFX_ICON_CLOSE)


func toggle_inventario() -> void:
	var will_open: bool = not main.inventory_panel.visible

	if will_open:
		_close_overlay_panels(main.inventory_panel)
		play_ui_sfx(main.SFX_ICON_OPEN)
		main.inventory_panel.visible = true

		if main.info_panel:
			main.info_panel.request_hide()

		main.inventory_panel.set_inventory_data(
			main.HABITATS,
			main.habitat_manager.unlocked_habitats,
			main.habitat_manager.inventory_habitat,
			main.aquarium_data,
			main.fish_defs,
			main.fish_inventory
		)
	else:
		main.inventory_panel.visible = false
		play_ui_sfx(main.SFX_ICON_CLOSE)


func toggle_options() -> void:
	var will_open: bool = not main.options_panel.visible

	if will_open:
		_close_overlay_panels(main.options_panel)
		play_ui_sfx(main.SFX_ICON_OPEN)
		main.options_panel.visible = true
		main.shop_open = false

		if main.info_panel:
			main.info_panel.request_hide()

		if main.shop_tween:
			main.shop_tween.kill()

		main.shop_panel.position.x = main.shop_x_closed
	else:
		main.options_panel.visible = false
		play_ui_sfx(main.SFX_ICON_CLOSE)


func toggle_stats_panel() -> void:
	var will_open: bool = not main.stats_panel.visible

	if will_open:
		_close_overlay_panels(main.stats_panel)
		play_ui_sfx(main.SFX_ICON_OPEN)
		main.stats_panel.visible = true

		if main.info_panel:
			main.info_panel.request_hide()

		main.stats_manager.refresh_stats_panel_full()
	else:
		main.stats_panel.visible = false
		play_ui_sfx(main.SFX_ICON_CLOSE)


func toggle_profile() -> void:
	var will_open: bool = not main.profile_panel.visible

	if will_open:
		close_all_panels()

		play_ui_sfx(main.SFX_ICON_OPEN)

		main.profile_panel._open()

		if main.info_panel:
			main.info_panel.request_hide()
	else:
		play_ui_sfx(main.SFX_ICON_CLOSE)
		main.profile_panel._close()

func close_all_panels() -> void:
	if main.info_panel:
		main.info_panel.request_hide()

	if main.shop_open:
		main.shop_open = false

		if main.shop_tween:
			main.shop_tween.kill()

		main.shop_panel.position.x = main.shop_x_closed
	
	if main.stats_panel.visible:
		main.stats_panel.visible = false
	
	if main.profile_panel.visible:
		if main.profile_panel.has_method("_close"):
			main.profile_panel._close()
		else:
			main.profile_panel.visible = false
	
	if main.options_panel.visible:
		main.options_panel.close_panel()
	
	if main.encyclopedia_panel.visible:
		main.encyclopedia_panel.visible = false
	
	if main.inventory_panel.visible:
		main.inventory_panel.visible = false
	
	if main.ranking_panel.visible:
		if main.ranking_panel.has_method("_close"):
			main.ranking_panel._close()
		else:
			main.ranking_panel.visible = false
	
func _update_ui() -> void:
	_update_currency_ui()
	_update_dps_ui()

	if main.shop_open:
		update_shop_cards()


func _update_currency_ui() -> void:
	var parts: Dictionary = main.format_doblones_parts(main.coins)
	main.coins_label.text = parts.value
	main.unidades_label.text = parts.unit


func _update_dps_ui() -> void:
	if main.dps < 1000.0:
		main.dps_label.text = "+" + ("%.2f" % main.dps).replace(".", ",") + " d/s"
		return

	var parts: Dictionary = main.format_doblones_parts(main.dps)
	main.dps_label.text = "+" + parts.value + " " + parts.unit.replace(" de doblones", "").replace(" doblones", "") + "/s"


func _refresh_current_shop_tab(tab: int) -> void:
	_block_info_hover = true

	if main.info_panel:
		main.info_panel.visible = false

	var tab_name: String = main.tab_container.get_tab_title(tab)

	if tab_name == "Peces":
		await _rebuild_tab("Peces", main.list_peces)
	elif tab_name == "Estructuras":
		await _rebuild_tab("Estructuras", main.list_estructuras)
	elif tab_name == "Únicos":
		await _rebuild_tab("Únicos", main.list_unicos)

	update_shop_cards()

	await main.get_tree().process_frame
	_block_info_hover = false

func refresh_open_shop_for_current_habitat() -> void:
	if not main.shop_open:
		return

	await _refresh_current_shop_tab(main.tab_container.current_tab)

func _rebuild_tab(tab_name: String, list: VBoxContainer) -> void:
	for c in list.get_children():
		c.queue_free()

	await main.get_tree().process_frame
	_populate_tab(tab_name, list)


func _populate_tab(tab_name: String, list: VBoxContainer) -> void:
	for k in main.ITEMS.keys():
		var id: String = String(k)
		if String(main.ITEMS[id]["tab"]) == tab_name:
			main.shop_manager.add_item_card_to_list(id, list)


func _on_tab_changed(tab: int) -> void:
	play_ui_sfx(main.SFX_CAMBIAR_TAB)
	await _refresh_current_shop_tab(tab)


func update_shop_cards() -> void:
	for card in main.list_peces.get_children():
		_refresh_card(card)

	for card in main.list_estructuras.get_children():
		_refresh_card(card)
		
	for card in main.list_unicos.get_children():
		_refresh_card(card)


func _refresh_card(card) -> void:
	var id: String = String(card.item_id)
	var p: int = main.shop_manager.get_price(id)
	var level: int = main.shop_manager.get_level(id)
	var max_level: int = main.shop_manager.get_max_level(id)

	var formatted_price: String = main.get_full_number_text(p)
	var level_text: String = str(level)

	if max_level > 0 and level >= max_level:
		formatted_price = "MAX"
		level_text = "MAX"

	card.set_unlocked(bool(main.unlocked.get(id, true)))

	if card.has_method("set_locked_text"):
		card.set_locked_text(main.shop_manager.get_locked_text(id))

	card.extra_b1 = main.shop_manager.get_tooltip_line_1(id)
	card.extra_b2 = main.shop_manager.get_tooltip_line_2(id)
	card.extra_b3 = main.shop_manager.get_tooltip_line_3(id)

	card.set_dynamic(
		p,
		formatted_price,
		main.shop_manager.get_item_effect_text(id),
		level_text
	)

	card.update_state(main.coins)


func toggle_ranking() -> void:
	var will_open: bool = not main.ranking_panel.visible

	if will_open:
		_close_overlay_panels(main.ranking_panel)
		play_ui_sfx(main.SFX_ICON_OPEN)

		if main.info_panel:
			main.info_panel.request_hide()

		if main.ranking_panel.has_method("_open"):
			main.ranking_panel._open()
		else:
			main.ranking_panel.visible = true
	else:
		play_ui_sfx(main.SFX_ICON_CLOSE)

		if main.ranking_panel.has_method("_close"):
			main.ranking_panel._close()
		else:
			main.ranking_panel.visible = false
			
func update_unique_tab_visibility() -> void:
	var should_show: bool = false

	if main.cleaning_manager != null:
		should_show = main.cleaning_manager.has_enough_unlocked_structures()

	should_show = should_show \
	or bool(main.unlocked.get("auspezio", false)) \
	or bool(main.unlocked.get("piranha", false))

	var unicos_tab_index: int = main.tab_container.get_tab_idx_from_control(
		main.tab_container.get_node("Únicos")
	)

	if unicos_tab_index != -1:
		main.tab_container.set_tab_hidden(unicos_tab_index, not should_show)
		
		
func show_save_notification() -> void:
	var label = Label.new()
	label.text = "¡Partida guardada!"
	
	# --- Configuración Visual ---
	# Aplicamos tu color personalizado #ab4b1d
	label.add_theme_color_override("font_color", Color("#ab4b1d"))
	
	# Cargamos la fuente Pirata One (asegúrate de que la ruta sea correcta)
	var custom_font = load("res://assets/fuentes/PirataOne-Regular.ttf")
	if custom_font:
		label.add_theme_font_override("font", custom_font)
	
	label.add_theme_font_size_override("font_size", 42)
	
	# Contorno para mejorar legibilidad sobre el fondo
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	
	# --- Alineación y Posición ---
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	# Capa superior
	label.z_index = 4000 
	
	main.ui_root.add_child(label)
	
	# --- Animación de desvanecimiento ---
	var tw = label.create_tween()
	
	# 1. Aparece y sube un poco (Squish effect)
	label.modulate.a = 0
	label.scale = Vector2(0.5, 0.5) # Empieza pequeño
	label.pivot_offset = label.size / 2 # Centro para el escalado
	
	tw.set_parallel(true)
	tw.tween_property(label, "modulate:a", 1.0, 0.2)
	tw.tween_property(label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "position:y", label.position.y - 40, 0.3)
	
	# 2. Pausa de 1 segundo (Lectura)
	tw.set_parallel(false)
	tw.tween_interval(1.0)
	
	# 3. Desaparece flotando hacia arriba
	tw.set_parallel(true)
	tw.tween_property(label, "modulate:a", 0.0, 0.7)
	tw.tween_property(label, "position:y", label.position.y - 60, 0.7)
	
	# 4. Limpieza de memoria
	tw.set_parallel(false)
	tw.finished.connect(label.queue_free)
	
# Comprueba si el usuario está en la pantalla de Login/Registro
func is_auth_panel_open() -> bool:
	# Verificamos si el panel de perfil está visible y si está mostrando la vista de autenticación
	return main.profile_panel.visible and main.profile_panel.auth_view.visible

# Comprueba si hay CUALQUIER cosa abierta para la lógica del ESC
func has_any_panel_open() -> bool:
	return main.stats_panel.visible or \
		   main.ranking_panel.visible or \
		   main.profile_panel.visible or \
		   main.encyclopedia_panel.visible or \
		   main.inventory_panel.visible or \
		   main.options_panel.visible or \
		   main.shop_open # En tu script la tienda usa esta variable

func has_exclusive_panel_open() -> bool:
	return main.shop_open or \
		   main.stats_panel.visible or \
		   main.ranking_panel.visible or \
		   main.profile_panel.visible or \
		   main.encyclopedia_panel.visible or \
		   main.inventory_panel.visible
