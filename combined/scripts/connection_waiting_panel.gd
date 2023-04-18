extends Panel


func _ready():
	$Timer.connect("timeout",self,"timer_out")

func timer_out():
	visible = false
#	get_parent().get_node("main_menu_options/join_button/Control/password_entry").visible = true
#	get_parent().get_node("main_menu_options/join_button/Control/password_entry/error").text = "Server not responding"
#	get_parent().get_node("main_menu_options/join_button/Control/password_entry/error").visible = true
	get_parent().get_node("error_panel").show_error("Server not responding please check on the server")
	Server.stop_creating_client()
	pass

func _on_waiting_panel_visibility_changed():
	if(visible == true):
		$Timer.start()
		get_parent().get_node("main_menu_options/join_button/Control/password_entry").visible = false

	pass # Replace with function body.
