extends Spatial


func _physics_process(delta):
	if(Input.is_action_just_pressed("grenade")):
		get_parent().get_node("AnimationPlayer").play("cinematic_shot")
		pass
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
