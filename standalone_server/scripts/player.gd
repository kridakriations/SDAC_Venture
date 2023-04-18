extends KinematicBody

export var speed = 20.0
export var max_spread = 0.3
export var spread_increase = 0.02
export var max_speed = 2
export var speed_shooting = 10

export var jump_vel = 15

export var mouse_sensitivity = 1.2 


export var gravity = Vector3(0.0,-40,0.0)
export var max_health = 100

var kill_streak = 0
var rng = RandomNumberGenerator.new()
var is_scoping = false
var curr_state = "HOLD"
var busy_frames = 0
var step_sound_playing = false
var leg_direction_side = 1
var leg_direction = 1
var curr_move_direc = Vector2.ZERO
var prev_move_direc = Vector2.ZERO
var dead = false
var id = null
var gun_no = 0
var in_air = false
var velocity = Vector3.ZERO
var up_velocity = Vector3.ZERO
var health = 0
var max_count = 1
var curr_count = 0
var on_floor = false
var coyote_time_buffer = 0

var send_confirm = 2
var max_leg_rotation = 30
var snap = 5

var left_leg_rotation = 0
var right_leg_rotation = 0
var head_x = 0

var gun_details = [{},{}]
var increase_health = 60

onready var low_foot_ray = $"%low_foot_ray"
onready var high_foot_ray = $"%high_foot_ray"
onready var torso = $"%body" # reference for the body of the player


var input_queue = []

func _ready():
	health = GameData.player_max_health


func shoot():
	return
	gun_details[gun_no]["current_bullet"] -= 1


func damage(damage,shooter_id = -1,shot_type = "SUICIDE",source = global_transform.origin):
	if(health <= 0):
		return
	increase_health = 180
	health = max(0,health - damage)
	Server.rpc_id(id,"set_health",health,id,source)
	if(shot_type != "BOMB"):
		Server.world_node.player_score[shooter_id]["HITS"] += 1
		Server.world_node.player_score[shooter_id]["ACCURACY"] = float(Server.world_node.player_score[shooter_id]["HITS"])/float(Server.world_node.player_score[shooter_id]["SHOTS_FIRED"])
	if(shot_type == "HEADSHOT"):
		Server.world_node.player_score[shooter_id]["HEADSHOTS"] += 1
		pass
#	get_parent().details_panel.get_node("player_list").change_health(id,health)
	if(health <= 0):# code for if the player died
		dead = true
		$Timer.wait_time = GameData.player_respawn_time
		$Timer.start()
		kill_streak = 0
		if(shot_type != "BOMB"):
			Server.player_instances[shooter_id].kill_streak += 1
		if(shooter_id in Server.player_instances):
			Server.world_node.player_score[shooter_id]["KILLS"] += 1
			Server.world_node.player_score[shooter_id]["SCORE"] += 10
#			Server.world_node.details_panel.get_node("score_panel").change_score(shooter_id,Server.world_node.player_score)
		Server.world_node.player_score[id]["DEATH"] += 1
		Server.world_node.player_score[id]["SCORE"] += (-5)
#		Server.world_node.details_panel.get_node("score_panel").change_score(id,Server.world_node.player_score)
		
		
		
		#add the function to handle after death situation over the client 
#		if(shooter_id in Server.player_instances):
#			Server.player_instances[shooter_id].kill_streak = Server.player_instances[shooter_id].kill_streak + 1
#			print(Server.player_instances[shooter_id].kill_streak)
		Server.rpc_id(id,"died",id,Server.world_node.player_score)
		var msg = {
			"TYPE":"DEATH",
			"BODY":{
				"SHOOTER":shooter_id,
				"SHOOTER_NAME":Server.player_names[shooter_id],
				"VICTIM":id,
				"VICTIM_NAME":Server.player_names[id],
				"SHOT_TYPE":shot_type
			},
		}
		Server.rpc_id(0,"recieve_message",msg)
		#end the function here
	
func can_current_gun_shoot():
	if(dead == true):
		return false
	return (can_shoot())

func jump():
	if is_on_floor():
		up_velocity.y = jump_vel
	pass

func _physics_process(delta):
	for i in input_queue:
		process_input1(i)
	input_queue = []
	if(kill_streak >= 3):
		kill_streak = 0
		Server.rpc_id(id,"add_bomb")
		pass
	pass

func process_input1(input):
	if(increase_health == 0):
		increase_health = 90
		if(health < GameData.player_max_health):
			health += 10
			health = min(GameData.player_max_health,health)
			Server.rpc_id(id,"set_health",health,id)
	else:
		increase_health -= 1
	var curr_time = OS.get_system_time_msecs()
	coyote_time_buffer = max(0,coyote_time_buffer-1)
	busy_frames = max(0,busy_frames-1)
	if(busy_frames <= 0):
		curr_state = "HOLD"
	

	if(is_on_floor()):
		velocity = Vector3.ZERO
	else:
		velocity += (gravity * 0.016667)
	torso.rotation_degrees.y -= input["mouse_motion_x"]
	head_x = clamp(head_x + input["mouse_motion_y"],-70,70)

	var forward_dir = torso.to_global(Vector3(0,0,2)) - torso.to_global(Vector3(0,0,0))
	var left_dir = torso.to_global(Vector3(2,0,0)) - torso.to_global(Vector3(0,0,0))
	
	#movement code ===========================================================
	velocity.x = 0
	velocity.z = 0
	
	forward_dir = forward_dir.normalized() #normalizing the forward direction vector
	left_dir = left_dir.normalized()
	var add_velocity = Vector3.ZERO
	
	curr_move_direc = Vector2.ZERO
	if input["ui_up"]:
		add_velocity += forward_dir
		curr_move_direc.x += 1
	if input["ui_down"]:
		add_velocity -= forward_dir
		curr_move_direc.x -= 1
	if input["ui_left"]:
		add_velocity += left_dir
		curr_move_direc.y += 1
	if input["ui_right"]:
		add_velocity -= left_dir
		curr_move_direc.y -= 1
	if ((input["ui_select"]==true or coyote_time_buffer > 0) and is_on_floor()):
		velocity.y = jump_vel
		coyote_time_buffer = 0
	if((input["ui_select"] == true)  and (is_on_floor() == false)):
		coyote_time_buffer = 10
		
#	if (input["grenade"]["is_throw"] == true):
##		var new_bomb = Gamedata.bomb_model.instance()
#		var new_bomb = GameData.bomb_model.instance()
#		Server.world_node.add_child(new_bomb)
#		new_bomb.global_transform.origin = input["grenade"]["source"]
#		var direction = input["grenade"]["target"] - input["grenade"]["source"]
#		direction = direction.normalized()
##		new_bomb.direction = direction
#		new_bomb.set_speed(direction)
	
	if (input["shoot"]["is_shot"] == false):
		gun_details[gun_no]["curr_spread"] = 0
		gun_details[gun_no]["curr_spread"] = 0

	if (input["shoot"]["is_shot"] == true and busy_frames <= 0):
		if(can_current_gun_shoot()):
			curr_state = "SHOOT"
			busy_frames += gun_details[gun_no]["fire_frame"] 
			gun_details[gun_no]["current_bullet"] -= 1
#			gun_node.get_child(gun_no).curr_spread += 0.3
			gun_details[gun_no]["curr_spread"] += 0.3
#			gun_node.get_child(gun_no).curr_spread = min(gun_node.get_child(gun_no).curr_spread,gun_node.get_child(gun_no).max_spread)
			gun_details[gun_no]["curr_spread"] = min(gun_details[gun_no]["curr_spread"],gun_details[gun_no]["max_spread"])
			rng.randf_range(-1,1)
			var recoil = gun_details[gun_no]["recoil"] 
			head_x = clamp(head_x - recoil,-70,70)
			if(input["shoot"]["target"] != null):
				Server.rpc_unreliable_id(0,"enemy_gun_shot",id,input["shoot"]["target"])
			Server.world_node.player_score[id]["SHOTS_FIRED"]+=1
			if(input["shoot"]["to_verify"] == true):	
				if((input["shoot"]["source"] != null) and (input["shoot"]["target"] != null)):
					Server.gun_shot(input["shoot"]["time_stamp"],input["shoot"]["source"],input["shoot"]["target"],id)
		else:
			curr_state = "SHOOT"
			busy_frames += GameData.wait_frame_without_bullet
	if(input["reload"] and (busy_frames <= 0 or curr_state == "SHOOT")):
		curr_state = "RELOAD"
		busy_frames = gun_details[gun_no]["reload_frame"]

		reload()
	
	if(input["swap"] and busy_frames <= 0):
		curr_state = "SWAP"
		busy_frames += gun_details[gun_no]["appear_frame"]#gun_node.get_child((gun_no+1)%2).appear_frame
		swap()
	
	if(input["scope"] == true):
		if(is_scoping == false and busy_frames <= 0):
			is_scoping = true
			curr_state = "SCOPING"
			busy_frames += gun_details[gun_no]["scope_frame"]#gun_node.get_child(0).scope_frame

				
	if(input["scope"] == false):
		if(is_scoping == true):
			if(busy_frames <= 0):
				busy_frames += gun_details[gun_no]["scope_frame"]#gun_node.get_child(0).scope_frame
				curr_state = "UNSCOPING"
			is_scoping = false

	add_velocity = add_velocity.normalized()

	low_foot_ray.force_raycast_update()
	high_foot_ray.force_raycast_update()
	if((high_foot_ray.is_colliding() == false) and (low_foot_ray.is_colliding() == true) and (is_on_floor() == true) and (input["ui_up"] == true)):
		add_velocity = (Vector3.UP * 15) + (add_velocity*0.75)
		pass

	velocity += add_velocity
	if(curr_state != "SHOOT" and is_scoping == false):
		velocity.x = velocity.x * speed
		velocity.z = velocity.z * speed
	else:
		velocity.x = velocity.x * speed_shooting
		velocity.z = velocity.z * speed_shooting

	move_and_slide(velocity,Vector3.UP,true,3)
	
	if (add_velocity != Vector3.ZERO and is_on_floor()):
		left_leg_rotation += snap
		right_leg_rotation -= snap
		if(abs(left_leg_rotation) >= max_leg_rotation):
			snap = snap * -1

						
		step_sound_playing = true
	else:
		step_sound_playing = false
	
	
	# code for updating the state over the network
	
	send_confirm -= 1
	if(send_confirm <= 0):
		send_confirm = 2
		var temp_data = {}
		temp_data["player_data"] = {
			"torso_degree":self.torso.rotation_degrees.y,
			"head_degree":head_x,#self.head.rotation_degrees.x,
			"player_position":self.global_transform.origin,
			"left_leg_degrees":right_leg_rotation,
			"right_leg_degrees":left_leg_rotation,
			"up_velocity":self.up_velocity,
			"velocity":self.velocity,
			"on_floor":is_on_floor(),
			"primary_gun_bullet":gun_details[0]["current_bullet"],#gun_node.get_child(0).current_bullet,
			"secondary_gun_bullet":gun_details[1]["current_bullet"],#gun_node.get_child(1).current_bullet,
			"gun_no":gun_no,
			"busy_frames":busy_frames,
			"curr_state":curr_state,
			"is_scoping":is_scoping,
			"rng_state":rng.state,
			"primary_gun_spread":gun_details[0]["curr_spread"],
			"secondary_gun_spread":gun_details[1]["curr_spread"],
			"coyote_time_buffer":coyote_time_buffer
		}
		temp_data["T"] = input["T"]
		temp_data["F"] = input["F"]
#		temp_data["AT"] = curr_time
#		temp_data["F"] = input["F"]
		
		Server.rpc_unreliable_id(id,"update_player",temp_data)



func reload():
	gun_details[gun_no]["current_bullet"] = gun_details[gun_no]["max_bullet"]
	pass

func swap():
	gun_no = (gun_no + 1)%2
	Server.rpc_id(0,"swap_gun_dummy",id)
	pass
	
func gun_damage():
	return gun_details[gun_no]["damage"]

func gun_head_damage():
	return gun_details[gun_no]["head_damage"] 

func add_primary_gun(gun_code):
	var gun_type = GameData.primary_gun_types[gun_code]
	gun_details[0]["max_bullet"] = GameData.gun_stats[gun_type]["max_bullet"]
	gun_details[0]["fire_frame"]= GameData.gun_stats[gun_type]["fire_frame"]
	gun_details[0]["reload_frame"] = GameData.gun_stats[gun_type]["reload_frame"]
	gun_details[0]["damage"] = GameData.gun_stats[gun_type]["damage"]
	gun_details[0]["head_damage"] = GameData.gun_stats[gun_type]["head_damage"]
	gun_details[0]["recoil"] = GameData.gun_stats[gun_type]["recoil"]
	gun_details[0]["scope_frame"] = GameData.gun_stats[gun_type]["scope_frame"]
	gun_details[0]["appear_frame"] = GameData.appear_frame
	gun_details[0]["current_bullet"] = gun_details[0]["max_bullet"]
	gun_details[0]["curr_spread"] = 0
	gun_details[0]["max_spread"] = GameData.gun_stats[gun_type]["max_spread"]
	pass


func add_secondary_gun(gun_code):
	var gun_type = GameData.secondary_gun_types[gun_code]
	gun_details[1]["max_bullet"] = GameData.gun_stats[gun_type]["max_bullet"]
	gun_details[1]["fire_frame"]= GameData.gun_stats[gun_type]["fire_frame"]
	gun_details[1]["reload_frame"] = GameData.gun_stats[gun_type]["reload_frame"]
	gun_details[1]["damage"] = GameData.gun_stats[gun_type]["damage"]
	gun_details[1]["head_damage"] = GameData.gun_stats[gun_type]["head_damage"]
	gun_details[1]["recoil"] = GameData.gun_stats[gun_type]["recoil"]
	gun_details[1]["scope_frame"] = GameData.gun_stats[gun_type]["scope_frame"]
	gun_details[1]["appear_frame"] = GameData.appear_frame
	gun_details[1]["current_bullet"] = gun_details[1]["max_bullet"]
	gun_details[1]["curr_spread"] = 0
	gun_details[1]["max_spread"] = GameData.gun_stats[gun_type]["max_spread"]
	pass

	


func can_shoot():
	if(gun_details[gun_no]["current_bullet"] > 0):
		return true
	return false



func _on_Timer_timeout():
	dead = false
	health = GameData.player_max_health
	Server.respawn_player(id)
	
func full_magazine():
	gun_details[1]["current_bullet"] = gun_details[1]["max_bullet"]
	gun_details[0]["current_bullet"] = gun_details[0]["max_bullet"]

