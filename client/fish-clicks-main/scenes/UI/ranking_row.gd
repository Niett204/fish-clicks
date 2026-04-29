extends HBoxContainer

# Ahora coinciden exactamente con tu captura: RankLabel, NameLabel, ValueLabel
@onready var rank_label = $RankLabel
@onready var name_label = $NameLabel
@onready var value_label = $ValueLabel

func set_data(pos: int, nickname: String, score: String, _foto_base64: String):
	rank_label.text = str(pos) + "."
	name_label.text = nickname
	value_label.text = score
	
	if nickname == GlobalData.user_nickname:
		# Esto cambia el color de la fuente directamente, ignorando el marrón del inspector
		name_label.add_theme_color_override("font_color", Color(1, 1, 0))
		rank_label.add_theme_color_override("font_color", Color(1, 1, 0))
		value_label.add_theme_color_override("font_color", Color(1, 1, 0))
	else:
		# Opcional: Volver al color original si la fila se recicla
		name_label.remove_theme_color_override("font_color")
		rank_label.remove_theme_color_override("font_color")
		value_label.remove_theme_color_override("font_color")
