extends Control

signal close_requested

@onready var list_container = $Panel/ScrollContainer/VBoxContainer
@export var row_scene: PackedScene # Aquí asignarás una escena simple con Labels

func _ready():
	GlobalData.ranking_received.connect(_on_ranking_data)
	GlobalData.ranking_failed.connect(func(err): print("Error Ranking: ", err))
	
	# Conexión de botones internos del panel (Clicks / Dinero)
	$Panel/BtnTabClicks.pressed.connect(func(): _load_ranking("clicks"))
	$Panel/BtnTabMoney.pressed.connect(func(): _load_ranking("money"))
	$Panel/BtnClose.pressed.connect(func(): close_requested.emit())

func _open():
	_load_ranking("clicks") # Carga por defecto

func _load_ranking(type: String):
	# Limpiar lista
	for child in list_container.get_children():
		child.queue_free()
	
	# Mostrar un texto de "Cargando..." si quieres
	GlobalData.fetch_ranking(type)

func _on_ranking_data(type: String, data: Array):
	# Limpiar por si acaso
	for child in list_container.get_children():
		child.queue_free()
		
	for i in range(data.size()):
		var entry = data[i]
		var row = row_scene.instantiate()
		list_container.add_child(row)
		
		# Ajusta estos nombres según los nodos de tu RankingRow.tscn
		row.get_node("RankLabel").text = str(i + 1) + "."
		row.get_node("NameLabel").text = entry.get("nickname", "Anónimo")
		
		# Formatear el valor según el tipo
		var value = entry.get("value", 0)
		if type == "money":
			row.get_node("ValueLabel").text = str(snapped(value, 0.01)) + " $"
		else:
			row.get_node("ValueLabel").text = str(value) + " clics"
