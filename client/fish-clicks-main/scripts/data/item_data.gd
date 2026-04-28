extends RefCounted
class_name ItemData

const ITEMS := {
	"doblon": {
		"tab": "Peces",
		"title": "Doblon",
		"icon": "res://assets/peces/doblon.png",
		"unlock_price": 10,
		"kind": "passive",
		"base_price": 40.0,
		"price_growth": 1.28,
		"base_value": 1.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_1"]
	},
	"sobrasada": {
		"tab": "Peces",
		"title": "Sobrasada",
		"icon": "res://assets/peces/sobrasada.png",
		"unlock_price": 250,
		"kind": "passive",
		"base_price": 220.0,
		"price_growth": 1.30,
		"base_value": 4.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_1"]
	},
	"espuma": {
		"tab": "Peces",
		"title": "Espuma",
		"icon": "res://assets/peces/espuma.png",
		"unlock_price": 1200,
		"kind": "passive",
		"base_price": 900.0,
		"price_growth": 1.32,
		"base_value": 12.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_1"]
	},
	"rufinus": {
		"tab": "Peces",
		"title": "Rufinus",
		"icon": "res://assets/peces/rufinus.png",
		"unlock_price": 5000,
		"kind": "passive",
		"base_price": 3500.0,
		"price_growth": 1.35,
		"base_value": 35.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_1"]
	},
	
	"chupete_jr": {
		"tab": "Únicos",
		"title": "Chupete jr",
		"icon": "res://assets/peces/chupete_jr.png",
		"unlock_price": -1,
		"kind": "passive",
		"base_price": 4500.0,
		"price_growth": 1.35,
		"base_value": 35.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_1"]
	},
	"auspezio": {
		"tab": "Únicos",
		"title": "Auspezio",
		"icon": "res://assets/peces/auspezio.png",
		"unlock_price": -1,
		"kind": "passive",
		"base_price": 3500.0,
		"price_growth": 1.35,
		"base_value": 35.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_1", "habitat_2"]
	},
	
	"barbacoa": {
		"tab": "Peces",
		"title": "Barbacoa",
		"icon": "res://assets/peces/barbacoa.png",
		"unlock_price": 10,
		"kind": "passive",
		"base_price": 3500.0,
		"price_growth": 1.35,
		"base_value": 35.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_2"]
	},
	
	"angeles": {
		"tab": "Peces",
		"title": "Angeles",
		"icon": "res://assets/peces/angeles.png",
		"unlock_price": 10,
		"kind": "passive",
		"base_price": 3500.0,
		"price_growth": 1.35,
		"base_value": 35.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_2"]
	},

	"jigou": {
		"tab": "Peces",
		"title": "Jigou",
		"icon": "res://assets/peces/jigou.png",
		"unlock_price": 10,
		"kind": "passive",
		"base_price": 3500.0,
		"price_growth": 1.35,
		"base_value": 35.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_2"]
	},
	
	"leonardo": {
		"tab": "Peces",
		"title": "Leonardo",
		"icon": "res://assets/peces/leonardo.png",
		"unlock_price": 10,
		"kind": "passive",
		"base_price": 3500.0,
		"price_growth": 1.35,
		"base_value": 35.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_2"]
	},

	"cofre": {
		"tab": "Estructuras",
		"title": "Cofre",
		"icon": "res://assets/estructuras/cofre_cerrado.png",
		"unlock_price": 0,
		"kind": "click",
		"base_price": 20.0,
		"price_growth": 1.10,
		"base_value": 0.75,
		"value_label": "clicks",
		"habitat_ids": ["habitat_1", "habitat_2"]
	},
	"vallisneria": {
		"tab": "Estructuras",
		"title": "Vallisneria",
		"icon": "res://assets/estructuras/vallisneria/vallisneria_mini.png",
		"unlock_price": 500,
		"kind": "passive",
		"base_price": 180.0,
		"price_growth": 1.14,
		"base_value": 6.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_1"]
	},
	"tronco": {
		"tab": "Estructuras",
		"title": "Tronco",
		"icon": "res://assets/estructuras/tronco/tronco_mini.png",
		"unlock_price": 800,
		"kind": "passive",
		"base_price": 250.0,
		"price_growth": 1.15,
		"base_value": 8.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_1"]
	},
	"anubia": {
		"tab": "Estructuras",
		"title": "Anubia",
		"icon": "res://assets/estructuras/anubia/anubia_mini.png",
		"unlock_price": 1200,
		"kind": "passive",
		"base_price": 400.0,
		"price_growth": 1.16,
		"base_value": 12.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_1"]
	},
	"coral": {
		"tab": "Estructuras",
		"title": "Coral Antartico",
		"icon": "res://assets/estructuras/coral/coral_small.png",
		"unlock_price": 1200,
		"kind": "passive",
		"base_price": 400.0,
		"price_growth": 1.16,
		"base_value": 12.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_2"]
	},

	"piedra": {
		"tab": "Estructuras",
		"title": "Piedra",
		"icon": "res://assets/estructuras/piedra/piedra_small.png",
		"unlock_price": 1200,
		"kind": "passive",
		"base_price": 400.0,
		"price_growth": 1.16,
		"base_value": 12.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_2"]
	},
	
	"iceberg": {
		"tab": "Estructuras",
		"title": "Iceberg",
		"icon": "res://assets/estructuras/iceberg/iceberg_small.png",
		"unlock_price": 1200,
		"kind": "passive",
		"base_price": 400.0,
		"price_growth": 1.16,
		"base_value": 12.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_2"]
	},
	
	"barco": {
		"tab": "Estructuras",
		"title": "Barco Hundido",
		"icon": "res://assets/estructuras/barco/barco_small.png",
		"unlock_price": 1200,
		"kind": "passive",
		"base_price": 400.0,
		"price_growth": 1.16,
		"base_value": 12.0,
		"value_label": "DPS",
		"habitat_ids": ["habitat_2"]
	}
}
