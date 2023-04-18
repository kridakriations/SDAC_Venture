extends Area

var grav = Vector3(0,-0.01,0)
var velocity = Vector3.ZERO
var speed = 1
var dormant = false

func set_speed(direction):
	velocity = direction * speed

func _physics_process(delta):
	if(velocity != Vector3.ZERO):
		global_transform.origin.x += velocity.x
		global_transform.origin.z += velocity.z
		global_transform.origin.y += (velocity.y + grav.y)
		velocity.y += grav.y


func _on_explosion_area_entered(area):
#	if(dormant == true):
#		return
	if(is_instance_valid(Server.world_node)):
		var space_state = Server.world_node.get_world().direct_space_state
		var dict = space_state.intersect_ray(global_transform.origin,Server.player_char.head.global_transform.origin,[],5,true,true)
		if(dict.empty() == false):
			visible = false
		velocity = Vector3.ZERO
		if(dormant == false):
			check_collision()
			pass
#			Server.bomb_blast_over_server(global_transform.origin,OS.get_system_time_msecs() - Server.time_offset - Server.render_offset)
		$AnimationPlayer.play("explosion")


func _on_AnimationPlayer_animation_finished(anim_name):
	pass
#	queue_free()


func _on_explosion_body_entered(body):
	print("bomb exploded on ",body.name)
	if(is_instance_valid(Server.world_node)):
		var space_state = Server.world_node.get_world().direct_space_state
		var dict = space_state.intersect_ray(global_transform.origin,Server.player_char.head.global_transform.origin,[],5,true,true)
		if(dict.empty() == false):
			visible = false
		velocity = Vector3.ZERO
		if(dormant == false):
			check_collision()
			pass
#			Server.bomb_blast_over_server(global_transform.origin,OS.get_system_time_msecs() - Server.time_offset - Server.render_offset)
		$AnimationPlayer.play("explosion")

func check_collision():
	var space_state = Server.world_node.get_world().direct_space_state
	var bomb_pos = global_transform.origin
	for id in Server.player_instances:
		var player_head_pos = Server.player_instances[id].global_transform.origin
		var dict = space_state.intersect_ray(bomb_pos,player_head_pos,[],5,true,true)
		if(dict.empty() == false):
			if(dict.has("collider") == false):
				continue
			var distance_from_blast = player_head_pos.distance_squared_to(bomb_pos)
			var collider = dict.collider
			if(distance_from_blast < 100):
				var damage = 100
				var victim_id = null
				if(collider.is_in_group("enemy_body")):
					victim_id = collider.get_parent().id
				elif(collider.is_in_group("enemy_head")):
					victim_id = collider.get_parent().get_parent().id
				
				print("victim id ",victim_id)
				if((victim_id != null) and (victim_id in get_tree().get_network_connected_peers())):
					if(Server.network.get_unique_id() == 1):
						Server.player_hit(1,victim_id,damage,"BOMB_SHOT",global_transform.origin)
					else:
						Server.rpc_id(1,"player_hit",Server.network.get_unique_id(),victim_id,damage,"BOMB_SHOT",global_transform.origin)
	# checking the collision for the user players
	print("started checking on player_char")
	if(is_instance_valid(Server.player_char)):
		var user_head_pos = Server.player_char.get_node("body/head/head_area").global_transform.origin
		var dict = space_state.intersect_ray(bomb_pos,user_head_pos,[],13,true,true)
		print(user_head_pos," ",bomb_pos)
		print("checking ",dict)
		if(dict.empty() == false):
#			print("checking ",dict)
			if(dict.has('collider') == true):
				var distance_from_blast = user_head_pos.distance_squared_to(bomb_pos)
				var collider = dict.collider
				if(distance_from_blast < 100):
					var damage = 100
					var victim_id = null
					if(collider.is_in_group("player_head")):
						victim_id = Server.network.get_unique_id()
					print(victim_id," victim id")
					if((victim_id != null)):
#						print("")
						if(Server.network.get_unique_id() == 1):
							Server.player_hit(1,victim_id,damage,"BOMB_SHOT",global_transform.origin)
						else:
							Server.rpc_id(1,"player_hit",Server.network.get_unique_id(),victim_id,damage,"BOMB_SHOT",global_transform.origin)
		
