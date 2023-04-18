extends MultiMeshInstance

export var min_distance = 10
var bullets = []
var new_bullets = []

func _process(delta):
	if(Engine.get_idle_frames()%2 == 0):
		bullets = new_bullets
		new_bullets = []
		var inst_count = bullets.size()
		var multi_mesh = multimesh
		multi_mesh.instance_count = inst_count
		if(inst_count != 0):
			var i = 0
			for bullet in bullets:
				var target = bullet["target"]
				var curr_pos = bullet["pos"]
				var speed = bullet["speed"]
				var direction = target - curr_pos
				direction = direction.normalized()
				curr_pos += direction * speed
				bullet["pos"] = curr_pos
				var curr_transform = Transform(Basis(),curr_pos)
				if(Transform(Basis(),target) != curr_transform):
					curr_transform = curr_transform.looking_at(target,Vector3.UP)
				multi_mesh.set_instance_transform(i,curr_transform)
				i += 1
				if(curr_pos.distance_squared_to(target) > min_distance):
#					bullets.erase(bullet)
					new_bullets.append(bullet)
					continue
				
			pass
		pass
