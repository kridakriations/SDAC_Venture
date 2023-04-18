extends Control

func _physics_process(delta):
	$frame_rate.text = str(Engine.get_frames_per_second())



func _on_Button_pressed():
	var serv_name = $server_details/room_name.text
	var new_serv_name = serv_name
	var password = $server_details/password.text
	while(serv_name != serv_name.trim_prefix(" ")):
		serv_name = serv_name.trim_prefix(" ")
	
	while(serv_name != serv_name.trim_suffix(" ")):
		serv_name = serv_name.trim_suffix(" ")
	Server.StartServer(1989,8,serv_name,password)
