extends Node

onready var player_model = preload("res://scenes/player.tscn")
onready var collision_model = preload("res://scenes/server_player.tscn")

onready var world_node = get_parent().find_node("world")

var server_name
var server_password
var broadcast_inteval = 1
var server_info = {"name":"lan_game"}
var socket_udp
var broadcast_timer = Timer.new()
var broadcast_port = 23000

var world_history = []
var details_panel
var player_instances = {}
var player_names = {}
var player_details = {}
var coll_players = {}
var count_players = 0
var network  = NetworkedMultiplayerENet.new()
var port = 45000
var max_players = 100
var game_started = false
var joined_player_status = {
}
var game_time = 0
var host_id = -1
var player_ready = 0

func _enter_tree():

	broadcast_timer.wait_time = broadcast_inteval
	broadcast_timer.one_shot = false
	broadcast_timer.autostart = false
	
	add_child(broadcast_timer)
	broadcast_timer.connect("timeout",self,"server_advertise")

	socket_udp = PacketPeerUDP.new()
	socket_udp.set_broadcast_enabled(true)
	
#	socket_udp.set_dest_address("192.168.156.255",broadcast_port)
	
func server_advertise():
	for i in range(0,256):
		socket_udp.set_dest_address("192.168."+str(i)+(".255"),broadcast_port)
		server_info.name = server_name
		server_info.password = server_password
		server_info.port = port
		var packet_message = to_json(server_info)
		var packet = packet_message.to_ascii()
		socket_udp.put_packet(packet)
		
	socket_udp.set_dest_address("255.255.255.255",broadcast_port)
	Logging.get_node("socket_send").text = str(int(Logging.get_node("socket_send").text)+1)
	server_info.name = server_name
	server_info.password = server_password
	server_info.port = port
	var packet_message = to_json(server_info)
	var packet = packet_message.to_ascii()
	socket_udp.put_packet(packet)
	
	socket_udp.set_dest_address("127.0.0.1",broadcast_port)
	Logging.get_node("socket_send").text = str(int(Logging.get_node("socket_send").text)+1)
	server_info.name = server_name
	server_info.password = server_password
	server_info.port = port
	packet_message = to_json(server_info)
	packet = packet_message.to_ascii()
	socket_udp.put_packet(packet)
	
func _exit_tree():
	broadcast_timer.stop()
	if(socket_udp != null):
		socket_udp.close()


func _ready():
	print(IP.get_local_addresses())
#	if(OS.get_cmdline_args().size() < 2):
#		StartServer(1989,8)
#	else:	
#		var arr = OS.get_cmdline_args()
#		StartServer(int(arr[0]),int(arr[1]))
#	pass
		
	
func StartServer(port_number,max_pl,room_name = "demo",password = ""):
	network.create_server(port_number,max_pl)
	get_tree().set_network_peer(network)
	print("Server Started")
	Logging.get_node("server_details").visible = false
	port = port_number
	server_name = room_name
	server_password = password
	broadcast_timer.start()
#	game_time = minutes * 60
	var interfaces = IP.get_local_interfaces()
	var found = false

	print("one or both of the IP addresses should work")
	for i in interfaces:
		if(i["friendly"] == ("Wi-Fi")):
			if(i["addresses"].size()>1):
				print(i["addresses"][1])
		if(i["friendly"] == "Local Area Connection* 2"):
			if(i["addresses"].size()>1):
				print(i["addresses"][1])

	network.connect("peer_connected",self,"_Peer_Connected")
	network.connect("peer_disconnected",self,"_Peer_Disconnected")
	
func _Peer_Connected(player_id):
	print("User "+str(player_id) + "Connected")
	if(game_started == true):
		print("game_started")
		network.disconnect_peer(player_id)
	joined_player_status[player_id] = {
		"name":null,
		"ready":false,
		"is_host":true
	}
	if(get_tree().get_network_connected_peers().size() == 1):
		joined_player_status[player_id]["is_host"] = "HOST"
		host_id = player_id
	else:
		joined_player_status[player_id]["is_host"] = "CLIENT"

func _Peer_Disconnected(player_id):
	print("User "+str(player_id) + "Disconnected")
	if(player_id in joined_player_status):
		joined_player_status.erase(player_id)
	if(player_id in player_instances):
		if(is_instance_valid(player_instances[player_id])):
			player_instances[player_id].queue_free()
		player_instances.erase(player_id)
	if(player_id in player_names):
		player_names.erase(player_id)
	if(player_id in player_details):
		player_details.erase(player_id)
	if(player_id in coll_players):
		if(is_instance_valid(coll_players[player_id])):	
			coll_players[player_id].queue_free()
		coll_players.erase(player_id)
	if((get_tree().get_network_connected_peers().size() == 0) or (host_id == player_id)):
		host_id = -1
		var connected_peers = get_tree().get_network_connected_peers()
		for id in connected_peers:
			network.disconnect_peer(id)
		get_tree().change_scene("res://scenes/start.tscn")
		game_started = false
		broadcast_timer.start()
		print("game started ",game_started)
		pass
	player_ready = 0
	for ply in  joined_player_status:
		if(joined_player_status[ply]["ready"] == true):
			player_ready += 1
	if(player_ready == get_tree().get_network_connected_peers().size()-1):
		if(host_id in get_tree().get_network_connected_peers()):
			rpc_id(host_id,"make_start_button_active")
		
	Logging.get_node("players_list").recreate_player_list(joined_player_status)

func end_game():
	game_started = false
	broadcast_timer.start()
	player_instances = {}
	coll_players = {}
	world_history = []
	rpc_id(0,"game_end",world_node.player_score)
	get_tree().change_scene("res://scenes/start.tscn")
	pass

remote func start_game(info,map_code,recieved_game_time):
	var player_id = get_tree().get_rpc_sender_id()
	if(player_id != host_id):
		return
	player_details[player_id] = info
	print("start_game_notification_recieved")
	game_time = recieved_game_time * 60
	if(map_code == 0):
		get_tree().change_scene("res://scenes/world_copy.tscn")
	elif(map_code == 1):
		get_tree().change_scene("res://scenes/world_copy_dio.tscn")
	elif(map_code == 2):
		get_tree().change_scene("res://scenes/world_copy_1v1.tscn")

remote func client_ready(info):
	var player_id = get_tree().get_rpc_sender_id()
	player_details[player_id] = info
	joined_player_status[player_id]["ready"] = true
	rpc("lobby_change",joined_player_status)
#	player_ready += 1
	player_ready = 0
	for ply in  joined_player_status:
		if(joined_player_status[ply]["ready"] == true):
			player_ready += 1
	if(player_ready == get_tree().get_network_connected_peers().size()-1):
		rpc_id(host_id,"make_start_button_active")
		
	Logging.get_node("players_list").recreate_player_list(joined_player_status)


remote func client_not_ready():
	var player_id = get_tree().get_rpc_sender_id()
	player_details.erase(player_id)
	joined_player_status[player_id]["ready"] = false
	rpc("lobby_change",joined_player_status)
#	player_ready -= 1
	player_ready = 0
	for ply in  joined_player_status:
		if(joined_player_status[ply]["ready"] == true):
			player_ready += 1
	if(player_ready < get_tree().get_network_connected_peers().size()-1):
		rpc_id(host_id,"make_start_button_inactive")

	Logging.get_node("players_list").recreate_player_list(joined_player_status)

remote func fetchservertime(client_time):
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(player_id,"returnservertime",OS.get_system_time_msecs(),client_time)
	
remote func spawn_player(player_transform):
	var new_player_instance = player_model.instance()
	world_node.add_child(new_player_instance)
	new_player_instance.global_transform = player_transform
	var player_id = get_tree().get_rpc_sender_id()
	player_instances[player_id] = new_player_instance
	
remote func process_input(dat):
	if(game_started == true):
		var player_id = get_tree().get_rpc_sender_id()
		player_instances[player_id].input_queue.append(dat)
	
remote func jump():
	var player_id = get_tree().get_rpc_sender_id()
	player_instances[player_id].jump()
	
remote func determinelatency(client_time):
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(player_id,"returnlatency",client_time)	

remote func bomb_thrown(bomber,grenade_input):
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(0,"bomb_thrown",player_id,grenade_input)
	pass

remote func gun_shot(render_time,source,target,player_id = null):
	if(player_id == null):
		player_id = get_tree().get_rpc_sender_id()
	if !(player_id in player_instances):
		return 	
	
	for i in range(world_history.size()):
		if((i+1 < world_history.size()) and (world_history[i]["T"] <= render_time and world_history[i+1]["T"] > render_time)):
			
			var prev_time = world_history[i]["T"]
			var next_time = world_history[i+1]["T"]
			var inter_factor = float(render_time - prev_time)/float(next_time - prev_time)
			for id in player_instances:
				if(id == player_id):
					coll_players[id].make_dormant()
					continue
				if(player_instances[id].dead == true):
					coll_players[id].make_dormant()
					continue
				coll_players[id].make_alive()
				coll_players[id].global_transform.origin = lerp(world_history[i]["player_data"][id]["player_position"],world_history[i+1]["player_data"][id]["player_position"],inter_factor)
				coll_players[id].torso.rotation_degrees.y = lerp(world_history[i]["player_data"][id]["torso_degree"],world_history[i+1]["player_data"][id]["torso_degree"],inter_factor)
				coll_players[id].head.rotation_degrees.x = lerp(world_history[i]["player_data"][id]["head_degree"],world_history[i+1]["player_data"][id]["head_degree"],inter_factor)
				coll_players[id].force_update_transform()
				coll_players[id].torso.force_update_transform()
				coll_players[id].head.force_update_transform()
				coll_players[id].left_leg.get_child(0).force_update_transform()
				coll_players[id].right_leg.get_child(0).force_update_transform()

				
			if player_id in player_instances:
				var space_state = world_node.get_world().direct_space_state
				var dict = space_state.intersect_ray(source,target,[coll_players[player_id].torso.get_rid(),coll_players[player_id].head.get_rid()],7,true,true)
				player_instances[player_id].shoot()
				if(dict.empty() == false):
					var collider = dict.collider
					if(collider.is_in_group("body")):
						var victim_id = collider.get_parent().main_id
						player_instances[victim_id].damage(player_instances[player_id].gun_damage(),player_id,"BODYSHOT",source)
						rpc_unreliable_id(player_id,"hit_landed",player_instances[player_id].gun_damage())
					elif(collider.is_in_group("head")):
						var victim_id = collider.get_parent().get_parent().main_id
						player_instances[victim_id].damage(player_instances[player_id].gun_head_damage(),player_id,"HEADSHOT",source)
						rpc_unreliable_id(player_id,"hit_landed",player_instances[player_id].gun_head_damage())
					elif(collider.is_in_group("lower_arm")):
						var victim_id = collider.get_node("../../../../../../").main_id
						player_instances[victim_id].damage(player_instances[player_id].gun_damage(),player_id,"HANDSHOT",source)
						rpc_unreliable_id(player_id,"hit_landed",player_instances[player_id].gun_damage())
					elif(collider.is_in_group("upper_arm")):
						var victim_id = collider.get_node("../../../../../").main_id
						player_instances[victim_id].damage(player_instances[player_id].gun_damage(),player_id,"HANDSHOT",source)
						rpc_unreliable_id(player_id,"hit_landed",player_instances[player_id].gun_damage())
					elif(collider.is_in_group("leg")):
						var victim_id = collider.get_node("../../../../").main_id
						player_instances[victim_id].damage(player_instances[player_id].gun_damage(),player_id,"LEGSHOT",source)
						rpc_unreliable_id(player_id,"hit_landed",player_instances[player_id].gun_damage())
			break

remote func bomb_blast(render_time,location,player_id):
	
	if(player_id == null):
		player_id = get_tree().get_rpc_sender_id()
	if !(player_id in player_instances):
		return 	
		
	for i in range(world_history.size()):
		if((i+1 < world_history.size()) and (world_history[i]["T"] <= render_time and world_history[i+1]["T"] > render_time)):
			
			var prev_time = world_history[i]["T"]
			var next_time = world_history[i+1]["T"]
			var inter_factor = float(render_time - prev_time)/float(next_time - prev_time)
			for id in player_instances:
#				if(id == player_id):
#					coll_players[id].make_dormant()
#					continue
				if(player_instances[id].dead == true):
					coll_players[id].make_dormant()
					continue
				coll_players[id].make_alive()
				coll_players[id].global_transform.origin = lerp(world_history[i]["player_data"][id]["player_position"],world_history[i+1]["player_data"][id]["player_position"],inter_factor)
				coll_players[id].torso.rotation_degrees.y = lerp(world_history[i]["player_data"][id]["torso_degree"],world_history[i+1]["player_data"][id]["torso_degree"],inter_factor)
				coll_players[id].head.rotation_degrees.x = lerp(world_history[i]["player_data"][id]["head_degree"],world_history[i+1]["player_data"][id]["head_degree"],inter_factor)
				coll_players[id].force_update_transform()
				coll_players[id].torso.force_update_transform()
				coll_players[id].head.force_update_transform()
				coll_players[id].left_leg.get_child(0).force_update_transform()
				coll_players[id].right_leg.get_child(0).force_update_transform()
	
	var space_state = world_node.get_world().direct_space_state
	for id in player_instances:
		var dict = space_state.intersect_ray(location,coll_players[id].head.global_transform.origin,[],5,true,true)
		if(dict.empty() == false):
			var dist_from_blast = location.distance_squared_to(coll_players[id].head.global_transform.origin)
			var collider = dict.collider
			if(dist_from_blast < 100):
				var damage = 100
				if(collider.is_in_group("body")):
					var victim_id = collider.get_parent().main_id
					player_instances[victim_id].damage(100,player_id,"BOMB",location)
					rpc_unreliable_id(player_id,"hit_landed",100)
				elif(collider.is_in_group("head")):
					var victim_id = collider.get_parent().get_parent().main_id
					player_instances[victim_id].damage(100,player_id,"BOMB",location)
					rpc_unreliable_id(player_id,"hit_landed",100)
				elif(collider.is_in_group("lower_arm")):
					var victim_id = collider.get_node("../../../../../../").main_id
					player_instances[victim_id].damage(100,player_id,"BOMB",location)
					rpc_unreliable_id(player_id,"hit_landed",100)
				elif(collider.is_in_group("upper_arm")):
					var victim_id = collider.get_node("../../../../../").main_id
					player_instances[victim_id].damage(100,player_id,"BOMB",location)
					rpc_unreliable_id(player_id,"hit_landed",100)
				elif(collider.is_in_group("leg")):
					var victim_id = collider.get_node("../../../../").main_id
					player_instances[victim_id].damage(100,player_id,"BOMB",location)
					rpc_unreliable_id(player_id,"hit_landed",100)
	
	
remote func reload_gun():
	var player_id = get_tree().get_rpc_sender_id()
	
	if(player_id in player_instances):
		
		player_instances[player_id].reload()
		rpc_unreliable_id(0,"reload_gun_dummy",player_id)
	pass


func send_world_state():
	{
		"torso_degree":"<put data>",
		"head_degree":"<put data>",
		"player_transform":"<put data>",
		"left_leg_degrees":"<put data>",
		"right_leg_degrees":"<put data>"
	}
	var world_state = {"T":1,
		"player_data":{}
	}
	var player_data = {}
	for id in player_instances:
		world_state["player_data"][id] = {
			"torso_degree":player_instances[id].torso.rotation_degrees.y,
			"head_degree":player_instances[id].head_x,
			"player_position":player_instances[id].global_transform.origin,
			"left_leg_degrees":player_instances[id].left_leg_rotation,
			"right_leg_degrees":player_instances[id].right_leg_rotation,
			"step_sound":player_instances[id].step_sound_playing
		}
	while((world_history.size() > 0) and (world_history[0]["T"] < OS.get_system_time_msecs() - 1000)):
		world_history.pop_front()
	
	world_state["T"] = OS.get_system_time_msecs()
	world_history.push_back(world_state)
	rpc_unreliable_id(0,"update_world",world_state)

remote func get_health():
	pass

remote func add_player_name(player_name):
	var player_id = get_tree().get_rpc_sender_id()
	player_names[player_id] = player_name
	joined_player_status[player_id]["name"] = player_name
	if(player_ready < get_tree().get_network_connected_peers().size()-1):
		rpc_id(host_id,"make_start_button_inactive")
		pass
	if(joined_player_status[player_id]["is_host"] == "HOST"):
		rpc_id(player_id,"open_lobby","HOST",joined_player_status)
	else:
		rpc_id(player_id,"open_lobby","CLIENT",joined_player_status)
	rpc("lobby_change",joined_player_status)
	Logging.get_node("players_list").recreate_player_list(joined_player_status)
	
	
func respawn_player(player_id):
	var new_pos = world_node.spawn_nodes.get_child(randi()%(world_node.spawn_nodes.get_children().size())).global_transform.origin
	player_instances[player_id].global_transform.origin = new_pos
	player_instances[player_id].full_magazine()
	rpc_id(player_id,"respawn",player_id,GameData.player_max_health,new_pos)
	var message = {
		"TYPE" : "SPAWN",
		"BODY" : {
			"PLAYER_ID":player_id,
			"NEW_POS":new_pos
		}
	}
	rpc_id(0,"recieve_message",message)


