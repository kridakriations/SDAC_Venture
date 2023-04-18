extends VBoxContainer

onready var password_entry_box = get_parent().get_parent().get_node("password_entry")
onready var demo_node = $demo
var prev_server = {}
var server_details = {}

func _init():
	print(Server.connect("new_server",self,"new_server_list"))
	print(Server.connect("remove_server",self,"new_server_list"))

func _ready():
	new_server_list()
	
func join_server_pressed(server_ip,server_port):
	print("pressed ",server_ip," ",server_port)
	if(Server.known_servers.has(server_ip)):
		if(Server.known_servers[server_ip]["password"] == ""):
			var ip = server_ip
			var port = server_port
			var new_ip = ip
			while(ip != ip.trim_prefix(" ")):
				ip = ip.trim_prefix(" ")
			
			while(ip != ip.trim_suffix(" ")):
				ip = ip.trim_suffix(" ")
			
			var pl_name = get_node("../../../../join_button/Control/name_box").text
			if(pl_name == ""):
				get_node("../../../../..").error_screen.show_error("Enter the player name")
				return
			Server.player_name = pl_name
			
			Gamedata.temp_ip = ip
			Gamedata.temp_name = Server.player_name
			Server.ConnectToServer(ip,port)
			get_node("../../../../../waiting_panel").visible = true
		else:
			var pl_name = get_node("../../../../join_button/Control/name_box").text
			if(pl_name == ""):
				get_node("../../../../..").error_screen.show_error("Enter the player name")
				return
			password_entry_box.visible = true
			password_entry_box.server_password = Server.known_servers[server_ip]["password"]
			password_entry_box.server_ip = server_ip
			password_entry_box.server_port = server_port
			password_entry_box.get_node("server_name").text = Server.known_servers[server_ip]["name"]
		
		
func new_server_list(game_info = {}):
#	return
	for i in range(1,get_child_count()):
		get_child(i).queue_free()
	server_details = {}		
	print("list changed")
	print(Server.known_servers)
	for i in Server.known_servers:
		var new_row = demo_node.duplicate()
		add_child(new_row)
#		new_row.get_node("name_label").text = str(Server.known_servers[i]["name"])
		new_row.get_node("join_button").text = str(Server.known_servers[i]["name"])
		server_details[i] = {"ip":i,"port":Server.known_servers[i].port}
		new_row.visible = true
		new_row.get_node("join_button").connect("pressed",self,"join_server_pressed",[i,Server.known_servers[i].port])
		new_row.visible = true

	
