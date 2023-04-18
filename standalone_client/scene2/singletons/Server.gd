extends Node

var render_offset = 100 # the enemies will be seen render offset milliseconds late than the actual enemies
var sync_timer = null
var player_name = null
var player_detail = null
var network = NetworkedMultiplayerENet.new() # new instances for the network 
var ip = "127.0.0.1"
var client_clock = 0
var latency = 0
var delta_latency = 0
var decimal_collector = 0.00
var port = 1989  # default port on which game will be running
var latency_array = []
var time_offset = 0
var player_char
var world_node = null
var latest_time_frame = -1
var player_latest_time_frame = -1
var player_detail_buffer 
var game_time_buffer
var player_instances = {}

var joined_player_data = {}

onready var soul_model = preload("res://scenes/death_soul.tscn")
onready var player_model = preload("res://scenes/player_node_new.tscn")

signal lobby_changed() 
signal all_clients_ready()
signal all_clients_not_active()
signal new_server()
signal remove_server()

var server_cleanup_timer = Timer.new()
var socket_udp = PacketPeerUDP.new()
var listen_port = 23000
var known_servers = {}

export (int) var server_cleanup_threshold = 3

func _init():
	server_cleanup_timer.wait_time = server_cleanup_threshold
	server_cleanup_timer.one_shot = false
	server_cleanup_timer.autostart = true
	server_cleanup_timer.connect("timeout",self,"server_cleanup")
	add_child(server_cleanup_timer)
	pass
	
func _ready():
	known_servers.clear()
	
	var verdict = socket_udp.listen(listen_port)
	if(verdict != OK):
		print(verdict)
		print("cant_listen")
	else:
		print("udp_listening")
	
func _process(delta):  #checking for the rooms on the server
	if(socket_udp.get_available_packet_count() > 0):
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


func server_cleanup():  #deleting the rooms which have stopped responding
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
	return 

func ConnectToServer(ip_var,port_var):
	if(get_tree().has_network_peer()):
		get_tree().set_network_peer(null)

	network.close_connection(0)
	print(network.create_client(ip_var,port_var))
	
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

func _onpeerdisconnected(peer_id):
	print("peer_disconnected ",peer_id)
	joined_player_data.erase(peer_id)
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
	player_detail = null
	world_node = null
	latest_time_frame = -1
	player_latest_time_frame = -1
	for id in joined_player_data:
		joined_player_data[id]["ready"] = false
		
func close_connection():
	if(is_instance_valid(sync_timer)):
		sync_timer.queue_free()
	if(get_tree().has_network_peer()):
		Server.network.close_connection()
	LoadingScreen.change_scene("res://scene2/first_Screen.tscn")
	

func bomb_blast_over_server(location,time_of_render):
	rpc_id(1,"bomb_blast",time_of_render,location,network.get_unique_id())
	pass

remote func add_bomb():
	print("bomb added")
	player_char.bomb += 1
	#code for updating the ui of bomb
	player_char.get_node("ColorRect/grenade_count").text = str(player_char.bomb)
	pass

remote func make_start_button_active():
	emit_signal("all_clients_ready")

remote func make_start_button_inactive():
	emit_signal("all_clients_not_active")

remote func lobby_change(new_lobby_data):
	joined_player_data = new_lobby_data
	emit_signal("lobby_changed")

remote func open_lobby(client_type,joined_players_status):
	joined_player_data = joined_players_status
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
	
remote func initiate_world(player_details,game_time,map_code):  #function to recieve instructions about initiating world
	player_detail_buffer = player_details
	game_time_buffer = game_time
	if(map_code == 0):
		LoadingScreen.change_scene("res://scene2/test_new_copy.tscn")
	elif(map_code == 1):
		LoadingScreen.change_scene("res://scene2/dio_test_map.tscn")
	elif(map_code == 2):
		LoadingScreen.change_scene("res://scene2/oneonone_test.tscn")
func gun_shot(source,target):
	rpc_id(1,"gun_shot",OS.get_system_time_msecs() - Server.time_offset - render_offset,source,target)
	pass

remote func enemy_gun_shot(player_id,target):
	if(network.get_connection_status() == 2):
		if((player_id != network.get_unique_id())and(player_id in player_instances)):
			player_instances[player_id].shoot(target)
			pass

remote func returnservertime(server_time,client_time):  # function for getting the server time
	latency = (OS.get_system_time_msecs() - client_time)/2
	client_clock = server_time + latency
	if (is_instance_valid(world_node)):
		world_node.get_node("Label2").text = "Latency " + str((OS.get_system_time_msecs() - client_time)/2)
	time_offset = (OS.get_system_time_msecs() - latency) - server_time

func determine_latency():  # function for requesting server time to get the information about latency
	rpc_id(1,"fetchservertime",OS.get_system_time_msecs())


remote func returnlatency(client_time): # function for getting the rpc call from server about latency
	if (is_instance_valid(world_node)):
		world_node.get_node("Label2").text = "Latency " + str((OS.get_system_time_msecs() - client_time)/2)

remote func bomb_thrown(bomber_id,grenade_data):
#	print(bomber_id," ",grenade_data)
	var new_bomb = Gamedata.bomb_model.instance()
	Server.world_node.add_child(new_bomb)
	new_bomb.global_transform.origin = grenade_data["source"]
	var direction = grenade_data["target"] - grenade_data["source"]
	direction = direction.normalized()
	new_bomb.set_speed(direction)
	new_bomb.dormant = true
	pass

remote func update_player(player_state):  
	if (is_instance_valid(world_node) and is_instance_valid(player_char)):
		player_char.recon_state = player_state
		pass


remote func update_world(world_state):
	if (latest_time_frame  < world_state["T"] or latest_time_frame == -1) && world_node != null:
		latest_time_frame = world_state["T"]
		if(is_instance_valid(world_node)):
			world_node.ws_buffer.append(world_state)

remote func set_health(val,player_id,source = Vector3.ZERO):
#	print(val," ",player_id)
	if(network.get_connection_status() == 2):
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
	
remote func respawn(player_id,start_health,new_pos):
	if(network.get_connection_status() == 2):
		if(player_id == Server.network.get_unique_id() and is_instance_valid(player_char)):
			print("you respawned")
			player_char.get_node("death_screen").visible = false
			player_char.set_health(start_health)
			player_char.full_magazine()
			player_char.global_transform.origin = new_pos
			player_char.died = false
		
remote func recieve_message(msg):
	if(is_instance_valid(world_node)):
		world_node.get_node("message_log").add_message(msg)
	pass
	
remote func game_end(final_score):
	print("game ended")
	if(is_instance_valid(world_node)):
		world_node.get_node("game_end_screen").show_scores(final_score)
	
remote func hit_landed(damage):
	if(is_instance_valid(player_char)):
		player_char.add_damage_indicator(damage)
	pass 
