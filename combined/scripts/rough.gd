#func _physics_process(delta):
#
#	var forward_dir = front_pos.global_transform.origin - back_pos.global_transform.origin #getting a vector for the front direction
#	var left_dir = left_pos.global_transform.origin - back_pos.global_transform.origin # getting a vector for the left direction
#
#	#movement code ===========================================================
#	forward_dir = forward_dir.normalized() #normalizing the forward direction vector
#	left_dir = left_dir.normalized()
#	var add_velocity = Vector3.ZERO
#	var moved = false
#	if Input.is_action_pressed("ui_up"):
#		add_velocity += forward_dir
#		moved = true
#		ui_up = true
#	if Input.is_action_pressed("ui_down"):
#		add_velocity -= forward_dir
#		moved = true
#		ui_down = true
#	if Input.is_action_pressed("ui_left"):
#		add_velocity += left_dir
#		moved = true
#		ui_left = true
#	if Input.is_action_pressed("ui_right"):
#		add_velocity -= left_dir
#		moved = true
#		ui_right = true
#	if Input.is_action_just_pressed("ui_select") and $body/RayCast.is_colliding():
#		up_velocity.y = jump_vel
#		ui_select = true
#
#
#	if(velocity.length() <= max_speed): #for keeping below the max speed max_speed
#		velocity += add_velocity
#	velocity = lerp(velocity,Vector3.ZERO,0.5) #for deacceleration
#	move_and_collide(((velocity*speed)+up_velocity)*(0.016667)*10)
#	$body/RayCast.force_raycast_update()
#	if($body/RayCast.is_colliding()):
#		in_air = false
#		up_velocity = Vector3.ZERO
#	else:
#		moved = false
#		in_air = true
#		up_velocity += (gravity * delta)
#
#
#
#	# movement code complete ========================================================
#
##	update_data(false) #updating the player details in the client singleton
#
#	if Input.is_action_just_pressed("stop_mouse"): # special line for restricting the movement of mouse after pressing TAB button
#		sense = !sense
#
#	var input_packet = {"mouse_motion_x":mouse_motion_x,
#						"mouse_motion_y":mouse_motion_y,
#						"ui_up":ui_up,
#						"ui_down":ui_down,
#						"ui_left":ui_left,
#						"ui_right":ui_right,
#						"ui_select":ui_select
#	}
#
#	input_buffer.append({"T":OS.get_system_time_msecs() - Server.time_offset,"user_input":input_packet})
#	mouse_motion_x = 0
#	mouse_motion_y = 0
#	ui_up = false
#	ui_down = false
#	ui_left = false
#	ui_right = false
#	ui_select = false
#	input_packet["T"] = OS.get_system_time_msecs()
#	Server.send_input(input_packet)
#
#	#reconcilation
#	reconcilate()










#old code for shooting which was in process function

#	if Input.is_action_pressed("shoot"):
#		var col_pt = front_head.global_transform.origin
#		if(front_ray.is_colliding()):
#			col_pt = front_ray.get_collision_point()
#		col_pt = front_head.global_transform.origin
#		Server.gun_shot(front_ray.global_transform.origin,col_pt)
#		if(gun_node.get_child(gun_no).curr_bullet > 0 ):
#			if(get_node("body/head/animation").is_playing() == false):
#				get_node("body/head/animation").play("recoil")
#			gun_node.get_child(gun_no).shoot(col_pt)
#		gun_data_viewer.get_child(gun_no).get_node("ammo").text = str(gun_node.get_child(gun_no).curr_bullet)
