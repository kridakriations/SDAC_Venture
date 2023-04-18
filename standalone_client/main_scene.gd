extends Control

func _ready():
	get_node("ready_panel/ip_address_label").text = Gamedata.temp_ip
	get_node("ready_panel/name_label").text = Gamedata.temp_name
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
#	if Input.is_action_just_pressed("fullscreen"):
#		OS.window_fullscreen = !OS.window_fullscreen

func _process(delta):
	if Input.is_action_just_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen

func hover_button():
	$hover_sound.stop()
	$hover_sound.play()
	pass

func press_button(index = 1):
	$press_sound.play()
