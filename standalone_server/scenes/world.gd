extends Spatial

export var current_map = 0
#onready var details_panel = get_node("details_panel")
onready var spawn_nodes = get_node("spawn_nodes")


var start_sending_packet = false

#var server = WebSocketServer.new()
var count = 0

var player_score = {}


func _ready():
	
	Server.world_node = self
	initiate_world()

func _physics_process(delta):
#	$Label.text = str(Engine.get_frames_per_second())
	if(count == 2):
		count = 0
		if(start_sending_packet):
			Server.send_world_state()
	else:
		count += 1
	

func initiate_world():
	var count_players = Server.player_details.keys().size()
	var sp_nodes = 0
	player_score = {}
	for id in Server.player_details:
		var new_player = Server.player_model.instance()
		add_child(new_player)
		Server.player_instances[id] = new_player
		new_player.global_transform.origin = spawn_nodes.get_child(sp_nodes).global_transform.origin
		new_player.id = id
		new_player.add_primary_gun(Server.player_details[id]["primary_gun"])
		new_player.add_secondary_gun(Server.player_details[id]["secondary_gun"])
		sp_nodes += 1
		sp_nodes = sp_nodes % spawn_nodes.get_children().size()
		player_score[id] = {
			"KILLS":0,
			"DEATH":0,
			"SCORE":0,
			"HEADSHOTS":0,
			"SHOTS_FIRED":0,
			"ACCURACY":0.0,
			"HITS":0
		}


		#adding the collision model
		var collision_player = Server.collision_model.instance()
		Server.coll_players[id] = collision_player
		collision_player.main_id = id
		add_child(collision_player)
		collision_player.add_primary_gun(Server.player_details[id]["primary_gun"])
		collision_player.add_secondary_gun(Server.player_details[id]["secondary_gun"])
	
	for id in Server.joined_player_status:
		Server.joined_player_status[id]["ready"] = false
	Server.game_started = true
	Server.broadcast_timer.stop()
	
	
	var player_details_data = {}
	for id in Server.player_details:
		player_details_data[id] = {
			"health":GameData.player_max_health,
			"player_name":Server.player_names[id],
			"player_detail":Server.player_details[id],
			
		}
		pass
#	player_details_data["map_code"] = current_map
	Server.rpc_id(0,"initiate_world",player_details_data,Server.game_time,current_map)
	start_sending_packet = true
	get_node("Timer").wait_time = Server.game_time
	get_node("Timer").start()


func end_game():
	Server.end_game()
	pass

func _on_Timer_timeout():
	end_game()
	


func _on_end_game_button_pressed():
	end_game()

