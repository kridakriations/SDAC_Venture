extends Button

func _ready():
	Server.stop_broadcasting()


func _on_create_button_pressed():
	var room_name = $Control/room_name.text
	var room_password = $Control/room_password.text
	var player_name = $Control/name.text
	var max_players = $Control/max_players.value
	if((room_name == "")):
		get_parent().get_parent().error_screen.show_error("Enter the room name")
		return
	if(player_name == ""):
		get_parent().get_parent().error_screen.show_error("Enter the player name")
		return
	#add the check for null room name
	Gamedata.temp_name = player_name
	Server.player_name = player_name
	Server.start_broadcasting(room_name,room_password,max_players)
	
	pass


func _on_Control_visibility_changed():
	
	pass 


func _on_name_text_changed(new_text):
	$Control/name_label.text = new_text
