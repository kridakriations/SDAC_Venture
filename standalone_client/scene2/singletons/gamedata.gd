extends Node

var temp_ip = "null"
var temp_port = "null"
var temp_name = "null"
var settings_file_address = "user://settings.json"
var outfit_file_address = "user://outfit.json"
var total_outfits = 3
var total_secondary_guns = 2
var total_primary_guns = 5

var color = [
			preload("res://assets/outfilt/material/skin_new.material"),
			preload("res://assets/outfilt/material/red.material"),
			preload("res://assets/outfilt/material/green.material"),
			preload("res://assets/outfilt/material/blue_new.material"),
			preload("res://assets/outfilt/material/gray.material"),
			preload("res://assets/outfilt/material/black_new.material"),
			preload("res://assets/outfilt/material/white.material"),
			preload("res://assets/outfilt/material/brown.material"),
			preload("res://assets/outfilt/material/cyan.material"),
			preload("res://assets/outfilt/material/maroon.material"),
			preload("res://assets/outfilt/material/sky_blue.material"),
			preload("res://assets/outfilt/material/dark_green.material"),
			preload("res://assets/outfilt/material/orange.material"),
			preload("res://assets/outfilt/material/pink.material"),
			preload("res://assets/outfilt/material/dark_pink.material"),
			preload("res://assets/outfilt/material/tan.material"),
			preload("res://assets/outfilt/material/voilet.material"),
			preload("res://assets/outfilt/material/yellow.material")
		]
var color_shirt = ["#d03a0e","d81919","25e61c","f5ee09","8c8282","080000","ffffff"]

onready var damage_indicators = {
	10:preload("res://scenes/10_damage.tscn"),
	13:preload("res://scenes/13_damage.tscn"),
	15:preload("res://scenes/15_damage.tscn"),
	20:preload("res://scenes/20_damage.tscn"),
	30:preload("res://scenes/30_damage.tscn"),
	40:preload("res://scenes/40_damage.tscn"),
	60:preload("res://scenes/60_damage.tscn"),
	70:preload("res://scenes/70_damage.tscn"),
	100:preload("res://scenes/100_damage.tscn"),
}

onready var secondary_guns_name = ["Glock","Knife"]
onready var secondary_guns_demostration = [
	preload("res://assets/demostration_guns/glock.tscn"),
	preload("res://assets/demostration_guns/glock.tscn")
]
onready var primary_guns_name = ["Assault rifle","Assault rifle2","Shotgun","Sniper rifle","SMG"]
onready var primary_guns_demostration = [
	preload("res://assets/demostration_guns/assault_rifle.tscn"),
	preload("res://assets/demostration_guns/m16.tscn"),
	preload("res://assets/demostration_guns/shotgun_new.tscn"),
	preload("res://assets/demostration_guns/dragunov.tscn"),
	preload("res://assets/demostration_guns/famas.tscn")
]

onready var primary_guns_enemy = [
	"res://assets/enemy_guns/assault_rifle.tscn",
	"res://assets/enemy_guns/assault_rifle2.tscn",
	"res://assets/enemy_guns/shotgun.tscn",
	"res://assets/enemy_guns/sniper.tscn",
	"res://assets/enemy_guns/smg.tscn"
]

onready var secondary_guns_enemy = [
	"res://assets/enemy_guns/glock.tscn",
	"res://assets/enemy_guns/dagger.tscn"
]

onready var primary_guns = [
	"res://assets/guns/assault_rifle.tscn",
	"res://assets/guns/assault_rifle2.tscn",
	"res://assets/guns/shotgun_new.tscn",
	"res://assets/guns/sniper.tscn",
	"res://assets/guns/smg.tscn"
]

onready var secondary_guns = [
	"res://assets/guns/glock.tscn",
	"res://assets/guns/dagger.tscn"
]

onready var bomb_model = preload("res://scene2/bomb.tscn")

onready var decal = preload("res://scenes/decal.tscn")

onready var gun_stats = {
	"assault_rifle":{
		"reload_frame":115,
		"fire_frame":9,
		"max_bullet":24,
		"recoil":0.5,
		"bullet_path":"res://assets/bullet/bullet.tscn",
		"scope_frame":7,
		"scoped_pos":Vector3(0.195,0.483,-0.567),
		"scoped_rotation_degrees":Vector3(-0.43,0,0),
		"normal_pos":Vector3(-0.108,0.383,-0.437),
		"normal_rotation_degrees":Vector3(0,0,0),
		"max_spread":20,
		"scope_value":80,
		"bullet_sound":"res://assets/bullet/assault_riflebullet.tscn"
	},
	"assault rifle2":{
		"reload_frame":98,
		"fire_frame":12,
		"max_bullet":24,
		"recoil":0.4,
		"bullet_path":"res://assets/bullet/bullet.tscn",
		"scope_frame":7,
		"scoped_pos":Vector3(0.179,0.376,-0.567),
		"scoped_rotation_degrees":Vector3(0,0,0),
		"normal_pos":Vector3(-0.066,0.361,-0.443),
		"normal_rotation_degrees":Vector3(0,0,0),
		"max_spread":10,
		"scope_value":80,
		"bullet_sound":"res://assets/bullet/assault_riflebullet.tscn"
	},
	"shotgun":{
		"reload_frame":180,
		"fire_frame":14,
		"max_bullet":2,
		"recoil":0.4,
		"bullet_path":"res://assets/bullet/bullet.tscn",
		"scope_frame":7,
		"scoped_pos":Vector3(0.442,0.197,0.029),
		"scoped_rotation_degrees":Vector3(0.791,0,0),
		"normal_pos":Vector3(-0.0,0.091,0),
		"normal_rotation_degrees":Vector3(0,0,0),
		"max_spread":30,
		"scope_value":80,
		"bullet_sound":"res://assets/bullet/shotgun.tscn"
	},
	"sniper":{
		"reload_frame":126,
		"fire_frame":37,
		"max_bullet":5,
		"recoil":0.4,
		"bullet_path":"res://assets/bullet/bullet.tscn",
		"scope_frame":7,
		"scoped_pos":Vector3(0.257,0.27,-0.573),
		"scoped_rotation_degrees":Vector3(0,0,0),
		"normal_pos":Vector3(-0.384,-0.241,0.294),
		"normal_rotation_degrees":Vector3(0,0,0),
		"max_spread":0,
		"scope_value":60,
		"bullet_sound":"res://assets/bullet/sniper.tscn"
	},
	"smg":{
		"reload_frame":60,
		"fire_frame":6,
		"max_bullet":25,
		"recoil":0.4,
		"bullet_path":"res://assets/bullet/bullet.tscn",
		"scope_frame":7,
		"scoped_pos":Vector3(0.366,0.199,-0.275),
		"scoped_rotation_degrees":Vector3(-2.799,-0.135,0),
		"normal_pos":Vector3(0,0.091,0),
		"normal_rotation_degrees":Vector3(0,0,0),
		"max_spread":20,
		"scope_value":80,
		"bullet_sound":"res://assets/bullet/assault_riflebullet.tscn"
	},
	"glock":{
		"reload_frame":97,
		"fire_frame":15,
		"max_bullet":10,
		"recoil":0.1,
		"bullet_path":"res://assets/bullet/bullet.tscn",
		"scope_frame":7,
		"scoped_pos":Vector3(0.47,0.15,0.029),
		"scoped_rotation_degrees":Vector3(0,0,0),
		"normal_pos":Vector3(0,0.091,0),
		"normal_rotation_degrees":Vector3(7,0,0),
		"max_spread":5,
		"scope_value":80,
		"bullet_sound":"res://assets/bullet/pistol.tscn"
	}
}

var settings = {
	"senstivity_value":1.2,
	"music_value":50,
	"sfx_value":2,
	"sfx_mute":false,
	"shading":true,
	"shadows":true,
	"render_distance":150
}



onready var gun_appear_frame = 50
onready var gun_disappear_frame = 96
onready var speed = 5

onready var senstivity_value = 1.2

onready var empty_clip_sound = preload("res://assets/bullet/empty_clip_sound.tscn")
onready var wait_frame_without_bullet = 9

func save_file(new_data,file_address = settings_file_address):
	var new_file = File.new()
	new_file.open(file_address,File.WRITE)
	var new_txt = JSON.print(new_data,"\t")
	new_file.store_string(new_txt)
	new_file.close()
	
	
func load_file(file_address = settings_file_address):
	var new_file = File.new()
	if(new_file.file_exists(file_address) == false):
		return {}
	else:
		new_file.open(file_address, File.READ)
		var file_text = new_file.get_as_text()
		var file_json = JSON.parse(file_text).result 
		return file_json
		
	
var default_outfit_code = {
	"shirt":6,
	"jacket":5,
	"shoes":5,
	"pants":3
}

