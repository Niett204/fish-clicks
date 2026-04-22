extends Node
class_name CleaningManager

var main: Node = null

var inactivity_time: float = 0.0 # Acumula segundos
@export var inactivity_threshold: float = 60.0 # Tiempo necesario para que paparezca el evento
var cleaning_event_available: bool = false # Evita que el evento se dispare varias veces seguidas
var fish_mode_manager: FishModeManager = null # Función de fish_mode_manager que devuelve si está
											  # en modo pecera o no
var shop_manager: ShopManager = null
var cleaning_event_layer: CleaningEventLayer = null
var ui_manager: UiManager = null

# Variables para las estadísticas 
var total_dirt_spots_cleaned: int = 0 # Número de manchas limpiadas
var cleaning_events_completed: int = 0 # Número de minijuegos completados

func setup(main_ref: Node) -> void:
	main = main_ref
	fish_mode_manager = main.fish_mode_manager
	shop_manager = main.shop_manager
	cleaning_event_layer = main.cleaning_event_layer
	ui_manager = main.ui_manager

	if cleaning_event_layer != null:
		cleaning_event_layer.setup_cleaning_layer(self)

	if cleaning_event_layer != null and not cleaning_event_layer.cleaning_finished_successfully.is_connected(_on_cleaning_finished_successfully):
		cleaning_event_layer.cleaning_finished_successfully.connect(_on_cleaning_finished_successfully)

func _ready() -> void:
	pass 

func _process(delta: float) -> void:
	if should_count_inactivity():
		inactivity_time += delta

	if can_activate_cleaning_event():
		activate_cleaning_event()
		
# Reinicia el contador cada vez que el jugador interactua con el juego	
func register_player_activity() -> void:
	inactivity_time = 0.0
	print("Actividad detectada -> contador reiniciado")

# Función que dice si el tiempo de inactividad debe seguir incrementándose o no
# El tiempo de inactividad no incrementa si estás en modo pecera o en el minijuego de limpieza	
func should_count_inactivity() -> bool:
	if cleaning_event_available:
		return false

	if fish_mode_manager != null and fish_mode_manager.is_fish_mode_active():
		return false

	return true

# Comprueba si al menos hay 3 estructuras desbloqueadas
func has_enough_unlocked_structures() -> bool:
	if shop_manager == null:
		return false

	return shop_manager.get_total_unlocked_structures_count() >= 3

# Comprueba si se puede activar el minijuego
func can_activate_cleaning_event() -> bool:
	# No se activa si no ha llegado al tiempo de inactividad definido
	if inactivity_time < inactivity_threshold:
		return false
	# No se activa si no tienes al menos 3 estructuras desbloqueadas
	if not has_enough_unlocked_structures():
		return false
	# No se activa si estás en modo pecera
	if fish_mode_manager != null and fish_mode_manager.is_fish_mode_active():
		return false

	return true

# Activador del minijuego de limpieza
func activate_cleaning_event() -> void:
	cleaning_event_available = true
	inactivity_time = 0.0
	
	if ui_manager != null:
		ui_manager.close_all_panels()

	if cleaning_event_layer != null:
		cleaning_event_layer.show_event()

	print("Evento de limpieza disponible")

func _on_cleaning_finished_successfully() -> void:
	register_cleaning_event_completed()
	deactivate_cleaning_event()
	
func deactivate_cleaning_event() -> void:
	cleaning_event_available = false
	inactivity_time = 0.0

	if cleaning_event_layer != null:
		cleaning_event_layer.hide_event()

func get_coin_penalty_multiplier() -> float:
	if cleaning_event_available and cleaning_event_layer != null and cleaning_event_layer.has_dirt_remaining():
		# La penalización es la mitad de las ganancias pasivas
		return 0.5

	return 1.0

# Funciones para actualizar las estadísticas
func register_dirt_spot_cleaned() -> void:
	total_dirt_spots_cleaned += 1

func register_cleaning_event_completed() -> void:
	cleaning_events_completed += 1
