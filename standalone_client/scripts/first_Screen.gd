extends Control


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta):
	if Input.is_action_just_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	

func _on_Button_pressed():
	return

