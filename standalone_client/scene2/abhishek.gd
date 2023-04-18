extends KinematicBody

# player script ================================================
export var mouse_sensitivity = 1.2 

export var gravity = Vector3(0.0,-40.0,0.0)
#export var gravity = Vector3(0.0,-10,0.0)
export var max_health = 100
export var max_leg_rotation = 30
export var leg_rotation_snap = 6

#debug values
export var speed = 20.0
#export var speed = 0.7
export var max_speed = 2
export var speed_shooting = 10
export var jump_vel = 15

export var max_spread = 0.3


export var spread_increase = 0.02
export var normal_scope = 90

#variables which are reassured using the server during reconcilation
var died = false
var busy_frames = 0
var current_spread = 0
var current_angle = 0
var velocity = Vector3.ZERO
var up_velocity = Vector3.ZERO
var on_floor = false
var is_scoping = false
var obstacle_jump_factor = 0.4
var is_on_floor_on_server = false
var coyote_time_buffer = 0


var max_sway = 5
var sway_lerp_factor = 0.1
var sway_recovery_factor = 0.5
var leg_direction_side = 1
var leg_direction = 1
var curr_move_direc = Vector2.ZERO
var prev_move_direc = Vector2.ZERO
var in_air = false
var player_status = false
var health = 0
var gun_no = 0
var sense = true
var rng = RandomNumberGenerator.new()
var dead = false
var input_buffer = []
var state_buffer = []
var input_cache = []
var state_cache = []
var recon_state = null
var floor_contact = 0
var bomb = 10
var frame_number = 0
var cache_size = 100
onready var damage_indicator_scene = preload("res://scenes/damage_indicator.tscn")
onready var damage_indicator = preload("res://scenes/get_shot_indicator.tscn")
onready var headshot_notification = preload("res://scenes/head_shot_notification.tscn")

onready var gun_data_viewer = $ColorRect/gun_tab
onready var low_foot_ray = $"%low_foot_ray"
onready var high_foot_ray = $"%high_foot_ray"

onready var front_head = $"%head_front"
onready var front_ray = $"%front_ray"
onready var clipping_ray = $"%clipping_ray"
onready var gun_node = $"%gun_node"
onready var torso = $"%body" # reference for the body of the player
onready var head = $"%head" # refrence for the head of the player


var min_upper_leg_rotation = -90
var max_upper_leg_rotation = 0

var min_lower_leg_rotation = 90
var max_lower_leg_rotation = 0

var prev_input_process_time = -1
var mouse_motion_x = 0
var mouse_motion_y = 0
var ui_up = false
var ui_left = false
var ui_right = false
var ui_down = false
var functional = false
var ui_select = false
var last_corrected_frame = null
var curr_state = "HOLD"
var input_frame_no = 0

var input_packet = {
	"T":0,
	"mouse_motion_x":0,
	"mouse_motion_y":0,
	"ui_up":false,
	"ui_down":false,
	"ui_left":false,
	"ui_right":false,
	"ui_select":false,
	"shoot":{"is_shot":false,
		"target":null,
		"source":null,
		"time_stamp":null,
		"to_verify":false,
	},
	"reload":false,
	"swap":false,
	"scope":false,
	"grenade":{"is_throw":false,
		"target":null,
		"source":null,
		
	},
	}
	
func clear_input():
	input_packet["T"] = 0
	input_packet["mouse_motion_x"] = 0
	input_packet["mouse_motion_y"] = 0
	input_packet["ui_up"] = false
	input_packet["ui_down"] = false
	input_packet["ui_left"] = false
	input_packet["ui_right"] = false
	input_packet["ui_select"] = false
	input_packet["shoot"]["is_shot"] = false
	input_packet["shoot"]["target"] = null
	input_packet["shoot"]["source"] = null
	input_packet["shoot"]["to_verify"] = false
	input_packet["reload"] = false
	input_packet["swap"] = false
	input_packet["scope"] = false
	input_packet["grenade"]["is_throw"] = false
	input_packet["grenade"]["target"] = null
	input_packet["grenade"]["source"] = null
	pass
	
func _ready():
	input_cache.resize(cache_size)
	state_cache.resize(cache_size)
	$death_screen.visible = false
	gun_node.get_child(gun_no+1).visible = false
	health = max_health
	Server.player_char = self
	Server.rpc_id(1,"get_health")
	$ColorRect/user_name.text = Server.player_name
	update_gun_info(1)
	update_gun_info(0)
	show_gun_info(0)
	$ColorRect/grenade_count.text = str(bomb)
	
# function for handling the movement of the camera based on the mouse movement
func _input(event):
	if sense == true:
		if event is InputEventMouseMotion:
			input_packet["mouse_motion_x"] += event.relative.x * Gamedata.senstivity_value / 10
			input_packet["mouse_motion_y"] += event.relative.y * Gamedata.senstivity_value / 10
			
			
func update_player(new_state):
	while ((input_buffer.size()  > 0) and input_buffer[0]["T"] <= new_state["T"]):
		input_buffer.pop_front()
		pass
	global_transform.origin = new_state["player_data"]["player_position"]
	head.rotation_degrees.x = new_state["player_data"]["head_degree"]
	torso.rotation_degrees.y = new_state["player_data"]["torso_degree"]
	velocity = new_state["player_data"]["velocity"]
	up_velocity = new_state["player_data"]["up_velocity"]
	for inputs in input_buffer:
		process_input(inputs["user_input"])
	pass
	
func set_health(new_value):
	$ColorRect/health_bar.value = new_value
	$ColorRect/health.text = str(new_value)
	pass

#process function
func _process(delta):
	pass

func swap():
	gun_node.get_child(gun_no).get_node("AnimationPlayer").play("disappear")
	gun_node.get_child((gun_no+1)%2).get_node("AnimationPlayer").play("appear")
	gun_no = (gun_no + 1)%2
	show_gun_info(gun_no)

func process_input(input,reconcilating = true):
	coyote_time_buffer = max(0,coyote_time_buffer - 1)
	busy_frames = max(0,busy_frames-1)
	if(busy_frames <= 0):
		curr_state = "HOLD"
		if(is_scoping == true and gun_node.get_child(gun_no).is_scoping == false):
			$pointer_sprite.visible = false
			gun_node.get_child(gun_no).fast_scope()
			get_node("body/head/Camera").fov = gun_node.get_child(gun_no).scope_value
		if(is_scoping == false and gun_node.get_child(gun_no).is_scoping == true):
			$pointer_sprite.visible = true
			gun_node.get_child(gun_no).fast_unscope()
			get_node("body/head/Camera").fov = normal_scope

	if(on_floor):
		velocity = Vector3.ZERO
	else:
		velocity += (gravity * 0.016667)
	
	

	torso.rotation_degrees.y -= input["mouse_motion_x"]
	head.rotation_degrees.x = clamp(head.rotation_degrees.x + input["mouse_motion_y"],-90,90)
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
	if ((input["ui_select"]==true or coyote_time_buffer > 0) and on_floor) :# (is_on_floor_on_server or is_on_floor())):
		if(reconcilating == false):
			$jump_sound.play()
		velocity.y = jump_vel
		coyote_time_buffer = 0
	if (input["ui_select"] == true and (on_floor == false)):
		coyote_time_buffer = 10
#	print((input["grenade"]["is_throw"] == true)," ",(bomb>0)," ",(reconcilating == false)," ",(died == false))
	if ((input["grenade"]["is_throw"] == true) and (bomb>0) and (reconcilating == false) and (died == false)):
#		print("grenade")
		bomb = max(0,bomb-1)
		var new_bomb = Gamedata.bomb_model.instance()
		get_parent().add_child(new_bomb)
		new_bomb.global_transform.origin = input["grenade"]["source"]
		var direction = input["grenade"]["target"] - input["grenade"]["source"]
		direction = direction.normalized()
		new_bomb.set_speed(direction)
		$ColorRect/grenade_count.text = str(bomb)
		Server.rpc_id(0,"bomb_thrown",Server.network.get_unique_id(),input["grenade"])
	
	if (input["shoot"]["is_shot"] == false):
		gun_node.get_child(0).curr_spread = 0
		gun_node.get_child(1).curr_spread = 0
				
	if (input["shoot"]["is_shot"] == true and busy_frames <= 0):
		if(reconcilating == true):
			if(gun_node.get_child(gun_no).can_shoot()):
				curr_state = "SHOOT"
				busy_frames += gun_node.get_child(gun_no).fire_frame
				gun_node.get_child(gun_no).curr_bullet -= 1
				update_gun_info(gun_no)
				rng.randf_range(-1,1)
				gun_node.get_child(gun_no).curr_spread += 0.3
				gun_node.get_child(gun_no).curr_spread = min(gun_node.get_child(gun_no).curr_spread,gun_node.get_child(gun_no).max_spread)
				var recoil = gun_node.get_child(gun_no).recoil
				head.rotation_degrees.x = clamp(head.rotation_degrees.x - recoil,-70,70)
		else:
			if (gun_node.get_child(gun_no).can_shoot() and busy_frames <= 0):
				gun_node.rotation_degrees = Vector3(0,0,0)
				if(get_node("body/head/animation").current_animation == "camera_bobbing"):
					get_node("body/head/animation").stop()
				var errx = gun_node.get_child(gun_no).curr_spread * rng.randf_range(-1,1)
				var erry = 0
				var err_pos = Vector3.ZERO + Vector3(errx,erry,0)
				gun_node.get_child(gun_no).curr_spread += 0.3
				gun_node.get_child(gun_no).curr_spread = min(gun_node.get_child(gun_no).curr_spread,gun_node.get_child(gun_no).max_spread)
				input["shoot"]["target"] = front_head.to_global(err_pos)
				input["shoot"]["source"] = front_ray.global_transform.origin
				if(is_instance_valid(Server.world_node)):
					var space_state = Server.world_node.get_world().direct_space_state
					var col_dict = space_state.intersect_ray(input["shoot"]["source"],input["shoot"]["target"],[],5,true,true)
					if(col_dict.empty() == false):
						if(col_dict.collider.is_in_group("enemy")):
							input["shoot"]["to_verify"] = true
						var decalpt = col_dict.position
						var decalnormal = col_dict.normal
						var new_decal = Gamedata.decal.instance()
						Server.world_node.add_child(new_decal)
						new_decal.global_transform.origin = decalpt
						var collision_normal = decalnormal
						var new_vec = decalnormal + Vector3(0,0.1,0)
						if(new_decal.global_transform.origin != new_vec.cross(decalpt + decalnormal)):
							new_decal.look_at(decalpt + decalnormal,new_vec.cross(decalpt + decalnormal))
					curr_state = "SHOOT"
					busy_frames += gun_node.get_child(gun_no).fire_frame
					var recoil = gun_node.get_child(gun_no).recoil
					head.rotation_degrees.x = clamp(head.rotation_degrees.x - recoil,-70,70)
					if(get_node("body/head/animation").is_playing() == false):
						if(gun_node.get_child(gun_no).gun_type == "sniper"):
							get_node("body/head/animation").play("sniper_recoil")
						else:
							get_node("body/head/animation").play("recoil")
					gun_node.get_child(gun_no).shoot(input["shoot"]["target"],is_scoping)
					
					update_gun_info(gun_no)
			elif ((gun_node.get_child(gun_no).can_shoot() == false) and busy_frames <= 0):
				curr_state = "SHOOT"
				busy_frames += Gamedata.wait_frame_without_bullet
				var temp_sound = Gamedata.empty_clip_sound.instance()
				add_child(temp_sound)
				temp_sound.transform.origin = Vector3(0,0,0)
				$ColorRect/damage_animation.play("show_reload")
	if(input["reload"] and (busy_frames <= 0 or curr_state == "SHOOT")):
		busy_frames = gun_node.get_child(gun_no).reload_frame
		curr_state = "RELOAD"
		if(reconcilating == true):
			gun_node.get_child(gun_no).fast_unscope()  # for fast unscoping before reload
			get_node("body/head/Camera").fov = normal_scope
			gun_node.get_child(gun_no).curr_bullet = gun_node.get_child(gun_no).max_bullet
			
		else:
			if(gun_node.get_child(gun_no).curr_bullet == 0):
				$ColorRect/damage_animation.play("hide_reload")
			gun_node.get_child(gun_no).fast_unscope()  # for fast unscoping before reload
			get_node("body/head/Camera").fov = normal_scope
			gun_node.get_child(gun_no).reload()
		update_gun_info(gun_no)
	if(input["swap"] and busy_frames <= 0):
		curr_state = "SWAP"
		busy_frames += gun_node.get_child((gun_no+1)%2).appear_frame
		if(reconcilating == true):
			gun_node.get_child(gun_no).fast_unscope() #fast unscoping before swap
			get_node("body/head/Camera").fov = normal_scope
			if(gun_node.get_child(gun_no).get_node("AnimationPlayer").current_animation != "disappear"):
				gun_node.get_child(gun_no).visible = false
			gun_no = (gun_no + 1)%2
			if(gun_node.get_child(gun_no).get_node("AnimationPlayer").current_animation != "appear"):
				gun_node.get_child(gun_no).visible = true	
			show_gun_info(gun_no)
		else:
			get_node("ColorRect/damage_animation").play("hide_reload")
			gun_node.get_child(gun_no).fast_unscope()
			get_node("body/head/Camera").fov = normal_scope
			swap()
			
	if(input["scope"] == true):
		if(reconcilating == false):
			if(is_scoping == false and busy_frames <= 0):
				gun_node.rotation_degrees = Vector3(0,0,0)
				is_scoping = true
				curr_state = "SCOPING"
				$pointer_sprite.visible = false
				busy_frames += gun_node.get_child(0).scope_frame
				gun_node.get_child(gun_no).scope()
				if(gun_node.get_child(gun_no).gun_type == "sniper"):
					get_node("body/head/animation").play("sniper_scope")
				else:
					get_node("body/head/animation").play("gun_scope")
		else:
			if(is_scoping == false and busy_frames <= 0):
				is_scoping = true
				$pointer_sprite.visible = false
				curr_state = "SCOPING"
				busy_frames += gun_node.get_child(0).scope_frame
				if(gun_node.get_child(gun_no).get_node("AnimationPlayer").current_animation != "scope"):
					gun_node.get_child(gun_no).fast_scope()
					get_node("body/head/Camera").fov = gun_node.get_child(gun_no).scope_value
				
	if(input["scope"] == false):
		if(reconcilating == false):
			if(is_scoping == true):
				gun_node.rotation_degrees = Vector3(0,0,0)
				if(busy_frames <= 0):
					$pointer_sprite.visible = true
					gun_node.get_child(gun_no).unscope()
					if(gun_node.get_child(gun_no).gun_type == "sniper"):
						get_node("body/head/animation").play("sniper_unscope")
					else:
						get_node("body/head/animation").play("gun_unscope")
					busy_frames += gun_node.get_child(0).scope_frame
					curr_state = "UNSCOPING"
				is_scoping = false
		else:
			if(is_scoping == true):
				if(busy_frames <= 0):
					$pointer_sprite.visible = true
					busy_frames += gun_node.get_child(0).scope_frame
					curr_state = "UNSCOPING"
					if(gun_node.get_child(gun_no).get_node("AnimationPlayer").current_animation != "unscope"):
						gun_node.get_child(gun_no).fast_unscope()
						get_node("body/head/Camera").fov = gun_node.get_child(gun_no).scope_value
				is_scoping = false
			
	add_velocity = add_velocity.normalized()
	
	if(add_velocity != Vector3.ZERO and on_floor  and $steps.playing == false):
		$steps.play()
#		if(curr_state != "SHOOT"):
#			get_node("body/head/animation").play("camera_bobbing")


	if(is_instance_valid(Server.world_node)):
		var space_state = Server.world_node.get_world().direct_space_state
		var low_ray_dict = space_state.intersect_ray(low_foot_ray.global_transform.origin,low_foot_ray.to_global(Vector3(0,0,1.5)),[],4)
		var high_ray_dict = space_state.intersect_ray(high_foot_ray.global_transform.origin,high_foot_ray.to_global(Vector3(0,0,1.5)),[],4)
		$low_ray.text = "low foot ray " + str(low_ray_dict.empty() == false)
		$high_ray.text = "high foot ray " + str(high_ray_dict.empty() == false)
		$on_floor.text = "onfloor " + str(on_floor)
		if(high_ray_dict.empty() and low_ray_dict.empty() == false and on_floor and input["ui_up"] == true):
			add_velocity = (Vector3.UP * 15) + (add_velocity*0.75)
		
		var cliping_dict = space_state.intersect_ray(clipping_ray.global_transform.origin,clipping_ray.to_global(Vector3(0,0,2.3)),[],4)
		if(cliping_dict.empty() == false):
			var position = cliping_dict.position
			var dis_to_wall = position.distance_to(clipping_ray.global_transform.origin)
			var lerp_factor = float(dis_to_wall)/1.73
			gun_node.rotation.x = lerp_angle(deg2rad(90),deg2rad(0),lerp_factor)
		else:
			gun_node.rotation.x = lerp_angle(gun_node.rotation.x,deg2rad(0),0.5)
	
	velocity += add_velocity
	if(curr_state != "SHOOT" and is_scoping == false):
		velocity.x = velocity.x * speed
		velocity.z = velocity.z * speed
		get_node("body/head/animation").play("camera_bobbing")
	else:
		velocity.x = velocity.x * speed_shooting
		velocity.z = velocity.z * speed_shooting
		if(get_node("body/head/animation").current_animation == "camera_bobbing"):
			get_node("body/head/animation").stop()
	if(add_velocity == Vector3.ZERO):
		if(get_node("body/head/animation").current_animation == "camera_bobbing"):
			get_node("body/head/animation").stop()
	if(add_velocity != Vector3.ZERO and curr_state == "HOLD" and is_scoping == false):
		gun_node.rotation_degrees.x = lerp(gun_node.rotation_degrees.x,30,0.2)
		gun_node.rotation_degrees.y = lerp(gun_node.rotation_degrees.y,20,0.2)
	elif(input["mouse_motion_x"] != 0 and is_scoping == false and curr_state != "SHOT"):
		if(input["mouse_motion_x"] < 0):
			var goal_sway = max_sway * -1
			gun_node.rotation_degrees.y = lerp(gun_node.rotation_degrees.y,(goal_sway),sway_lerp_factor)
		if(input["mouse_motion_x"] > 0 and is_scoping == false):
			var goal_sway = max_sway
			gun_node.rotation_degrees.y = lerp(gun_node.rotation_degrees.y,(goal_sway),sway_lerp_factor)
	else:
		gun_node.rotation_degrees.y = lerp(gun_node.rotation_degrees.y,(0),sway_lerp_factor)	
		gun_node.rotation_degrees.x = lerp(gun_node.rotation_degrees.x,(0),sway_lerp_factor)	

	var temp_vel = move_and_slide(velocity,Vector3.UP,true,3)
	if((curr_state == "HOLD")and is_scoping == false and (temp_vel.y == 0)):
			if(temp_vel != Vector3.ZERO):
				gun_node.get_child(gun_no).get_node("AnimationPlayer").play("moving")
			else:
				gun_node.get_child(gun_no).get_node("AnimationPlayer").play("idle")
	else:
		var curr_gun_anim = gun_node.get_child(gun_no).get_node("AnimationPlayer").current_animation
		if(curr_gun_anim == "idle" or curr_gun_anim == "moving"):
			gun_node.get_child(gun_no).get_node("AnimationPlayer").stop()
	
	on_floor = is_on_floor()
	var sim_state = {
		"player_position":global_transform.origin,
		"head_degree":head.rotation_degrees.x,
		"torso_degree":torso.rotation_degrees.y,
		"velocity":velocity,
		"up_velocity":up_velocity,
		"on_floor":(on_floor),
		"primary_gun_bullet":gun_node.get_child(0).curr_bullet,
		"secondary_gun_bullet":gun_node.get_child(1).curr_bullet,
		"gun_no":gun_no,
		"busy_frames":busy_frames,
		"is_scoping":is_scoping,
		"curr_state":curr_state,
		"rng_state":rng.state,
		"primary_gun_spread":gun_node.get_child(0).curr_spread,
		"secondary_gun_spread":gun_node.get_child(1).curr_spread,
		"coyote_time_buffer":coyote_time_buffer
	}
	return sim_state


func _physics_process(delta):
	#collecting input
	if(sense == true):
		if Input.is_action_pressed("ui_up"):
			input_packet["ui_up"] = true
		if Input.is_action_pressed("ui_down"):
			input_packet["ui_down"] = true
		if Input.is_action_pressed("ui_left"):
			input_packet["ui_left"] = true
		if Input.is_action_pressed("ui_right"):
			input_packet['ui_right'] = true
		if Input.is_action_just_pressed("ui_select"):
			input_packet["ui_select"] = true
		if Input.is_action_pressed("shoot"):
			input_packet["shoot"]["is_shot"] = true
			input_packet["shoot"]["time_stamp"] = OS.get_system_time_msecs() - Server.time_offset - Server.render_offset
		if Input.is_action_just_pressed("reload"):
			input_packet["reload"] = true
		if Input.is_action_just_pressed("swap"):
			input_packet["swap"] = true
		if Input.is_action_pressed("scope"):
			input_packet["scope"] = true
		if Input.is_action_just_pressed("grenade"):
			input_packet["grenade"]["is_throw"] = true
			input_packet["grenade"]["target"] = front_head.global_transform.origin
			input_packet["grenade"]["source"] = head.global_transform.origin
	
	
	var sim_state = process_input(input_packet,false)#proccesing the input
	
	var packet_formation_time = OS.get_system_time_msecs() - Server.time_offset
	input_buffer.append({"T":packet_formation_time,"user_input":input_packet,"F":input_frame_no})
	state_buffer.append(sim_state)
	input_packet["T"] = packet_formation_time
	input_packet["F"] = input_frame_no
	input_frame_no += 1
	Server.send_input(input_packet) #sending the input to buffer
	recon()
	clear_input()
	
	
func recon():
	if((recon_state == null) or ((last_corrected_frame != null ) and (recon_state["F"] <= last_corrected_frame["F"]))):
		return
	last_corrected_frame = recon_state
	
	while ((input_buffer.size()  > 0) and (input_buffer[0]["F"] < last_corrected_frame["F"])):
		input_buffer.pop_front()
		state_buffer.pop_front()
	var is_diff = check_diff(state_buffer[0],recon_state)
	if(is_diff):
		# forcing the incoming state from the server on player character
		global_transform.origin = last_corrected_frame["player_data"]["player_position"]
		head.rotation_degrees.x = last_corrected_frame["player_data"]["head_degree"]
		torso.rotation_degrees.y = last_corrected_frame["player_data"]["torso_degree"]
		velocity = last_corrected_frame["player_data"]["velocity"]
		up_velocity = last_corrected_frame["player_data"]["up_velocity"]
		on_floor = last_corrected_frame["player_data"]["on_floor"]
		gun_node.get_child(0).curr_bullet = last_corrected_frame["player_data"]["primary_gun_bullet"]
		gun_node.get_child(1).curr_bullet = last_corrected_frame["player_data"]["secondary_gun_bullet"]
		update_gun_info(0)
		update_gun_info(1)
		gun_no = last_corrected_frame["player_data"]["gun_no"]
		busy_frames = last_corrected_frame["player_data"]["busy_frames"]
		is_scoping = last_corrected_frame["player_data"]["is_scoping"]
		curr_state = last_corrected_frame["player_data"]["curr_state"]
		gun_node.get_child(0).curr_spread = last_corrected_frame["player_data"]["primary_gun_spread"]
		gun_node.get_child(1).curr_spread = last_corrected_frame["player_data"]["secondary_gun_spread"]
		rng.state = last_corrected_frame["player_data"]["rng_state"]
		coyote_time_buffer = last_corrected_frame["player_data"]["coyote_time_buffer"]
		for i in range(1,input_buffer.size()):
			var sim_state = process_input(input_buffer[i]["user_input"],true)
			state_buffer[i] = sim_state
	if(input_buffer.size() > 0):
		input_buffer.pop_front()
		state_buffer.pop_front()
	
	recon_state = null
	
func check_diff(client_state,server_state):
	var buff = 0.5
	var rotation_buff = 2
	if(client_state["player_position"].distance_to(server_state["player_data"]["player_position"]) > buff):
		print(client_state["player_position"]," ",server_state["player_data"]["player_position"])
		print("position")
		return true
	if(client_state["velocity"].distance_to(server_state["player_data"]["velocity"]) > (buff*1.5)):
		print("vel")
		print(client_state["velocity"]," ",server_state["player_data"]["velocity"])
		return true
	if(client_state["up_velocity"] != server_state["player_data"]["up_velocity"]):
		print("up_velocity")
		return true
	if(client_state["on_floor"] != server_state["player_data"]["on_floor"]):
		print("on_Floor")
		print(server_state["F"])
		print(client_state["on_floor"]," ",server_state["player_data"]["on_floor"])
		return true
	if(client_state["primary_gun_bullet"] != server_state["player_data"]["primary_gun_bullet"]):
		print("primary gun bullet")
		print(client_state["primary_gun_bullet"]," ",server_state["player_data"]["primary_gun_bullet"])
		return true
	if(client_state["secondary_gun_bullet"] != server_state["player_data"]["secondary_gun_bullet"]):
		print("sec gun bullet")
		return true
	if(client_state["gun_no"] != server_state["player_data"]["gun_no"]):
		print("gun_no")
		return true
	if(client_state["busy_frames"] != server_state["player_data"]["busy_frames"]):
#		print()
		print(server_state["F"]," ",client_state["busy_frames"]," ",server_state["player_data"]["busy_frames"]," #######################################################################")
#		print("busy_frame")
		return true
	if(client_state["is_scoping"] != server_state["player_data"]["is_scoping"]):
		print("scoping error")
		return true
	if(client_state["curr_state"] != server_state["player_data"]["curr_state"]):
		print("curr_Stte_error")
		return true
	if(client_state["rng_state"] != server_state["player_data"]["rng_state"]):
		print("rng_state_error")
		return true
	if(client_state["primary_gun_spread"] != server_state["player_data"]["primary_gun_spread"]):
		print("primary_gun_spread_error")
		return true
#	print(client_state["primary_gun_spread"]," ",server_state["player_data"]["primary_gun_spread"])
	if(client_state["secondary_gun_spread"] != server_state["player_data"]["secondary_gun_spread"]):
		print("secondary_gun_spread")
		return true
	if(client_state["coyote_time_buffer"] != server_state["player_data"]["coyote_time_buffer"]):
		print("coyote_time_buffer")
		return true
	return false

func change_complete_outfit(outfit_code):
	gun_node.get_child(gun_no).change_outfit(outfit_code)
	gun_node.get_child((gun_no+1)%2).change_outfit(outfit_code)
	return
	

func change_secondary_gun(gun_code):
	gun_node.get_child(1).free()
	var new_gun_model = load(Gamedata.secondary_guns[gun_code])
	var new_gun = new_gun_model.instance()
	gun_node.add_child(new_gun)
	if(gun_no == 0):
		new_gun.visible = false
	pass

func change_primary_gun(gun_code):
	gun_node.get_child(0).free()
	var new_gun_model = load(Gamedata.primary_guns[gun_code])
	var new_gun = new_gun_model.instance()
	gun_node.add_child(new_gun)
	gun_node.move_child(new_gun,0)
	if(gun_no == 1):
		new_gun.visible = false
	pass

func show_gun(new_gun_no):
	if(gun_no == new_gun_no):
		return
	gun_node.get_child(gun_no).visible = false
	gun_node.get_child(new_gun_no).visible = true
	gun_no = new_gun_no

func _on_foot_area_body_entered(body):
	if(body == self):
		return
	floor_contact += 1

func _on_foot_area_body_exited(body):
	if(body == self):
		return
	floor_contact -= 1

func update_gun_info(gun_index):
	gun_data_viewer.get_child(gun_index).get_node("ammo").text = str(gun_node.get_child(gun_index).curr_bullet)
	gun_data_viewer.get_child(gun_index).get_node("max_ammo").text = str(gun_node.get_child(gun_index).max_bullet)
	gun_data_viewer.get_child(gun_index).get_node("gun_name").text = str(gun_node.get_child(gun_index).gun_type)
	pass

func show_gun_info(gun_index):
	gun_data_viewer.get_child(gun_index).visible = true
	gun_data_viewer.get_child((gun_index + 1)%2).visible = false

func add_damage_indicator(damage):
	var new_damage_indiactor = Gamedata.damage_indicators[damage].instance()#damage_indicator_scene.instance()
	add_child(new_damage_indiactor)
	pass

func full_magazine():
	gun_node.get_child(0).fast_reload()
	gun_node.get_child(1).fast_reload()

func got_hit(source):
	var temp = damage_indicator.instance()
	var shot_direction = source - global_transform.origin
	if(shot_direction == Vector3.ZERO):
		return
	var forward_dir =  torso.to_global(Vector3(0,0,2)) - torso.to_global(Vector3(0,0,0))
	var angle = Vector2(forward_dir.x,forward_dir.z).angle_to(Vector2(shot_direction.x,shot_direction.z))
	get_node("ColorRect").add_child(temp)
	temp.rect_position = Vector2(-109,-200)
	temp.rect_rotation = rad2deg(angle)
	pass

func show_headshot():
	var new_temp = headshot_notification.instance()
	get_node("ColorRect").add_child(new_temp)
