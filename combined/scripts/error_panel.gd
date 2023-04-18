extends Panel

func _ready():
	pass # Replace with function body.

func show_error(error):
	$Label.text = error
	visible = true

func _on_error_panel_visibility_changed():
	if(visible == true):
#		$Timer.start()
		pass

func _on_okay_button_pressed():
	visible = false
