extends Node
# a script were all the game data is saved

var player_max_health = 100
var player_respawn_time = 5

onready var primary_gun_models = [
	"res://scenes/server_guns/assault_rifle.tscn",
	"res://scenes/server_guns/assault_rifle2.tscn",
	"res://scenes/server_guns/shotgun_new.tscn",
	"res://scenes/server_guns/sniper.tscn",
	"res://scenes/server_guns/smg.tscn"
	
]
onready var primary_gun_types = [
	"assault_rifle","assault_rifle2","shotgun","sniper","smg"
]
onready var secondary_gun_types = [
	"glock"
]


onready var secondary_gun_models = [
	"res://scenes/server_guns/glock.tscn",
	"res://scenes/server_guns/dagger.tscn"
]

onready var primary_gun_collision_models = [
	"res://scenes/collision_guns/assault_rifle.tscn",
	"res://scenes/collision_guns/assault_rifle2.tscn",
	"res://scenes/collision_guns/shotgun.tscn",
	"res://scenes/collision_guns/sniper.tscn",
	"res://scenes/collision_guns/smg.tscn"
]

onready var secondary_gun_collision_models = [
	"res://scenes/collision_guns/glock.tscn",
	"res://scenes/collision_guns/dagger.tscn",
]

onready var gun_stats = {
	"assault_rifle":{
		"reload_frame":115,
		"fire_frame":9,
		"max_bullet":24,
		"recoil":0.5,
		"damage":15,
		"head_damage":60,
		"scope_frame":7,
		"max_spread":20,
	},
	"assault_rifle2":{
		"reload_frame":98,
		"fire_frame":12,
		"max_bullet":24,
		"recoil":0.4,
		"damage":13,
		"head_damage":40,
		"scope_frame":7,
		"max_spread":10,
	},
	"shotgun":{
		"reload_frame":180,
		"fire_frame":14,
		"max_bullet":2,
		"recoil":0.4,
		"damage":70,
		"head_damage":100,
		"scope_frame":7,
		"max_spread":30,
	},
	"sniper":{
		"reload_frame":126,
		"fire_frame":37,
		"max_bullet":5,
		"recoil":0.4,
		"damage":70,
		"head_damage":100,
		"scope_frame":7,
		"max_spread":0,
	},
	"smg":{
		"reload_frame":60,
		"fire_frame":6,
		"max_bullet":25,
		"recoil":0.6,
		"damage":20,
		"head_damage":40,
		"max_spread":20,
		"scope_frame":7,
	},
	"glock":{
		"reload_frame":97,
		"fire_frame":15,
		"max_bullet":10,
		"recoil":0.1,
		"damage":20,
		"head_damage":30,
		"scope_frame":7,
		"max_spread":5,
	}
}

onready var bomb_model = preload("res://scenes/server_bomb.tscn")

onready var appear_frame = 50
onready var wait_frame_without_bullet = 9
var distance = 5
var bomb_kill_streak = 3


