extends Control

onready var error_screen = $error_panel

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

#func _process(delta):
#	OS.window_fullscreen = true
##	if Input.is_action_just_pressed("fullscreen"):
##		OS.window_fullscreen = !OS.window_fullscreen
#

func _on_Button_pressed():
	return



func _on_quit_button_pressed():
	get_tree().quit()
