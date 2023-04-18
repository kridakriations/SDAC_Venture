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
	if(is_instance_valid(Server.world_node)):
		var space_state = Server.world_node.get_world().direct_space_state
		var dict = space_state.intersect_ray(global_transform.origin,Server.player_char.head.global_transform.origin,[],5,true,true)
		if(dict.empty() == false):
			visible = false
		velocity = Vector3.ZERO
		if(dormant == false):
			Server.bomb_blast_over_server(global_transform.origin,OS.get_system_time_msecs() - Server.time_offset - Server.render_offset)
		$AnimationPlayer.play("explosion")


func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()


func _on_explosion_body_entered(body):
	if(is_instance_valid(Server.world_node)):
		var space_state = Server.world_node.get_world().direct_space_state
		var dict = space_state.intersect_ray(global_transform.origin,Server.player_char.head.global_transform.origin,[],5,true,true)
		if(dict.empty() == false):
			visible = false
		velocity = Vector3.ZERO
		if(dormant == false):
			Server.bomb_blast_over_server(global_transform.origin,OS.get_system_time_msecs() - Server.time_offset - Server.render_offset)
		$AnimationPlayer.play("explosion")
