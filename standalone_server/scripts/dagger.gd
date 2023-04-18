extends Spatial

export var fire_rate = 0.2
export var max_bullet = 10
export var damage = 10
export var appear_frame = 48
export var fire_frame =  12
export var reload_frame = 84

var recoil = 0.1
var last_shoot = -1
var current_bullet = 10


func _ready():
	$Timer.wait_time = fire_rate
	$Timer.autostart = false

func reload():
	current_bullet = max_bullet
	


func can_shoot():
	if(current_bullet > 0 and ($Timer.is_stopped())):
		return true
	return true

func shoot():
	return
#	$Timer.start()
