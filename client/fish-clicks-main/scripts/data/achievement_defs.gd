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
		"desc": "Un par de doblones en el bolsillo y más hambre que rumbo. Todo empieza aquí… aunque aún no lo sepas.",
		"kind": "coins",
		"target": 100.0,
		"condition": "Consigue 100 doblones",
		"icon": preload("res://assets/logros/coins_100.png")
	},
	"coins_1000": {
		"title": "Contramaestre",
		"desc": "Ya no limpias la cubierta, ahora das órdenes. Empiezas a notar algo peligroso… te gusta que te escuchen.",
		"kind": "coins",
		"target": 1000.0,
		"condition": "Consigue 1000 doblones",
		"icon": preload("res://assets/logros/coins_1000.png")
	},
	"coins_10000": {
		"title": "Navegante",
		"desc": "El mar se abre ante ti y tu nombre empieza a sonar. Dicen que tienes talento… tú empiezas a creértelo.",
		"kind": "coins",
		"target": 10000.0,
		"condition": "Consigue 10000 doblones",
		"icon": preload("res://assets/logros/coins_10000.png")
	},
	"coins_100000": {
		"title": "Intendente",
		"desc": "El oro fluye y las decisiones pesan. Ya no dudas, solo decides. Quizá demasiado rápido.",
		"kind": "coins",
		"target": 100000.0,
		"condition": "Consigue 100000 doblones",
		"icon": preload("res://assets/logros/coins_100000.png")
	},
	"coins_1000000": {
		"title": "Capitán",
		"desc": "Un millón de doblones. El barco es tuyo. La tripulación también. Y en algún punto… olvidaste quién eras antes de mandar.",
		"kind": "coins",
		"target": 1000000.0,
		"condition": "Consigue 1000000 doblones",
		"icon": preload("res://assets/logros/coins_1000000.png")
	},

	# =========================
	# NÚMERO DE PECES
	# =========================
	"fish_30": {
		"title": "Totalmente bajo control",
		"desc": "No, no es abuso animal, les gusta estar en las bolsas del inventario. Te lo juro. No lo pienses más. Sigue comprando más peces.",
		"kind": "fish",
		"target": 30,
		"condition": "Consigue 30 peces",
		"icon": preload("res://assets/logros/fish_30.png")
	},

	# =========================
	# NÚMERO DE ESTRUCTURAS
	# =========================
	"structures_1": {
		"title": "acuario.jpg",
		"desc": "Solo voy a poner una cosita rápida… y listo.",
		"kind": "structures",
		"target": 1,
		"condition": "Desbloquea 1 estructura",
		"icon": preload("res://assets/logros/acuario_jpg.png")
	},
	"structures_2": {
		"title": "acuario_final.jpg",
		"desc": "No hagas más cambios.",
		"kind": "structures",
		"target": 2,
		"condition": "Desbloquea 2 estructuras",
		"icon": preload("res://assets/logros/acuario_final_jpg.png")
	},
	"structures_3": {
		"title": "acuario_final_FINAL.jpg",
		"desc": "Bueno, solo un cambio más.",
		"kind": "structures",
		"target": 3,
		"condition": "Desbloquea 3 estructuras",
		"icon": preload("res://assets/logros/acuario_final_FINAL_jpg.png")
	},
	"structures_4": {
		"title": "acuario_final_FINAL(1).jpg",
		"desc": "El último cambio, te lo juro.",
		"kind": "structures",
		"target": 4,
		"condition": "Desbloquea 4 estructuras",
		"icon": preload("res://assets/logros/acuario_final_FINAL(1)_jpg.png")
	},
	"structures_5": {
		"title": "acuario_final_FINAL(1)_de_verdad.jpg",
		"desc": "Ahora ya sí, el definitivo.",
		"kind": "structures",
		"target": 5,
		"condition": "Desbloquea 5 estructuras",
		"icon": preload("res://assets/logros/acuario_final_FINAL(1)_de_verdad_jpg.png")
	},

	# =========================
	# DOBLONES INVERTIDOS EN ESTRUCTURAS
	# =========================
	"structures_spent_x": {
		"title": "Comprador compulsivo",
		"desc": "No necesitas otra planta. Ni otra roca. Ni otra decoración. Pero eso nunca te ha detenido antes.",
		"kind": "structures_spent",
		"target": 10000.0,
		"condition": "Invierte X doblones en estructuras",
		"icon": preload("res://assets/estructuras/cofre_cerrado.png")
	},
	# =========================
	# LIMPIEZA DE LA PECERA
	# =========================
	"clean_aquarium_1": {
		"title": "Menos mal que no era moho.",
		"desc": "Las algas no te han invadido, ¡progresas!",
		"kind": "aquarium_cleaned",
		"target": 1,
		"condition": "Limpia por primera vez la pecera",
		"icon": preload("res://assets/logros/limpiar_1.png")
	},
	"clean_aquarium_5": {
		"title": "Como los chorros del oro.",
		"desc": "Deberías cambiar el estropajo a estas alturas.",
		"kind": "aquarium_cleaned",
		"target": 5,
		"condition": "Limpia 5 veces la pecera",
		"icon": preload("res://assets/logros/limpiar_5.png")
	},
	"clean_aquarium_10": {
		"title": "Ya lo haces por gusto, ¿no?",
		"desc": "Ya puedes ver los poros de los peces.",
		"kind": "aquarium_cleaned",
		"target": 10,
		"condition": "Limpia 10 veces la pecera",
		"icon": preload("res://assets/logros/limpiar_10.png")
	},
	"clean_aquarium_50": {
		"title": "Tienes un problema.",
		"desc": "Puede que sea TOC, míratelo.",
		"kind": "aquarium_cleaned",
		"target": 50,
		"condition": "Limpia 50 veces la pecera",
		"icon": preload("res://assets/logros/limpiar_50.png")
	},
	"clean_aquarium_100": {
		"title": "Vas a desgastar el cristal.",
		"desc": "Ahora los peces te ven los poros a ti.",
		"kind": "aquarium_cleaned",
		"target": 100,
		"condition": "Limpia 100 veces la pecera",
		"icon": preload("res://assets/logros/limpiar_100.png")
	},
	# =========================
	# LIMPIEZA AUTOMÁTICA
	# =========================
	"auto_cleaning_unlocked": {
		"title": "Trabajo en equipo.",
		"desc": "El equipo trabaja. Tú… supervisas.",
		"kind": "auto_cleaning_unlocked",
		"target": 1,
		"condition": "Consigue la limpieza automática",
		"icon": preload("res://assets/logros/limpiar_auto.png")
	},
		# =========================
	# MINIJUEGO DEL ALIEN
	# =========================
	"alien_lose_1": {
		"title": "Houston, tenemos un problema.",
		"desc": "¿Tienes un plan B?",
		"kind": "alien_losses",
		"target": 1,
		"condition": "Pierde 1 vez el minijuego del alien",
		"icon": preload("res://assets/logros/perder_1.png")
	},
	"alien_win_1": {
		"title": "Contacto hostil neutralizado.",
		"desc": "Con los peces no se juega.",
		"kind": "alien_wins",
		"target": 1,
		"condition": "Gana 1 vez el minijuego del alien",
		"icon": preload("res://assets/logros/ganar_1.png")
	},
	"alien_lose_10": {
		"title": "Skill issue.",
		"desc": "¿Y si el problema no es el alien?",
		"kind": "alien_losses",
		"target": 10,
		"condition": "Pierde 10 veces el minijuego del alien",
		"icon": preload("res://assets/logros/perder_10.png")
	},
	"alien_win_10": {
		"title": "I always come back.",
		"desc": "Has vuelto. Una y otra y otra vez.",
		"kind": "alien_wins",
		"target": 10,
		"condition": "Gana 10 veces el minijuego del alien",
		"icon": preload("res://assets/logros/ganar_10.png")
	},
	"alien_no_hit": {
		"title": "No Hit / Any%",
		"desc": "Is this your perfect victory?",
		"kind": "alien_no_hit",
		"target": 1,
		"condition": "Gana el minijuego del alien sin recibir daño",
		"icon": preload("res://assets/logros/no_hit.png")
	},
	"alien_egg": {
		"title": "¿De dónde vienen los peces?",
		"desc": "La vida se abre camino.",
		"kind": "alien_egg",
		"target": 1,
		"condition": "Obtén el huevo misterioso",
		"icon": preload("res://assets/logros/huevo_alien.png")
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
		"icon": preload("res://assets/logros/logro.png"),
		"hidden": true
	},
	"shiny_first": {
		"title": "No es diferente, solo es especial",
		"desc": "Celebramos nuestras diferencias.",
		"kind": "shiny_ever",
		"target": 1,
		"condition": "Consigue el primer pez especial",
		"icon": preload("res://assets/logros/shiny_1.png"),
		"hidden": true
	},
	"all_aquarium_shiny": {
		"title": "peZes",
		"desc": "Al menos estos no te comen el cerebro. Creo. No me hagas demasiado caso, mejor no te acerques mucho.",
		"kind": "all_aquarium_shiny",
		"target": 1,
		"condition": "Llena el acuario solo con peces especiales",
		"icon": preload("res://assets/logros/peZes.png"),
		"hidden": true
	},
	"all_species_in_aquarium": {
		"title": "Fiesta en la pecera",
		"desc": "Que caiga la perca (Drop the bass).",
		"kind": "all_species_in_aquarium",
		"target": 1,
		"condition": "Pon un pez de cada tipo en el acuario",
		"icon": preload("res://assets/logros/fiesta.png"),
		"hidden": true
	},
	"alien_jump": {
		"title": "¡¡¡SALTA!!!",
		"desc": "Auspicio salta de alegría al ver tantos peces. Nunca había sido tan feliz. «¡Fblthp lpwrdwp!», exclamó.",
		"kind": "alien_clicked",
		"target": 1,
		"condition": "Pulsa el alien cuando aparezca, y saltará",
		"icon": preload("res://assets/logros/salta.png"),
		"hidden": true
	},
	"better_luck_next_time": {
		"title": "Better luck next time!",
		"desc": "Ahora toca. No… ¡ahora! Venga, ahora seguro que sí…",
		"kind": "random_tick",
		"target": 1,
		"condition": "Obtenido con una probabilidad del 0,01% en cada tick del juego",
		"icon": preload("res://assets/logros/luck.png"),
		"hidden": true
	},
	"encyclopedia_complete": {
		"title": "Pezología 101",
		"desc": "Abrid todos el libro por la página 394.",
		"kind": "encyclopedia_complete",
		"target": 1,
		"condition": "Completa la enciclopedia de peces",
		"icon": preload("res://assets/logros/pezologia_101.png"),
		"hidden": true
	},
	"profile_clicked_100": {
		"title": "YO.",
		"desc": "Eres tú… ¿Pero… quién eres realmente?",
		"kind": "profile_clicks",
		"target": 100,
		"condition": "Pulsa 100 veces en la foto de perfil",
		"icon": preload("res://assets/logros/yo.png"),
		"hidden": true
	},
	"volume_slider_spam": {
		"title": "¿Me oyes? ¿Me escuchas?...¿Me sientes?",
		"desc": "Sube, baja, sube, baja… ¿buscas el volumen perfecto o una señal divina?",
		"kind": "volume_slider_spam",
		"target": 1,
		"condition": "Cambia el volumen general rápidamente",
		"icon": preload("res://assets/logros/escuchas_oyes_sientes.png"),
		"hidden": true
	},
	"same_species_full_aquarium": {
		"title": "Piscifactoría",
		"desc": "Más te vale que cumpla con las regulaciones de densidad, oxígeno, temperatura, calidad del agua…",
		"kind": "same_species_full_aquarium",
		"target": 1,
		"condition": "Llena el acuario de peces de la misma especie",
		"icon": preload("res://assets/logros/piscifactoria.png"),
		"hidden": true
	},
	"annoy_fish_repeatedly": {
		"title": "Toca-huevas",
		"desc": "No toques, ¿por qué tocas?",
		"kind": "annoy_fish",
		"target": 50,
		"condition": "Molesta a los peces repetidamente en el acuario",
		"icon": preload("res://assets/logros/huevas.png"),
		"hidden": true
	},
		"dirty_aquarium_10_min": {
		"title": "Viviendo entre las algas",
		"desc": "Tus peces han decidido abrazar su lado más… natural.",
		"kind": "dirty_aquarium_time",
		"target": 600.0,
		"condition": "Deja la pecera sucia durante 10 minutos",
		"icon": preload("res://assets/logros/viviendo_entre_las_algas.png"),
		"hidden": true
	},
}
