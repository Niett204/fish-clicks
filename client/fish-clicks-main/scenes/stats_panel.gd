extends Control

signal close_requested

@onready var btn_close: TextureButton = $BtnClose

@onready var label_clicks_value: Label = $MarginContainer/MarginContainer/HBoxContainer/LeftPage/StatsList/StatRow_Clicks/LabelStat_Clicks_Value
@onready var label_peces_value: Label = $MarginContainer/MarginContainer/HBoxContainer/LeftPage/StatsList/StatRow_Peces/LabelStat_Peces_Value
@onready var label_estructuras_value: Label = $MarginContainer/MarginContainer/HBoxContainer/LeftPage/StatsList/StatRow_Estructuras/LabelStat_Estructuras_Value
@onready var label_doblones_value: Label = $MarginContainer/MarginContainer/HBoxContainer/LeftPage/StatsList/StatRow_Doblones/LabelStat_Doblones_Value
@onready var label_peces_especiales_value: Label = $MarginContainer/MarginContainer/HBoxContainer/LeftPage/StatsList/StatRow_PecesEspeciales/LabelStat_PecesEspeciales_Value
@onready var label_tiempo_value: Label = $MarginContainer/MarginContainer/HBoxContainer/LeftPage/StatsList/StatRow_TiempoJuego/LabelStat_TiempoJuego_Value
@onready var label_fecha_inicio_value: Label = $MarginContainer/MarginContainer/HBoxContainer/LeftPage/StatsList/StatRow_FechaInicio/LabelStat_FechaInicio_Value
@onready var label_dps_value: Label = $MarginContainer/MarginContainer/HBoxContainer/LeftPage/StatsList/StatRow_DPS/LabelStat_DPS_Value
@onready var label_dpc_value: Label = $MarginContainer/MarginContainer/HBoxContainer/LeftPage/StatsList/StatRow_DPC/LabelStat_DPC_Value

@onready var stat_row_dirt_cleaned: Control = $MarginContainer/MarginContainer/HBoxContainer/LeftPage/StatsList/StatRow_Manchas
@onready var label_dirt_cleaned_value: Label = $MarginContainer/MarginContainer/HBoxContainer/LeftPage/StatsList/StatRow_Manchas/LabelStat_Manchas_Value
@onready var stat_row_cleaning_events: Control = $MarginContainer/MarginContainer/HBoxContainer/LeftPage/StatsList/StatRow_EventosLimpieza
@onready var label_cleaning_events_value: Label = $MarginContainer/MarginContainer/HBoxContainer/LeftPage/StatsList/StatRow_EventosLimpieza/LabelStat_EventosLimpieza_Value

@onready var stat_row_alien_wins: Control = $MarginContainer/MarginContainer/HBoxContainer/LeftPage/StatsList/StatRow_AlienWin
@onready var label_alien_wins_value: Label = $MarginContainer/MarginContainer/HBoxContainer/LeftPage/StatsList/StatRow_AlienWin/LabelStat_AlienWin_Value
@onready var stat_row_alien_losses: Control = $MarginContainer/MarginContainer/HBoxContainer/LeftPage/StatsList/StatRow_AlienLose
@onready var label_alien_losses_value: Label = $MarginContainer/MarginContainer/HBoxContainer/LeftPage/StatsList/StatRow_AlienLose/LabelStat_AlienLose_Value

@onready var label_count: Label = $AchievementsHeader/LabelCount
@onready var label_percent: Label = $AchievementsHeader/LabelPercent

@onready var achievements_grid: GridContainer = $MarginContainer/MarginContainer/HBoxContainer/RightPage/AchievementsScroll/AchievementsCenter/AchievementsGrid

@onready var achievement_info_panel: PanelContainer = $AchievementInfoPanel
@onready var label_achievement_title: Label = $AchievementInfoPanel/MarginContainer/VBoxContainer/LabelAchievementTitle
@onready var label_achievement_desc: Label = $AchievementInfoPanel/MarginContainer/VBoxContainer/LabelAchievementDesc
@onready var label_achievement_condition: Label = $AchievementInfoPanel/MarginContainer/VBoxContainer/LabelAchievementCondition

const QUESTION_ICON := preload("res://assets/misc/interrogante.png")

func _ready() -> void:
	visible = false
	achievement_info_panel.visible = false
	achievement_info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	achievement_info_panel.top_level = true
	achievement_info_panel.z_index = 1000

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.93, 0.84, 0.68, 0.96)
	style.border_color = Color("#7b4a24")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10

	achievement_info_panel.add_theme_stylebox_override("panel", style)

	var style_grabber := StyleBoxFlat.new()
	style_grabber.bg_color = Color("#aa4b21")
	style_grabber.border_color = Color("#7b4a24")
	style_grabber.border_width_left = 2
	style_grabber.border_width_top = 2
	style_grabber.border_width_right = 2
	style_grabber.border_width_bottom = 2
	style_grabber.corner_radius_top_left = 6
	style_grabber.corner_radius_top_right = 6
	style_grabber.corner_radius_bottom_left = 6
	style_grabber.corner_radius_bottom_right = 6

	var style_grabber_highlight := StyleBoxFlat.new()
	style_grabber_highlight.bg_color = Color("#d89252")
	style_grabber_highlight.border_color = Color("#7b4a24")
	style_grabber_highlight.border_width_left = 2
	style_grabber_highlight.border_width_top = 2
	style_grabber_highlight.border_width_right = 2
	style_grabber_highlight.border_width_bottom = 2
	style_grabber_highlight.corner_radius_top_left = 6
	style_grabber_highlight.corner_radius_top_right = 6
	style_grabber_highlight.corner_radius_bottom_left = 6
	style_grabber_highlight.corner_radius_bottom_right = 6

	var style_bg := StyleBoxFlat.new()
	style_bg.bg_color = Color(0.25, 0.16, 0.08, 0.35)
	style_bg.corner_radius_top_left = 6
	style_bg.corner_radius_top_right = 6
	style_bg.corner_radius_bottom_left = 6
	style_bg.corner_radius_bottom_right = 6

	var v_scroll: VScrollBar = $MarginContainer/MarginContainer/HBoxContainer/RightPage/AchievementsScroll.get_v_scroll_bar()

	v_scroll.custom_minimum_size.x = 12

	v_scroll.add_theme_stylebox_override("grabber", style_grabber)
	v_scroll.add_theme_stylebox_override("grabber_highlight", style_grabber_highlight)
	v_scroll.add_theme_stylebox_override("grabber_pressed", style_grabber_highlight)
	v_scroll.add_theme_stylebox_override("scroll", style_bg)

	btn_close.pressed.connect(_on_btn_close_pressed)
	btn_close.mouse_entered.connect(_on_btn_close_mouse_entered)
	btn_close.mouse_exited.connect(_on_btn_close_mouse_exited)
	btn_close.button_down.connect(_on_btn_close_button_down)
	btn_close.button_up.connect(_on_btn_close_button_up)

func _on_close_pressed() -> void:
	visible = false
	close_requested.emit()

func set_stats_data(data: Dictionary) -> void:
	label_clicks_value.text = str(data.get("total_clicks", 0))
	label_peces_value.text = str(data.get("total_fish", 0))
	label_estructuras_value.text = str(data.get("total_structures", 0))
	label_doblones_value.text = str(data.get("total_doblones", "0"))
	label_peces_especiales_value.text = str(data.get("total_special_fish", 0))
	label_tiempo_value.text = str(data.get("play_time", "00:00:00"))
	label_fecha_inicio_value.text = str(data.get("start_date", "DD/MM/AAAA"))
	label_dps_value.text = str(data.get("dps", "0 d/s"))
	label_dpc_value.text = str(data.get("dpc", "0 d/c"))
	
	label_dirt_cleaned_value.text = str(data.get("total_dirt_cleaned", 0))
	label_cleaning_events_value.text = str(data.get("cleaning_events_completed", 0))
	# Solo se verán los stats de limpieza una vez se desbloquea el minijuego
	var show_cleaning_stats: bool = bool(data.get("show_cleaning_stats", false))
	stat_row_dirt_cleaned.visible = show_cleaning_stats
	stat_row_cleaning_events.visible = show_cleaning_stats
	
	label_alien_wins_value.text = str(data.get("alien_minigame_wins", 0))
	label_alien_losses_value.text = str(data.get("alien_minigame_losses", 0))
	# Solo se verán los stats del alien una vez se desbloquea el minijuego
	var show_alien_stats: bool = bool(data.get("show_alien_stats", false))
	stat_row_alien_wins.visible = show_alien_stats
	stat_row_alien_losses.visible = show_alien_stats

func set_achievements_progress(unlocked_count: int, total_count: int) -> void:
	label_count.text = "%d/%d" % [unlocked_count, total_count]

	var percent := 0.0
	if total_count > 0:
		percent = (float(unlocked_count) / float(total_count)) * 100.0

	label_percent.text = "%d%%" % int(round(percent))

func set_achievements_data(items: Array) -> void:
	for child in achievements_grid.get_children():
		child.queue_free()

	for item in items:
		var is_unlocked := bool(item.get("unlocked", false))
		var is_hidden := bool(item.get("hidden", false))

		if is_hidden and not is_unlocked:
			continue
		
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(50, 50)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.focus_mode = Control.FOCUS_NONE
		slot.text = ""

		var style := StyleBoxFlat.new()
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_right = 8
		style.corner_radius_bottom_left = 8
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2

		if is_hidden and is_unlocked:
			style.border_color = Color("#9c63e0")
			style.bg_color = Color(0.35, 0.08, 0.08, 0.16)
		else:
			style.border_color = Color("#7b4a24")
			style.bg_color = Color(1, 1, 1, 0.06) if is_unlocked else Color(0, 0, 0, 0.10)

		slot.add_theme_stylebox_override("normal", style)
		slot.add_theme_stylebox_override("hover", style)
		slot.add_theme_stylebox_override("pressed", style)
		slot.add_theme_stylebox_override("focus", style)
		slot.add_theme_color_override("font_color", Color(0, 0, 0, 0))

		var icon := TextureRect.new()
		icon.texture = item.get("icon", null) if is_unlocked else QUESTION_ICON
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = Color(1, 1, 1, 1)

		slot.add_child(icon)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 4
		icon.offset_top = 4
		icon.offset_right = -4
		icon.offset_bottom = -4

		var title := String(item.get("title", ""))
		var condition := String(item.get("condition", ""))
		var desc := String(item.get("desc", ""))

		if is_unlocked:
			slot.mouse_entered.connect(_on_achievement_hovered.bind(slot, title, condition, desc))
			slot.mouse_exited.connect(_on_achievement_unhovered)

		achievements_grid.add_child(slot)

func _on_achievement_hovered(slot: Control, title: String, condition: String, desc: String) -> void:
	show_achievement_info(slot, title, condition, desc)

func _on_achievement_unhovered() -> void:
	hide_achievement_info()

func _on_btn_close_pressed() -> void:
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

func show_achievement_info(slot: Control, title: String, condition: String, desc: String) -> void:
	label_achievement_title.text = title
	label_achievement_condition.text = condition
	label_achievement_desc.text = desc

	achievement_info_panel.visible = true
	achievement_info_panel.modulate = Color(1, 1, 1, 0)
	achievement_info_panel.move_to_front()

	# fijamos ancho y reseteamos alto
	achievement_info_panel.size = Vector2(250, 0)

	# importante: fuerza recálculo del layout
	label_achievement_desc.custom_minimum_size.y = 0
	label_achievement_desc.size.y = 0
	achievement_info_panel.reset_size()

	await get_tree().process_frame

	achievement_info_panel.reset_size()

	var slot_rect := slot.get_global_rect()
	var panel_size := achievement_info_panel.size
	var viewport_size := get_viewport_rect().size

	var pos := Vector2(
		slot_rect.position.x + slot_rect.size.x + 5,
		slot_rect.position.y - 22
	)

	if pos.y + panel_size.y > viewport_size.y - 12:
		pos.y = viewport_size.y - panel_size.y - 12

	pos.x = clamp(pos.x, 12.0, viewport_size.x - panel_size.x - 12.0)
	pos.y = clamp(pos.y, 12.0, viewport_size.y - panel_size.y - 12.0)

	achievement_info_panel.global_position = pos

	var t := create_tween()
	t.tween_property(achievement_info_panel, "modulate:a", 1.0, 0.12)

func hide_achievement_info() -> void:
	achievement_info_panel.visible = false
