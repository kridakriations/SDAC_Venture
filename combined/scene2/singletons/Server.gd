extends Node

var render_offset = 100  # the enemies will be seen render offset milliseconds late than the actual enemies
var sync_timer = null 
var player_name = null
var player_detail = null
var network = NetworkedMultiplayerENet.new()  # new instances for the network 
var ip = "127.0.0.1"
var client_clock = 0
var latency = 0
var delta_latency = 0
var decimal_collector = 0.00
var deafault_port = 1989 # default port on which game will be running
var latency_array = [] 
var time_offset = 0
var player_char
var world_node = null
var latest_time_frame = -1
var player_latest_time_frame = -1
var player_detail_buffer 
var game_time_buffer
var send_updates = false
var player_instances = {}
var player_names = {}
var joined_player_status = {
}
var frame_to_send_updates = 0
var player_details = {}
var joined_player_data = {}
var player_states = {}
var player_healths = {}
var player_scores = {}
var player_kill_streaks = {}

var player_ready = 0
var host_id = -1
var game_started = false
var game_time = 0
var game_timer

var choosen_spawn_points


onready var soul_model = preload("res://scenes/death_soul.tscn")
onready var player_model = preload("res://scenes/player_node_new.tscn")  

signal lobby_changed() 
signal all_player_ready()
signal all_player_not_active()
signal new_server()
signal remove_server()

var server_timer = Timer.new()
var socket_udp = PacketPeerUDP.new()
var socket_udp_port = 23000
var known_servers = {}
var room_name 
var room_password
var is_host = null

export (int) var server_cleanup_threshold = 3

func _init():
	add_child(server_timer)
	pass
	
func start_searching():  #function to start search for the rooms available on the network
	is_host = false
	server_timer.stop()
	if(server_timer.is_connected("timeout",self,"broad_cast_server_info")):
		server_timer.disconnect("timeout",self,"broad_cast_server_info")
	if(server_timer.is_connected("timeout",self,"server_cleanup") == false):
		server_timer.connect("timeout",self,"server_cleanup")
	server_timer.wait_time = server_cleanup_threshold
	server_timer.one_shot = false
	server_timer.start()
	
	socket_udp.close()
	var verdict = socket_udp.listen(socket_udp_port)
	if(verdict == OK):
		print("listening")
	else:
		print("cant listen")
	pass

func stop_broadcasting():  # function to stop broadcasting room details on the network
	server_timer.stop()
	print("stopped")
#	socket_udp.close()
#	if(server_timer.is_connected("timeout",self,"broad_cast_server_info")):
#		server_timer.disconnect("timeout",self,"broad_cast_server_info")
#	if(server_timer.is_connected("timeout",self,"server_cleanup")):
#		server_timer.disconnect("timeout",self,"server_cleanup")
	pass

func clear_previous_server_data():  # function for clearing previous server instance data
	server_timer.stop()
	if(server_timer.is_connected("timeout",self,"server_cleanup")):
		server_timer.disconnect("timeout",self,"server_cleanup")	
	joined_player_status.clear()
	player_names.clear()
	player_states.clear()
	player_scores.clear()
	player_kill_streaks.clear()
	player_details.clear()
	pass

func start_broadcasting(room_name,room_password,max_pl): #  function to start broadcasting server details
	print(IP.get_local_interfaces())
	var actual_port = deafault_port
	var found = false
	for i in range(0,10):
		if(network.create_server(actual_port,max_pl) == OK):
			found = true
			break
		else:
			actual_port += 1
	print(actual_port," ",LoadingScreen.current_scene)
#	print()
	if(found == false):
		print("cant create server")
		if(LoadingScreen.current_scene.name == "first_screen"):
			LoadingScreen.current_scene.get_node("error_panel").show_error("Can't create a ROOM. Try closing all the background applications")
			pass
		return
	get_tree().set_network_peer(network)
	if(network.is_connected("peer_connected",self,"_onpeerconnected") == false):
		network.connect("peer_connected",self,"_onpeerconnected")
	if(network.is_connected("peer_disconnected",self,"_onpeerdisconnected") == false):
		network.connect("peer_disconnected",self,"_onpeerdisconnected")
	
	is_host = true
	clear_previous_server_data()
	if(server_timer.is_connected("timeout",self,"broad_cast_server_info") == true):
		server_timer.disconnect("timeout",self,"broad_cast_server_info")
	server_timer.connect("timeout",self,"broad_cast_server_info",[room_name,room_password,actual_port])
	server_timer.wait_time = 1
	server_timer.one_shot = false
	server_timer.start()
	
	socket_udp.close()
	socket_udp.set_broadcast_enabled(true)
	
	joined_player_status[1] = {
		"name":Gamedata.temp_name,
		"ready":false,
		"is_host":true
	}
	player_names[1] = Gamedata.temp_name

	lobby_change(joined_player_status)
	LoadingScreen.change_scene("res://host_scene.tscn")
	pass

remote func fetchservertime(client_time):  # function to fetch the server time (this is when this application will be running as client)
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(player_id,"returnservertime",OS.get_system_time_msecs(),client_time)

remote func determinelatency(client_time): # function to determine latency (this is when this application will be running as client)
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(player_id,"returnlatency",client_time)	



func _process(delta):
	if(socket_udp.get_available_packet_count() > 0):  # checking for the rooms available in the network
		var array_bytes = socket_udp.get_packet()
		var server_ip = socket_udp.get_packet_ip()
		var server_port = socket_udp.get_packet_port()
		
		if(server_ip != "" and server_port != 0):
			if(not known_servers.has(server_ip)):
				print("signal emitted")
				var server_message = array_bytes.get_string_from_ascii()
				var game_info = parse_json(server_message)
				print("new_game_info ",game_info)
				game_info.ip = server_ip
				game_info.last_seen = OS.get_unix_time()
				known_servers[server_ip] = game_info
				
				print("known_server added",known_servers)
				emit_signal("new_server",game_info)
			else:
				var game_info = known_servers[server_ip]
				game_info.last_seen = OS.get_unix_time() 
			
	pass

func server_cleanup():  # function for deleting the rooms that have stopped responding
	var now = OS.get_unix_time()
	var someserver_deleted = false
	for server_ip in known_servers:
		var server_info = known_servers[server_ip]
		if(now - server_info.last_seen > server_cleanup_threshold):
			known_servers.erase(server_ip)
			print("remove server ",server_ip)
			someserver_deleted = true
	if(someserver_deleted):
		emit_signal("remove_server")
	
func broad_cast_server_info(room_name,room_password,actual_port): #function for broadcasting server info (using the broadcasting ip)
	print("broadcasting")
	var server_info = {
		"name":room_name,
		"password":room_password,
		"port":actual_port
		}
		
	for i in range(0,256):
		socket_udp.set_dest_address("192.168."+str(i)+(".255"),socket_udp_port)
		var packet_message = to_json(server_info)
		var packet = packet_message.to_ascii()
		socket_udp.put_packet(packet)
		
	for i in range(0,256):
		socket_udp.set_dest_address("192.168."+str(i)+(".1"),socket_udp_port)
		var packet_message = to_json(server_info)
		var packet = packet_message.to_ascii()
		socket_udp.put_packet(packet)

	
	socket_udp.set_dest_address("255.255.255.255",socket_udp_port)
	var packet_message = to_json(server_info)
	var packet = packet_message.to_ascii()
	socket_udp.put_packet(packet)
	
	for i in range(0,256):
		var net = i 
		var broad = net | (15)
#		print(i," ",broad)
		socket_udp.set_dest_address("10.2."+str(i)+(".255"),socket_udp_port)
		packet_message = to_json(server_info)
		packet = packet_message.to_ascii()
		socket_udp.put_packet(packet)
	
	
	socket_udp.set_dest_address("192.168.137.1",socket_udp_port)
	packet_message = to_json(server_info)
	packet = packet_message.to_ascii()
	socket_udp.put_packet(packet)


func server_timer_timeout():	
	var now = OS.get_unix_time()
	var someserver_deleted = false
	for server_ip in known_servers:
		var server_info = known_servers[server_ip]
		if(now - server_info.last_seen > server_cleanup_threshold):
			known_servers.erase(server_ip)
			print("remove server ",server_ip)
			someserver_deleted = true
	if(someserver_deleted):
		emit_signal("remove_server")

func _exit_tree():
	socket_udp.close()

func _physics_process(delta): 
#	print(player_states.size()," ",joined_player_status.size()," ",player_states.size())
	if(player_states.size() == joined_player_status.size() and player_states.size() > 0 and game_started):
		send_updates = true
		if(is_instance_valid(game_timer) == false):
			game_timer = Timer.new()
			game_timer.wait_time = game_time
			game_timer.one_shot = true
			add_child(game_timer)
			game_timer.start()
			game_timer.connect("timeout",self,"end_game_over_network")
		
#	print(frame_to_send_updates)
	if(frame_to_send_updates <= 0 and send_updates and game_started == true):  #function to send updates over network
#		print("sent_updates")
		{
			"torso_degree":"<put data>",
			"head_degree":"<put data>",
			"player_transform":"<put data>",
			"left_leg_degrees":"<put data>",
			"right_leg_degrees":"<put data>"
		}
		var temp_player_state = {}
		for temp_id in player_states:
			var temp_state = {}
			for val in player_states[temp_id]:
				temp_state[val] = player_states[temp_id][val]
			temp_player_state[temp_id] = temp_state
			
			
		var world_state = {"T":1,
			"player_data":temp_player_state
		}
		
		world_state["T"] = OS.get_system_time_msecs()
		if(is_instance_valid(game_timer)):
			world_state["game_time"] = game_timer.wait_time
		rpc_unreliable("update_world",world_state)
		update_world(world_state)

		frame_to_send_updates += 2
	else:
#		print("not send updates")
		frame_to_send_updates -= 1
		frame_to_send_updates = max(frame_to_send_updates,0)
	return 

func stop_creating_client(): 
	if(get_tree().has_network_peer()):
		get_tree().set_network_peer(null)
	network.close_connection(0)
	

func ConnectToServer(ip_var,port_var):
	if(get_tree().has_network_peer()):
		get_tree().set_network_peer(null)
	network.close_connection(0)
	print(network.create_client(ip_var,port_var))
	
	print(network.get_connection_status())
	
	if((network.get_connection_status() == 1)or(network.get_connection_status() == 2)):
		get_tree().set_network_peer(network)
	if(network.is_connected("connection_failed",self,"_onconnectionfailed") == false):
		network.connect("connection_failed",self,"_onconnectionfailed")
	if(network.is_connected("connection_succeeded",self,"_onconnectionsucceeded") == false):
		network.connect("connection_succeeded",self,"_onconnectionsucceeded")
	if(network.is_connected("server_disconnected",self,"_onserverdisconnected") == false):
		network.connect("server_disconnected",self,"_onserverdisconnected")
	if(network.is_connected("peer_disconnected",self,"_onpeerdisconnected") == false):
		network.connect("peer_disconnected",self,"_onpeerdisconnected")
	
func _onserverdisconnected():
	print("disconnected from server")
	disconnection_drill()
	
func _onconnectionfailed():
	print("onconnectionfailed")

func _onpeerconnected(new_player_id):
	print("new_player_connected with id ",new_player_id)
	if(game_started == true):
		print("game_started")
		network.disconnect_peer(new_player_id)
	joined_player_status[new_player_id] = {
		"name":null,
		"ready":false,
		"is_host":true
	}
	joined_player_status[new_player_id]["is_host"] = "CLIENT"

func _onpeerdisconnected(peer_id):
	print("peer_disconnected ",peer_id)
	joined_player_data.erase(peer_id)
	if(peer_id in joined_player_data):
		joined_player_data.erase(peer_id)
	if(peer_id in player_names):
		player_names.erase(peer_id)
	if(peer_id in player_healths):
		player_healths.erase(peer_id)
	if(peer_id in player_scores):
		player_scores.erase(peer_id)	
	if(peer_id in player_kill_streaks):
		player_kill_streaks.erase(peer_id)
	emit_signal("lobby_changed")
	if(peer_id in player_instances):
		player_instances[peer_id].queue_free()
		player_instances.erase(peer_id)
	
func _onconnectionsucceeded():
	print("onconnectionsucceeded with client id ",network.get_unique_id())
	if(1 in get_tree().get_network_connected_peers()):
		rpc_id(1,"fetchservertime",OS.get_system_time_msecs())
	sync_timer = Timer.new()
	sync_timer.name = "sync_timer"
	sync_timer.wait_time = 0.1
	sync_timer.autostart = true
	add_child(sync_timer)
	sync_timer.connect("timeout",self,"determine_latency")
	print("requesting to add player name")
	rpc_id(1,"add_player_name",player_name)
	
func disconnection_drill():
	print("disconnection_drill")
	sync_timer.queue_free()
	network.close_connection()
	LoadingScreen.change_scene("res://scene2/first_Screen.tscn")
	pass
	
func send_input(dat):
	rpc_id(1,"process_input",dat)
	pass

func player_ready(info):
	rpc_id(1,"client_ready",info)
	pass	

func player_not_ready():
	rpc_id(1,"client_not_ready")
	pass

func reload_gun():
	rpc_id(1,"reload_gun")
	
func end_game():
	player_instances = {}
	player_details.clear()
	latest_time_frame = -1
	player_latest_time_frame = -1
	for id in joined_player_data:
		joined_player_data[id]["ready"] = false
	
func end_game_over_network():
	game_timer.queue_free()
	game_started = false
	send_updates = false
	rpc("game_end",player_scores)
	game_end(player_scores)
	pass
		
func close_connection():
	LoadingScreen.change_scene("res://scene2/first_Screen.tscn")
	game_started = false
	send_updates = false
	clear_previous_server_data()
	if(is_instance_valid(sync_timer)):
		sync_timer.queue_free()
	if(get_tree().has_network_peer()):
		Server.network.close_connection()
	
func clear_previous_game_data():
	player_healths.clear()
	player_kill_streaks.clear()
	player_scores.clear()

func initiate_game_data():
	for id in player_details:
		player_healths[id] = Gamedata.player_max_health
		player_kill_streaks[id] = 0
		player_scores[id] = {
			"KILLS":0,
			"DEATH":0,
			"SCORE":0,
			"HEADSHOTS":0,
			"SHOTS_FIRED":0,
			"ACCURACY":0.0,
			"HITS":0
		}
		

func start_game(info,map_code,recieved_game_time):
	game_started = true
	stop_broadcasting()
	player_details[1] = info
	clear_previous_game_data()
	initiate_game_data()
#	player_healths[1] = Gamedata.player_max_health
	game_time = recieved_game_time * 60
#	game_time = 60
	var sp = 0
	var assigned_spawn_points = {}
	for i in joined_player_data:
		assigned_spawn_points[i] = sp
		sp += 1
	var player_details_data = {}
	for id in Server.player_details:
		player_details_data[id] = {
			"health":Gamedata.player_max_health,
			"player_name":Server.player_names[id],
			"player_detail":Server.player_details[id],
			
		}
		pass
	rpc("initiate_world",assigned_spawn_points,player_details_data,game_time,map_code)	
	initiate_world(assigned_spawn_points,player_details_data,game_time,map_code)
	
	
#	LoadingScreen.change_scene("res://scene2/test_new_copy.tscn")



func bomb_blast_over_server(location,time_of_render):
#	if(network.get_unique_id() == 1):
#		
	rpc_id(1,"bomb_blast",time_of_render,location,network.get_unique_id())
	pass

func respawn_player_over_network(player_id,respawn_timer):
	respawn_timer.queue_free()
	if(is_instance_valid(world_node)):
		var new_spawn_point =(randi()%(world_node.spawn_points.get_children().size()))
		player_healths[player_id] = Gamedata.player_max_health
		if(player_id == 1):
			respawn(player_id,Gamedata.player_max_health,new_spawn_point)
		else:
			rpc_id(player_id,"respawn",player_id,Gamedata.player_max_health,new_spawn_point)
		var message = {
			"TYPE" : "SPAWN",
			"BODY" : {
				"PLAYER_ID":player_id,
				"NEW_POS":new_spawn_point
			}
		}
		rpc("recieve_message",message)
		recieve_message(message)

remote func update_player_state(new_state,host = false):
	var player_id
	if(host == true):
		player_id = 1
	else:
		player_id = get_tree().get_rpc_sender_id()
	player_states[player_id] = new_state
	


remote func client_ready(info):
	var player_id = get_tree().get_rpc_sender_id()
	player_details[player_id] = info
	joined_player_status[player_id]["ready"] = true
	rpc("lobby_change",joined_player_status)
	lobby_change(joined_player_status)
	player_ready = 0
	for ply in  joined_player_status:
		if(joined_player_status[ply]["ready"] == true):
			player_ready += 1
	if(player_ready == get_tree().get_network_connected_peers().size()-1):

		emit_signal("all_player_ready")

remote func client_not_ready():
	var player_id = get_tree().get_rpc_sender_id()
	player_details.erase(player_id)
	joined_player_status[player_id]["ready"] = false
	rpc("lobby_change",joined_player_status)
	lobby_change(joined_player_status)
	player_ready = 0
	for ply in  joined_player_status:
		if(joined_player_status[ply]["ready"] == true):
			player_ready += 1
	if(player_ready < get_tree().get_network_connected_peers().size()-1):
		emit_signal("all_player_not_active")

#	Logging.get_node("players_list").recreate_player_list(joined_player_status)

remote func add_bomb():
	print("bomb added")
	player_char.bomb += 1
	#code for updating the ui of bomb
	player_char.get_node("ColorRect/grenade_count").text = str(player_char.bomb)
	pass


remote func player_hit(shooter_id,victim_id,damage_taken,shot_type,source = Vector3.ZERO):
	if(player_healths[victim_id] <= 0):
		return
		
#	var shooter_id = get_tree().get_rpc_sender_id()
	
	player_healths[victim_id] = max(0,player_healths[victim_id]-damage_taken)
	if(network.get_unique_id() != victim_id):
		rpc_id(victim_id,"set_health",victim_id,player_healths[victim_id],source)
	else:
		set_health(victim_id,player_healths[victim_id],source)
	if(shot_type!= "BOMB_SHOT"):
		player_scores[shooter_id]["HITS"] += 1
		if(player_scores[shooter_id]["SHOTS_FIRED"] > 0):
			player_scores[shooter_id]["ACCURACY"] = float(player_scores[shooter_id]["HITS"])/float(player_scores[shooter_id]["SHOTS_FIRED"])
	
	if(shot_type == "HEADSHOT"):
		player_scores[shooter_id]["HEADSHOTS"] += 1
	
	if(player_healths[victim_id] <= 0):
		var new_respawn_timer = Timer.new()
		new_respawn_timer.wait_time = Gamedata.player_respawn_time
		new_respawn_timer.one_shot = true
		add_child(new_respawn_timer)
		new_respawn_timer.start()
		new_respawn_timer.connect("timeout",self,"respawn_player_over_network",[victim_id,new_respawn_timer])
		
		player_kill_streaks[victim_id] = 0
		if(shooter_id != victim_id):
			player_kill_streaks[shooter_id] += 1
		if(player_kill_streaks[shooter_id] >= 3):
			player_kill_streaks[shooter_id] = 0
			if(shooter_id == 1):
				add_bomb()
			else:
				rpc_id(shooter_id,"add_bomb")
			pass
		if(victim_id != shooter_id):
			if(shooter_id in player_scores):
				player_scores[shooter_id]["KILLS"] += 1
				player_scores[shooter_id]["SCORE"] += 10
			if(victim_id in player_scores):
				player_scores[victim_id]["DEATH"] += 1
				player_scores[victim_id]["SCORE"] += (-5)
		
		if(victim_id != 1):
			rpc_id(victim_id,"died",victim_id,player_scores)
		else:
			died(victim_id,player_scores)
			
		var msg = {
			"TYPE":"DEATH",
			"BODY":{
				"SHOOTER":shooter_id,
				"SHOOTER_NAME":player_names[shooter_id],
				"VICTIM":victim_id,
				"VICTIM_NAME":player_names[victim_id],
				"SHOT_TYPE":shot_type
			},
		}
		rpc("recieve_message",msg)
		recieve_message(msg)
	
remote func lobby_change(new_lobby_data):
	joined_player_data = new_lobby_data
	emit_signal("lobby_changed")

remote func open_lobby(client_type,joined_players_status):
	joined_player_data = joined_players_status
#	print(client_type)
	if(client_type == "HOST"):
		LoadingScreen.change_scene("res://host_scene.tscn")
	else:
		LoadingScreen.change_scene("res://main_scene.tscn")

remote func reload_gun_dummy(ply):
	if(ply in player_instances):
		player_instances[ply].reload_gun()
		pass
	pass

remote func swap_gun_dummy(ply):
	if(network.get_connection_status() == 2):
		if(ply == network.get_unique_id()):
			return
		if(ply in player_instances):
			player_instances[ply].swap_gun()
			pass
		pass
	
remote func initiate_world(assigned_spawn_points,player_details,game_time,map_code):
	player_detail_buffer = player_details
	choosen_spawn_points = assigned_spawn_points
	game_time_buffer = game_time
	if(map_code == 0):
		LoadingScreen.change_scene("res://scene2/test_new_copy.tscn")
	elif(map_code == 1):
		LoadingScreen.change_scene("res://scene2/dio_new_test_map.tscn")
	elif(map_code == 2):
		LoadingScreen.change_scene("res://scene2/oneonone_test.tscn")

func gun_shot(source,target):
	rpc_id(1,"gun_shot",OS.get_system_time_msecs() - Server.time_offset - render_offset,source,target)


remote func add_player_name(player_name):
	var player_id = get_tree().get_rpc_sender_id()
	player_names[player_id] = player_name
	joined_player_status[player_id]["name"] = player_name
	if(player_id in get_tree().get_network_connected_peers()):
		rpc_id(player_id,"open_lobby","CLIENT",joined_player_status)
	rpc("lobby_change",joined_player_status)
	lobby_change(joined_player_status)

remote func enemy_gun_shot(player_id,target):
	if(network.get_connection_status() == 2):
		if((player_id != network.get_unique_id())and(player_id in player_instances)):
			player_instances[player_id].shoot(target)
			pass

remote func returnservertime(server_time,client_time):
	latency = (OS.get_system_time_msecs() - client_time)/2
	client_clock = server_time + latency
	if (is_instance_valid(world_node)):
		world_node.get_node("Label2").text = "Latency " + str((OS.get_system_time_msecs() - client_time)/2)
	time_offset = (OS.get_system_time_msecs() - latency) - server_time

func determine_latency():
	rpc_id(1,"fetchservertime",OS.get_system_time_msecs())


remote func returnlatency(client_time):
	if (is_instance_valid(world_node)):
		world_node.get_node("Label2").text = "Latency " + str((OS.get_system_time_msecs() - client_time)/2)

remote func bomb_thrown_over_network(bomber_id,greande_info):
	bomb_thrown(bomber_id,greande_info)
	rpc("bomb_thrown",bomber_id,greande_info)

remote func bomb_thrown(bomber_id,grenade_data):
	if(bomber_id != network.get_unique_id()):
		var new_bomb = Gamedata.bomb_model.instance()
		Server.world_node.add_child(new_bomb)
		new_bomb.global_transform.origin = grenade_data["source"]
		var direction = grenade_data["target"] - grenade_data["source"]
		direction = direction.normalized()
		new_bomb.set_speed(direction)
		new_bomb.dormant = true
		

remote func update_player(player_state):
	if (is_instance_valid(world_node) and is_instance_valid(player_char)):
		player_char.recon_state = player_state
		pass


remote func update_world(world_state):
	if(world_state.has("game_time")):
		if(is_instance_valid(Server.world_node)):
			world_node.update_game_timer(world_state["game_time"])
			pass
	if (latest_time_frame  < world_state["T"] or latest_time_frame == -1) && world_node != null:
		latest_time_frame = world_state["T"]
		if(is_instance_valid(world_node)):
			world_node.ws_buffer.append(world_state)

remote func enemy_gun_shot_over_network(shooter_id,target):
	player_scores[shooter_id]["SHOTS_FIRED"] += 1
	rpc_unreliable("enemy_gun_shot",shooter_id,target)
	enemy_gun_shot(shooter_id,target)
	pass

remote func swap_gun_over_network(swapper_id):
	rpc_unreliable("swap_gun_dummy",swapper_id)
	swap_gun_dummy(swapper_id)
	pass

remote func set_health(player_id,val,source = Vector3.ZERO):
#	print(val," ",player_id)
	if(network.get_connection_status() == 2):
		print("setting_health ",player_id," ",Server.network.get_unique_id())
		if(player_id == Server.network.get_unique_id()):
			if(is_instance_valid(player_char)):
				if(player_char.get_node("ColorRect/health_bar").value > val):
					player_char.got_hit(source)
				player_char.set_health(val)
		
remote func died(player_id,new_scores):
	if(network.get_connection_status() == 2 and is_instance_valid(world_node) and is_instance_valid(player_char)):
		if(player_id == Server.network.get_unique_id() ):
			print("you dead")
			
			var new_soul = soul_model.instance()
			world_node.add_child(new_soul)
			new_soul.global_transform.origin = player_char.global_transform.origin
			
			new_soul.get_node("Particles").emitting = true
		
		player_char.died = true
		player_char.get_node("death_screen").visible = true
		player_char.get_node("death_screen").start_countdown()
		player_char.get_node("death_screen").show_scores(new_scores)
	
remote func respawn(player_id,start_health,new_spawn_point):
	if(network.get_connection_status() == 2):
		if(player_id == Server.network.get_unique_id() and is_instance_valid(player_char)):
			print("you respawned")
			player_char.get_node("death_screen").visible = false
			player_char.set_health(start_health)
			player_char.full_magazine()
			player_char.global_transform.origin = world_node.get_node("level/spawn_points").get_child(new_spawn_point).global_transform.origin
			player_char.died = false
		
remote func recieve_message(msg):
	if(is_instance_valid(world_node)):
		world_node.get_node("message_log").add_message(msg)
	pass
	
remote func game_end(final_score):
	print("game ended")
	game_started = false
	if(is_instance_valid(world_node)):
		world_node.get_node("game_end_screen").show_scores(final_score)
	
remote func hit_landed(damage):
	if(is_instance_valid(player_char)):
		player_char.add_damage_indicator(damage)
	pass 
