extends Spatial

export var max_enemy_sound_dis = 35
export var map_id = 0

var ws_buffer = []
var player_buffer = []

onready var spawn_points = $level/spawn_points

func _init():
	pass
	
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Server.world_node = self
	for id in Server.joined_player_data:
		Server.joined_player_data[id]["ready"] = false
	initiate_world(Server.choosen_spawn_points,Server.player_detail_buffer,Server.game_time_buffer)
	
	
	
	

func initiate_world(choosen_spawn_points,player_details,game_time_buffer):  #function for initiating the world after getting information from the host 
	get_node("game_end_screen").visible = false
	print(player_details)
	for id in player_details:
		if(Server.network.get_connection_status() == 2):
			print(id)
			if(int(id) != Server.network.get_unique_id()):
				var new_player = Server.player_model.instance()
				self.add_child(new_player)
				
				print(player_details[id]["player_name"])
		
				new_player.get_node("name_label").text = player_details[id]["player_name"]
				new_player.change_primary_gun(player_details[id]["player_detail"]["primary_gun"])
				new_player.change_secondary_gun(player_details[id]["player_detail"]["secondary_gun"])
				new_player.change_complete_outfit(player_details[id]["player_detail"]["outfit"])
				new_player.global_transform.origin = spawn_points.get_child(choosen_spawn_points[id]).global_transform.origin
				new_player.get_node("body/head").rotation_degrees.x = spawn_points.get_child(choosen_spawn_points[id]).rotation_degrees.x
				new_player.get_node("body").rotation_degrees.y = spawn_points.get_child(choosen_spawn_points[id]).rotation_degrees.y
				new_player.id = int(id)
				Server.player_instances[id] = new_player
			elif(is_instance_valid(Server.player_char)):
				print(player_details)
				Server.player_char.change_primary_gun(player_details[id]["player_detail"]["primary_gun"])
				Server.player_char.change_secondary_gun(player_details[id]["player_detail"]["secondary_gun"])
				Server.player_char.change_complete_outfit(player_details[id]["player_detail"]["outfit"])	
				Server.player_char.global_transform.origin = spawn_points.get_child(choosen_spawn_points[id]).global_transform.origin
				Server.player_char.get_node("body/head").rotation_degrees.x = spawn_points.get_child(choosen_spawn_points[id]).rotation_degrees.x
				Server.player_char.get_node("body").rotation_degrees.y = spawn_points.get_child(choosen_spawn_points[id]).rotation_degrees.y
				Server.player_char.left_leg_rotation = 0
				Server.player_char.right_leg_rotation = 0
		
	for id in player_details:
		Server.set_health(id,player_details[id]["health"])
	
	
	#starting the countdown timer
	$Timer.wait_time = game_time_buffer
	$Timer.start()


func update_game_timer(game_wait_time):
	$Timer.wait_time = game_wait_time
	pass	


func _physics_process(delta):
	if Input.is_action_just_pressed("stop_mouse"): # special line for restricting the movement of mouse after pressing TAB button
		$abhishek.sense = !$abhishek.sense
		$pause_screen.visible = !$pause_screen.visible	

	
	$Label.text = str(Engine.get_frames_per_second())
	$time_label.text = str(int($Timer.time_left))
	
	
	#for the other entities  #### ENTITY INTERPOLATION ALGORITHM
	if(Server.network.get_connection_status() != 2):
		return
	var render_time = OS.get_system_time_msecs() - Server.time_offset - Server.render_offset

	if(Server.network.get_unique_id() == 1):
		render_time = OS.get_system_time_msecs() - Server.render_offset
	while((ws_buffer.size() > 1) and (ws_buffer[1]["T"] < render_time)):
		ws_buffer.pop_front()


	if(ws_buffer.size() > 1): 
		var interpolation_factor = float(render_time - ws_buffer[0]["T"])/float(ws_buffer[1]["T"] - ws_buffer[0]["T"])
		for id in ws_buffer[1]["player_data"]:
			if(Server.network.get_connection_status() == 2):
				if (id == Server.network.get_unique_id()) and (id in ws_buffer[0]["player_data"]):
					pass
				elif (id in ws_buffer[0]["player_data"] and (id in Server.player_instances) and is_instance_valid(Server.player_char)):

					Server.player_instances[id].global_transform.origin = lerp(ws_buffer[0]["player_data"][id]["player_position"],ws_buffer[1]["player_data"][id]["player_position"],interpolation_factor)
					Server.player_instances[id].get_node("body").get_node("head").rotation_degrees.x = lerp(ws_buffer[0]["player_data"][id]["head_rotation"],ws_buffer[1]["player_data"][id]["head_rotation"],interpolation_factor)
					Server.player_instances[id].get_node("body").rotation_degrees.y = lerp(ws_buffer[0]["player_data"][id]["body_rotation"],ws_buffer[1]["player_data"][id]["body_rotation"],interpolation_factor)
					Server.player_instances[id].get_node("body/legs_node/left_leg").rotation_degrees.x = lerp(ws_buffer[0]["player_data"][id]["left_leg_rotation"],ws_buffer[1]["player_data"][id]["left_leg_rotation"],interpolation_factor)
					Server.player_instances[id].get_node("body/legs_node/right_leg").rotation_degrees.x = lerp(ws_buffer[0]["player_data"][id]["right_leg_rotation"],ws_buffer[1]["player_data"][id]["right_leg_rotation"],interpolation_factor)

					var dis = Server.player_instances[id].global_transform.origin.distance_to(Server.player_char.global_transform.origin)
					if(ws_buffer[1]["player_data"][id]["step_sound"] and dis < max_enemy_sound_dis):
						if(Server.player_instances[id].get_node("steps").playing == false):
							Server.player_instances[id].get_node("steps").play()
							print("enemy_sound_play")
					else:
						Server.player_instances[id].get_node("steps").stop()
				
			
