extends Control

onready var player_panel = $players
onready var row_demo = $players/list/demo
onready var list = $players/list

func _ready():
	if(Server.is_connected("lobby_changed",self,"recreate_player_panel") == false):
		Server.connect("lobby_changed",self,"recreate_player_panel")
	if(Server.is_connected("all_player_ready",self,"make_start_button_active") == false):
		Server.connect("all_player_ready",self,"make_start_button_active")
	if(Server.is_connected("all_player_not_active",self,"make_start_button_in_active") == false):
		Server.connect("all_player_not_active",self,"make_start_button_in_active")
	
	recreate_player_panel()

func _on_host_pressed():
	var server_ip = get_node("ip_address_box").text
	var port = get_node("port_box").text
	port = int(port)
	Server.ConnectToServer(server_ip,port)
	Server.player_name = get_parent().get_node("id_card/name").text
	Server.player_detail = {
		"outfit": get_parent().get_node("id_card").outfit_code,
		"primary_gun":get_parent().get_node("id_card").curr_primary_gun,
		"secondary_gun":get_parent().get_node("id_card").curr_secondary_gun
		}


func _on_start_pressed():
	player_panel.visible = true

func _on_close_panel_pressed():
	player_panel.visible = false
	pass # Replace with function body.

func make_start_button_active():
	player_panel.get_node("start_game_button").disabled = false

func make_start_button_in_active():
	player_panel.get_node("start_game_button").disabled = true

func recreate_player_panel():
	print("recreate lobby")
	for i in range(1,player_panel.get_node("list").get_children().size()):
		player_panel.get_node("list").get_child(i).queue_free()
	var ready_players = 0
	for id in Server.joined_player_data:
		var new_row = row_demo.duplicate()
		list.add_child(new_row)
		new_row.get_node("name").text = Server.joined_player_data[id]["name"]
		if(Server.joined_player_data[id]["ready"] == true):
			new_row.get_node("is_ready").text = "ready"#str(Server.joined_player_data[id]["ready"])
		else:
			new_row.get_node("is_ready").text = "not ready"
#		new_row.get_node("is_ready").text = str(Server.joined_player_data[id]["ready"])
		new_row.get_node("type").text = str(Server.joined_player_data[id]["is_host"])
		new_row.visible = true
		if(Server.joined_player_data[id]["ready"] == true):
			ready_players += 1
	if(ready_players != Server.joined_player_data.size()-1):
		make_start_button_in_active()
	else:
		make_start_button_active()
		pass


func _on_start_game_button_pressed():
	var player_data = {
		"outfit": get_parent().get_node("id_card").outfit_code,
		"primary_gun":get_parent().get_node("id_card").curr_primary_gun,
		"secondary_gun":get_parent().get_node("id_card").curr_secondary_gun
		}
	var map_code = get_parent().get_node("id_card").curr_map_code
	var game_time = get_parent().get_node("id_card").curr_game_time
	Server.start_game(player_data,map_code,game_time)
#	Server.rpc_id(1,"start_game",player_data,map_code,game_time)
	pass


func _on_main_menu_button_pressed():
	Server.close_connection()
