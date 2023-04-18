extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# old gun_shot function
remote func gun_shot(render_time,source,target):
	var player_id = get_tree().get_rpc_sender_id()
	if !(player_id in player_instances):
		return 		
	if(player_instances[player_id].can_current_gun_shoot() == false):
		return false
	rpc_id(0,"enemy_gun_shot",player_id)
	world_node.player_score[player_id]["SHOTS_FIRED"]+=1
	for i in range(world_history.size()):
		if((i+1 < world_history.size()) and (world_history[i]["T"] <= render_time and world_history[i+1]["T"] > render_time)):
			var temp_state= {}
			for id in player_instances:
				temp_state[id] = {
					"torso_degree":player_instances[id].torso.rotation_degrees.y,
					"head_degree":player_instances[id].head.rotation_degrees.x,
					"player_position":player_instances[id].global_transform.origin
				}
			var prev_time = world_history[i]["T"]
			var next_time = world_history[i+1]["T"]
			var inter_factor = float(render_time - prev_time)/float(next_time - prev_time)
			for id in player_instances:
				if(id == player_id):
					continue
				player_instances[id].global_transform.origin = lerp(world_history[i]["player_data"][id]["player_position"],world_history[i+1]["player_data"][id]["player_position"],inter_factor)
				player_instances[id].torso.rotation_degrees.y = lerp(world_history[i]["player_data"][id]["torso_degree"],world_history[i+1]["player_data"][id]["torso_degree"],inter_factor)
				player_instances[id].head.rotation_degrees.x = lerp(world_history[i]["player_data"][id]["head_degree"],world_history[i+1]["player_data"][id]["head_degree"],inter_factor)
			if player_id in player_instances:
				var ray_cast = RayCast.new()
				ray_cast.enabled = true
				ray_cast.collide_with_areas = true
				world_node.add_child(ray_cast)
				ray_cast.global_transform.origin = source
				ray_cast.cast_to = ray_cast.to_local(target)##((target - ray_cast.global_transform.origin) * 10) + ray_cast.global_transform.origin
				ray_cast.add_exception(player_instances[player_id])
				ray_cast.add_exception(player_instances[player_id].get_node("body"))
				ray_cast.force_raycast_update()
				player_instances[player_id].shoot()
				if(ray_cast.is_colliding()):
					var collider = ray_cast.get_collider()
					if(collider.is_in_group("body")):
						collider.get_parent().damage(player_instances[player_id].gun_damage(),player_id,"BODYSHOT")
					if(collider.is_in_group("head")):
						collider.get_parent().get_parent().damage(player_instances[player_id].gun_damage()*3,player_id,"HEADSHOT")

			for id in player_instances:
				player_instances[id].global_transform.origin = temp_state[id]["player_position"]
				player_instances[id].torso.rotation_degrees.y = temp_state[id]["torso_degree"]
				player_instances[id].head.rotation_degrees.x = temp_state[id]["head_degree"]

			break


#old process input function

func process_input(data):
#	if(on_floor):
#		up_velocity = Vector3.ZERO
#	else:
#		up_velocity += (gravity * 0.016667)
	torso.rotation_degrees.y -= data["mouse_motion_x"]
	head.rotation_degrees.x = clamp(head.rotation_degrees.x + data["mouse_motion_y"],-70,90)
	
	
	var forward_dir = front_pos.global_transform.origin - back_pos.global_transform.origin #getting a vector for the front direction
	var left_dir = left_pos.global_transform.origin - back_pos.global_transform.origin # getting a vector for the left direction
	
	#movement code ===========================================================
	forward_dir = forward_dir.normalized() #normalizing the forward direction vector
	left_dir = left_dir.normalized()
	var add_velocity = Vector3.ZERO
	
	curr_move_direc = Vector2.ZERO
	if data["ui_up"]:
		add_velocity += forward_dir
		curr_move_direc.x += 1
	if data["ui_down"]:
		add_velocity -= forward_dir
		curr_move_direc.x -= 1
	if data["ui_left"]:
		add_velocity += left_dir
		curr_move_direc.y += 1
	if data["ui_right"]:
		add_velocity -= left_dir
		curr_move_direc.y -= 1
	if ((data["ui_select"]==true) and on_floor):
		up_velocity.y = jump_vel
	
	
	#code for the leg movement=====================================	
	if(curr_move_direc != prev_move_direc):
		legs.get_child(0).rotation_degrees.x = 0
		legs.get_child(1).rotation_degrees.x = 0
		legs.get_child(0).rotation_degrees.z = 0
		legs.get_child(1).rotation_degrees.z = 0
	if(curr_move_direc.x != 0):
		if(curr_move_direc.y > 0):
			legs.get_child(0).rotation_degrees.x += leg_rotation_snap * leg_direction
			legs.get_child(1).rotation_degrees.x -= leg_rotation_snap * leg_direction
			if(abs(legs.get_child(0).rotation_degrees.x) > 30):
				leg_direction *= -1
		elif(curr_move_direc.y < 0):
			legs.get_child(0).rotation_degrees.x -= leg_rotation_snap * leg_direction
			legs.get_child(1).rotation_degrees.x += leg_rotation_snap * leg_direction
			if(abs(legs.get_child(0).rotation_degrees.x) > 30):
				leg_direction *= -1
		else:
			legs.get_child(0).rotation_degrees.x -= leg_rotation_snap * leg_direction
			legs.get_child(1).rotation_degrees.x += leg_rotation_snap * leg_direction
			if(abs(legs.get_child(0).rotation_degrees.x) > 30):
				leg_direction *= -1
		if(curr_move_direc.y != 0):
			legs.get_child(0).rotation_degrees.z -= leg_rotation_snap * leg_direction_side
			legs.get_child(1).rotation_degrees.z += leg_rotation_snap * leg_direction_side
			if(abs(legs.get_child(0).rotation_degrees.z) > 30):
				leg_direction_side *= -1
	else:
		if(curr_move_direc.y != 0):
			legs.get_child(0).rotation_degrees.z -= leg_rotation_snap * leg_direction_side
			legs.get_child(1).rotation_degrees.z += leg_rotation_snap * leg_direction_side
			if(abs(legs.get_child(0).rotation_degrees.z) > 30):
				leg_direction_side *= -1			
	prev_move_direc = curr_move_direc
	# code ended for the leg movement=============================
	
		
	if(velocity.length() <= max_speed): #for keeping below the max speed max_speed
		velocity += add_velocity
		
		
	#adding physics
	velocity = lerp(velocity,Vector3.ZERO,0.5) #for deacceleration
	move_and_slide(((velocity*speed)+up_velocity)*(0.016667)*10,-Vector3.UP,true,4,deg2rad(70))
#	$body/RayCast.force_raycast_update()
#	if ($body/RayCast.is_colliding() == true):
#		on_floor = true
#	else:
#		on_floor = false
	
	
	#sending the player_update to the respective player
	var temp_data = {}
	temp_data["player_data"] = {
		"torso_degree":self.torso.rotation_degrees.y,
		"head_degree":self.head.rotation_degrees.x,
		"player_position":self.global_transform.origin,
		"left_leg_degrees":legs.get_node("left_leg").rotation_degrees,
		"right_leg_degrees":legs.get_node("right_leg").rotation_degrees,
		"up_velocity":self.up_velocity,
		"velocity":self.velocity,
		"on_floor":self.on_floor
	}
	temp_data["T"] = data["T"]
	Server.rpc_id(id,"update_player",temp_data)
