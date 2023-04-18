extends Spatial

export var fire_rate = 0.1
export var max_bullet = 30
export var damage = 20
export var appear_frame = 48
export var fire_frame =  9
export var reload_frame = 120
var current_bullet = 30
var recoil = 0.5


func _ready():
	$Timer.wait_time = fire_rate
	$Timer.autostart = false

func reload():
	current_bullet = max_bullet
	

func can_shoot():
	if(current_bullet > 0 and ($Timer.is_stopped())):
		return true
	return false

func shoot():
#	$Timer.start()
	current_bullet -= 1
		
