extends Node

export var gun_type = ""

var current_bullet = 0
var max_bullet = 0
var fire_frame = 0
var reload_frame = 0
var damage = 0
var recoil = 0
var appear_frame
var scope_frame = 0
var head_damage = 0


func _ready():
	max_bullet = GameData.gun_stats[gun_type]["max_bullet"]
	fire_frame = GameData.gun_stats[gun_type]["fire_frame"]
	reload_frame = GameData.gun_stats[gun_type]["reload_frame"]
	damage = GameData.gun_stats[gun_type]["damage"]
	head_damage = GameData.gun_stats[gun_type]["head_damage"]
	recoil = GameData.gun_stats[gun_type]["recoil"]
	scope_frame = GameData.gun_stats[gun_type]["scope_frame"]
	appear_frame = GameData.appear_frame
	current_bullet = max_bullet
	
	
func reload():
	current_bullet = max_bullet
	


func can_shoot():
	if(current_bullet > 0):
		return true
	return false

func shoot():
	current_bullet -= 1
