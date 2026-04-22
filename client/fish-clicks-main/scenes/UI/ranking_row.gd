extends HBoxContainer

# Ahora coinciden exactamente con tu captura: RankLabel, NameLabel, ValueLabel
@onready var rank_label = $RankLabel
@onready var name_label = $NameLabel
@onready var value_label = $ValueLabel

func set_data(pos: int, nickname: String, score: String, _foto_base64: String):
	# Seteamos los textos
	rank_label.text = str(pos) + "."
	name_label.text = nickname
	value_label.text = score
