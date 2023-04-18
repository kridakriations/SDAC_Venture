extends Control

var options = [
	"join_button","settings_button","controls_button","host_button","artwork_button","credits_button"
]

func hide_all_options():
	for i in options:
		print(i)
		get_node(i).get_child(0).visible = false




func _on_join_button_pressed():
	hide_all_options()
	get_node(options[0]).get_child(0).visible = true


func _on_settings_button_pressed():
	hide_all_options()
	get_node(options[1]).get_child(0).visible = true
#	set_the_settings_value()


func _on_controls_button_pressed():
	hide_all_options()
	get_node(options[2]).get_child(0).visible = true


func _on_tutorial_button_pressed():
	hide_all_options()
	get_node(options[3]).get_child(0).visible = true


func _on_artwork_button_pressed():
	hide_all_options()
	get_node(options[4]).get_child(0).visible = true


func _on_credits_button_pressed():
	hide_all_options()
	get_node(options[5]).get_child(0).visible = true


func _on_Button_pressed():
	var ip = get_node("join_button/Control/ip_box").text
	var port = get_node("join_button/Control/port_box").value
	var new_ip = ip
	while(ip != ip.trim_prefix(" ")):
		ip = ip.trim_prefix(" ")
	
	while(ip != ip.trim_suffix(" ")):
		ip = ip.trim_suffix(" ")
	
	Server.player_name = get_node("join_button/Control/name_box").text
	Gamedata.temp_ip = ip
	Gamedata.temp_name = Server.player_name
	Server.ConnectToServer(ip,port)


func button_pressed():
	$press_sound.play()


func button_mouse_entered():
	$hover_sound.stop()
	$hover_sound.play()


func _on_name_box_text_changed(new_text):
	$join_button/Control/name.text = new_text



