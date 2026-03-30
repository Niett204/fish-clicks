extends RefCounted
class_name AchievementDefs

const ACHIEVEMENT_DEFS := {
	# =========================
	# CLICKS AL COFRE
	# =========================
	"clicks_1": {
		"title": "Primer botín",
		"desc": "Si tuviese un doblón por cada vez que hiciese un click… Ah. Sí, eso es lo que está pasando.",
		"kind": "clicks",
		"target": 1,
		"condition": "Clica 1 vez el cofre",
		"icon": preload("res://assets/logros/clicks_1.png")
	},
	"clicks_100": {
		"title": "Empieza el vicio, ¿eh?",
		"desc": "El primer paso es admitir el problema.",
		"kind": "clicks",
		"target": 100,
		"condition": "Clica 100 veces el cofre",
		"icon": preload("res://assets/logros/clicks_100.png")
	},
	"clicks_1000": {
		"title": "Fiebre del doblón",
		"desc": "Cada domingo a las 16h, solo en Doblon Max… ¿Era así?",
		"kind": "clicks",
		"target": 1000,
		"condition": "Clica 1000 veces el cofre",
		"icon": preload("res://assets/logros/clicks_1000.png")
	},
	"clicks_10000": {
		"title": "Solo un click más…",
		"desc": "Puedo dejarlo cuando quiera.",
		"kind": "clicks",
		"target": 10000,
		"condition": "Clica 10000 veces el cofre",
		"icon": preload("res://assets/logros/clicks_10000.png")
	},
	"clicks_100000": {
		"title": "Necesito más clicks",
		"desc": "¿Trabajar? No, clicar.",
		"kind": "clicks",
		"target": 100000,
		"condition": "Clica 100000 veces el cofre",
		"icon": preload("res://assets/logros/clicks_100000.png")
	},
	"clicks_1000000": {
		"title": "Click Master 3000",
		"desc": "Dime la verdad, ¿usas autoclicker, a que sí?",
		"kind": "clicks",
		"target": 1000000,
		"condition": "Clica 1000000 veces el cofre",
		"icon": preload("res://assets/logros/clicks_1000000.png")
	},

	# =========================
	# DOBLONES
	# =========================
	"coins_100": {
		"title": "Marinero",
		"desc": "TODO",
		"kind": "coins",
		"target": 100.0,
		"condition": "Consigue 100 doblones",
		"icon": preload("res://assets/logros/coins_100.png")
	},
	"coins_1000": {
		"title": "Contramaestre",
		"desc": "TODO",
		"kind": "coins",
		"target": 1000.0,
		"condition": "Consigue 1000 doblones",
		"icon": preload("res://assets/logros/coins_1000.png")
	},
	"coins_10000": {
		"title": "Navegante",
		"desc": "TODO",
		"kind": "coins",
		"target": 10000.0,
		"condition": "Consigue 10000 doblones",
		"icon": preload("res://assets/logros/coins_10000.png")
	},
	"coins_100000": {
		"title": "Intendente",
		"desc": "TODO",
		"kind": "coins",
		"target": 100000.0,
		"condition": "Consigue 100000 doblones",
		"icon": preload("res://assets/logros/coins_100000.png")
	},
	"coins_1000000": {
		"title": "Capitán",
		"desc": "TODO",
		"kind": "coins",
		"target": 1000000.0,
		"condition": "Consigue 1000000 doblones",
		"icon": preload("res://assets/logros/coins_1000000.png")
	},

	# =========================
	# NÚMERO DE PECES
	# =========================
	"fish_30": {
		"title": "TODO",
		"desc": "No, no es abuso animal, les gusta estar en las bolsas del inventario. Te lo juro. No lo pienses más. Sigue comprando más peces.",
		"kind": "fish",
		"target": 30,
		"condition": "Consigue 30 peces",
		"icon": preload("res://assets/peces/doblon.png")
	},

	# =========================
	# NÚMERO DE ESTRUCTURAS
	# =========================
	"structures_1": {
		"title": "acuario.jpg",
		"desc": "TODO",
		"kind": "structures",
		"target": 1,
		"condition": "Desbloquea 1 estructura",
		"icon": preload("res://assets/estructuras/vallisneria/vallisneria_mini.png")
	},
	"structures_2": {
		"title": "acuario_final.jpg",
		"desc": "No hagas más cambios.",
		"kind": "structures",
		"target": 2,
		"condition": "Desbloquea 2 estructuras",
		"icon": preload("res://assets/estructuras/vallisneria/vallisneria_small.png")
	},
	"structures_3": {
		"title": "acuario_final_FINAL.jpg",
		"desc": "Bueno, solo un cambio más.",
		"kind": "structures",
		"target": 3,
		"condition": "Desbloquea 3 estructuras",
		"icon": preload("res://assets/estructuras/anubia/anubia_small.png")
	},
	"structures_4": {
		"title": "acuario_final_FINAL(1).jpg",
		"desc": "El último cambio, te lo juro.",
		"kind": "structures",
		"target": 4,
		"condition": "Desbloquea 4 estructuras",
		"icon": preload("res://assets/estructuras/anubia/anubia_medium.png")
	},
	"structures_5": {
		"title": "acuario_final_FINAL(1)_de_verdad.jpg",
		"desc": "Ahora ya sí, el definitivo.",
		"kind": "structures",
		"target": 5,
		"condition": "Desbloquea 5 estructuras",
		"icon": preload("res://assets/estructuras/anubia/anubia_large.png")
	},

	# =========================
	# DOBLONES INVERTIDOS EN ESTRUCTURAS
	# =========================
	"structures_spent_x": {
		"title": "Comprador compulsivo",
		"desc": "TODO",
		"kind": "structures_spent",
		"target": 10000.0,
		"condition": "Invierte X doblones en estructuras",
		"icon": preload("res://assets/estructuras/cofre_cerrado.png")
	},

	# =========================
	# OCULTOS
	# =========================
	"achievement_first": {
		"title": "Logro",
		"desc": "Lo has logrado. Enhorabuena.",
		"kind": "achievements_unlocked",
		"target": 1,
		"condition": "Obtén un logro",
		"icon": preload("res://assets/peces/doblon_shiny.png"),
		"hidden": true
	},
	"shiny_first": {
		"title": "No es diferente, solo es especial",
		"desc": "Celebramos nuestras diferencias.",
		"kind": "shiny_ever",
		"target": 1,
		"condition": "Consigue el primer pez especial",
		"icon": preload("res://assets/peces/doblon_shiny.png"),
		"hidden": true
	},
	"all_aquarium_shiny": {
		"title": "peZes",
		"desc": "Al menos estos no te comen el cerebro. Creo. No me hagas demasiado caso, mejor no te acerques mucho.",
		"kind": "all_aquarium_shiny",
		"target": 1,
		"condition": "Llena el acuario solo con peces especiales",
		"icon": preload("res://assets/peces/tiza_shiny.png"),
		"hidden": true
	},
	"all_species_in_aquarium": {
		"title": "Fiesta en la pecera",
		"desc": "TODO",
		"kind": "all_species_in_aquarium",
		"target": 1,
		"condition": "Pon un pez de cada tipo en el acuario",
		"icon": preload("res://assets/peces/rufinus.png"),
		"hidden": true
	},
	"alien_jump": {
		"title": "¡¡¡SALTA!!!",
		"desc": "TODO",
		"kind": "alien_clicked",
		"target": 1,
		"condition": "Pulsa el alien cuando aparezca, y saltará",
		"icon": preload("res://assets/ui/iconos/icono_hud_abierto.png"),
		"hidden": true
	},
	"better_luck_next_time": {
		"title": "Better luck next time!",
		"desc": "TODO",
		"kind": "random_tick",
		"target": 1,
		"condition": "Obtenido con una probabilidad del 0,01% en cada tick del juego",
		"icon": preload("res://assets/ui/iconos/icono_hud_abierto.png"),
		"hidden": true
	},
	"encyclopedia_complete": {
		"title": "Pezología 101",
		"desc": "Abrid todos el libro por la página 394.",
		"kind": "encyclopedia_complete",
		"target": 1,
		"condition": "Completa la enciclopedia de peces",
		"icon": preload("res://assets/ui/iconos/icono_hud_abierto.png"),
		"hidden": true
	},
	"profile_clicked_100": {
		"title": "YO.",
		"desc": "TODO",
		"kind": "profile_clicks",
		"target": 100,
		"condition": "Pulsa 100 veces en la foto de perfil",
		"icon": preload("res://assets/ui/iconos/icono_hud_abierto.png"),
		"hidden": true
	},
	"volume_slider_spam": {
		"title": "¿Me oyes? ¿Me escuchas?...¿Me sientes?",
		"desc": "TODO",
		"kind": "volume_slider_spam",
		"target": 1,
		"condition": "Cambia el nivel del sonido general muy rápidamente varias veces",
		"icon": preload("res://assets/ui/iconos/icono_hud_abierto.png"),
		"hidden": true
	},
	"same_species_full_aquarium": {
		"title": "Piscifactoría",
		"desc": "Más te vale que cumpla con las regulaciones de densidad, oxígeno, temperatura, calidad del agua…",
		"kind": "same_species_full_aquarium",
		"target": 1,
		"condition": "Llena el acuario de peces de la misma especie",
		"icon": preload("res://assets/peces/doblon.png"),
		"hidden": true
	},
	"annoy_fish_repeatedly": {
		"title": "Toca-huevas",
		"desc": "No toques, ¿por qué tocas?",
		"kind": "annoy_fish",
		"target": 50,
		"condition": "Molesta a los peces repetidamente en el acuario",
		"icon": preload("res://assets/peces/sobrasada.png"),
		"hidden": true
	},
}
