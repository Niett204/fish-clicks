extends RefCounted
class_name ItemData

const ITEMS := {
	# ======================
	# PECES - MUNDO 1
	# Los peces son la fuente principal de DPS. Pocos, caros y valiosos.
	# ======================
	"doblon": {
		"tab": "Peces",
		"title": "Doblon",
		"icon": "res://assets/peces/doblon.png",
		"unlock_price": 25,
		"kind": "fish",
		"base_price": 120.0,
		"price_growth": 1.35,
		"base_value": 1.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_1"]
	},
	"sobrasada": {
		"tab": "Peces",
		"title": "Sobrasada",
		"icon": "res://assets/peces/sobrasada.png",
		"unlock_price": 750,
		"kind": "fish",
		"base_price": 1200.0,
		"price_growth": 1.45,
		"base_value": 8.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_1"]
	},
	"espuma": {
		"tab": "Peces",
		"title": "Espuma",
		"icon": "res://assets/peces/espuma.png",
		"unlock_price": 3500,
		"kind": "fish",
		"base_price": 5000.0,
		"price_growth": 1.55,
		"base_value": 35.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_1"]
	},
	"rufinus": {
		"tab": "Peces",
		"title": "Rufinus",
		"icon": "res://assets/peces/rufinus.png",
		"unlock_price": 30000,
		"kind": "fish",
		"base_price": 35000.0,
		"price_growth": 1.70,
		"base_value": 150.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_1"]
	},

	# ======================
	# ÚNICOS
	# ======================
	"chupete_jr": {
		"tab": "Únicos",
		"title": "Chupete jr",
		"icon": "res://assets/peces/chupete_jr.png",
		"unlock_price": -1,
		"kind": "unique_buff",
		"buff_type": "cleaning_speed",
		"max_level": 10,
		"base_price": 50000.0,
		"price_growth": 3.0,
		"base_value": 0.15,
		"habitat_ids": ["habitat_1", "habitat_2"]
	},

	"auspezio": {
		"tab": "Únicos",
		"title": "Auspezio",
		"icon": "res://assets/peces/auspezio.png",
		"unlock_price": -1,
		"kind": "unique_buff",
		"buff_type": "alien_time_reduction",
		"max_level": 30,
		"base_price": 500000.0,
		"price_growth": 1.6,
		"base_value": 2.0,
		"habitat_ids": ["habitat_1", "habitat_2"]
	},

	# ======================
	# PECES - MUNDO 2
	# ======================
	"barbacoa": {
		"tab": "Peces",
		"title": "Barbacoa",
		"icon": "res://assets/peces/barbacoa.png",
		"unlock_price": 90000,
		"kind": "fish",
		"base_price": 250000.0,
		"price_growth": 1.45,
		"base_value": 500.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_2"]
	},
	"angeles": {
		"tab": "Peces",
		"title": "Angeles",
		"icon": "res://assets/peces/angeles.png",
		"unlock_price": 250000,
		"kind": "fish",
		"base_price": 500000.0,
		"price_growth": 1.55,
		"base_value": 850.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_2"]
	},
	"jigou": {
		"tab": "Peces",
		"title": "Jigou",
		"icon": "res://assets/peces/jigou.png",
		"unlock_price": 1000000,
		"kind": "fish",
		"base_price": 1500000.0,
		"price_growth": 1.70,
		"base_value": 2500.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_2"]
	},
	"leonardo": {
		"tab": "Peces",
		"title": "Leonardo",
		"icon": "res://assets/peces/leonardo.png",
		"unlock_price": 4500000,
		"kind": "fish",
		"base_price": 9000000.0,
		"price_growth": 1.90,
		"base_value": 12000.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_2"]
	},

	# ======================
	# ESTRUCTURAS
	# No dan DPS directo. Dan buffs y pueden subir sin nivel máximo.
	# buff_type:
	# - click_flat: sube los doblones base por clic.
	# - fish_dps_multiplier: más doblones dados por peces.
	# - global_coin_multiplier: más doblones en general.
	# - shiny_chance_bonus: más probabilidad de shiny.
	# ======================
	"cofre": {
		"tab": "Estructuras",
		"title": "Cofre",
		"icon": "res://assets/estructuras/cofre_cerrado.png",
		"unlock_price": 0,
		"kind": "structure_buff",
		"buff_type": "click_flat",
		"base_price": 25.0,
		"price_growth": 1.16,
		"base_value": 0.50,
		"value_label": "clicks",
		"habitat_ids": ["habitat_1", "habitat_2"]
	},
	"vallisneria": {
		"tab": "Estructuras",
		"title": "Vallisneria",
		"icon": "res://assets/estructuras/vallisneria/vallisneria_mini.png",
		"unlock_price": 300,
		"kind": "structure_buff",
		"buff_type": "fish_dps_multiplier",
		"base_price": 220.0,
		"price_growth": 1.12,
		"base_value": 0.012,
		"value_label": "% peces",
		"habitat_ids": ["habitat_1"]
	},
	"tronco": {
		"tab": "Estructuras",
		"title": "Tronco",
		"icon": "res://assets/estructuras/tronco/tronco_mini.png",
		"unlock_price": 2000,
		"kind": "structure_buff",
		"buff_type": "global_coin_multiplier",
		"base_price": 900.0,
		"price_growth": 1.16,
		"base_value": 0.006,
		"value_label": "% general",
		"habitat_ids": ["habitat_1"]
	},
	"anubia": {
		"tab": "Estructuras",
		"title": "Anubia",
		"icon": "res://assets/estructuras/anubia/anubia_mini.png",
		"unlock_price": 8000,
		"kind": "structure_buff",
		"buff_type": "fish_dps_multiplier",
		"base_price": 3500.0,
		"price_growth": 1.21,
		"base_value": 0.02,
		"value_label": "% peces",
		"habitat_ids": ["habitat_1"]
	},
	"coral": {
		"tab": "Estructuras",
		"title": "Coral Antartico",
		"icon": "res://assets/estructuras/coral/coral_small.png",
		"unlock_price": 120000,
		"kind": "structure_buff",
		"buff_type": "fish_dps_multiplier",
		"base_price": 150000.0,
		"price_growth": 1.11,
		"base_value": 0.025,
		"value_label": "% peces",
		"habitat_ids": ["habitat_2"]
	},
	"piedra": {
		"tab": "Estructuras",
		"title": "Piedra",
		"icon": "res://assets/estructuras/piedra/piedra_small.png",
		"unlock_price": 300000,
		"kind": "structure_buff",
		"buff_type": "global_coin_multiplier",
		"base_price": 400000.0,
		"price_growth": 1.14,
		"base_value": 0.01,
		"value_label": "% general",
		"habitat_ids": ["habitat_2"]
	},
	"iceberg": {
		"tab": "Estructuras",
		"title": "Iceberg",
		"icon": "res://assets/estructuras/iceberg/iceberg_small.png",
		"unlock_price": 1000000,
		"kind": "structure_buff",
		"buff_type": "fish_dps_multiplier",
		"base_price": 1200000.0,
		"price_growth": 1.18,
		"base_value": 0.04,
		"value_label": "% peces",
		"habitat_ids": ["habitat_2"]
	},
	"barco": {
		"tab": "Estructuras",
		"title": "Barco Hundido",
		"icon": "res://assets/estructuras/barco/barco_small.png",
		"unlock_price": 3500000,
		"kind": "structure_buff",
		"buff_type": "shiny_chance_bonus",
		"base_price": 4000000.0,
		"price_growth": 1.24,
		"base_value": 0.0005,
		"value_label": "% shiny",
		"habitat_ids": ["habitat_2"]
	}
}
