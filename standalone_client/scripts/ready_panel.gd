extends Control

onready var player_panel = $players
onready var row_demo = $players/list/demo
onready var list = $players/list

func _ready():
	if(Server.is_connected("lobby_changed",self,"recreate_player_panel") == false):
		Server.connect("lobby_changed",self,"recreate_player_panel")
	recreate_player_panel()
	
	
func _on_ready_pressed():
	var player_data = {
		"outfit": get_parent().get_node("id_card").outfit_code,
		"primary_gun":get_parent().get_node("id_card").curr_primary_gun,
		"secondary_gun":get_parent().get_node("id_card").curr_secondary_gun
		}
		
	if($ready.text == "Ready"):
		get_parent().get_node("id_card").make_dormant()
		$ready.text = "Not Ready"
		Server.player_ready(player_data)
	else:
		$ready.text = "Ready"
		get_parent().get_node("id_card").make_active()
		Server.player_not_ready()

	pass

func _on_open_lobby_pressed():
	player_panel.visible = true

func _on_close_panel_pressed():
	player_panel.visible = false


func recreate_player_panel():
	for i in range(1,player_panel.get_node("list").get_children().size()):
		player_panel.get_node("list").get_child(i).queue_free()
	print(Server.joined_player_data)
	print("here")
	
	for id in Server.joined_player_data:
		var new_row = row_demo.duplicate()
		list.add_child(new_row)
		print(new_row.name)
		new_row.get_node("name").text = Server.joined_player_data[id]["name"]
		if(Server.joined_player_data[id]["ready"] == true):
			new_row.get_node("is_ready").text = "ready"#str(Server.joined_player_data[id]["ready"])
		else:
			new_row.get_node("is_ready").text = "not ready"
		new_row.get_node("type").text = str(Server.joined_player_data[id]["is_host"])
		new_row.visible = true
		




func _on_main_menu_button_pressed():
	Server.close_connection()
#	Server.go_to_starting_scene()
