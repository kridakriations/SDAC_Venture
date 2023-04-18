extends Panel

var server_ip
var server_password 
var server_port


func _on_cancel_button_pressed():
	visible = false




func _on_proceed_button_pressed():
	var entered_password = $password.text
	print("entered password ",entered_password)
	if(entered_password == ""):
		$error.visible = true
		$error.text = "!!Please enter the Password!!"
	elif(entered_password == server_password):
		Server.player_name = get_node("../../../join_button/Control/name_box").text
		Gamedata.temp_ip = server_ip
		Gamedata.temp_name = Server.player_name
		Server.ConnectToServer(server_ip,server_port)
		get_node("../../../../waiting_panel").visible = true
		
	else:
		$error.visible = true
		$error.text = "!!Wrong Password!!"
	pass # Replace with function body.


func _on_password_entry_visibility_changed():
	if(visible == true):
		$error.visible = false
