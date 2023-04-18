extends ImmediateGeometry


var grav = Vector3(0,-0.01,0)
var velocity = Vector3.ZERO
#var speed = 1

func showline(source,target):
#	pass
	clear()

	begin(Mesh.PRIMITIVE_TRIANGLES )
	var direction = target - source
	direction = direction.normalized()
	var velocity = direction * 1
	var wide = 0.2
	var prev = source
	for i in range(0,10):
		if(velocity != Vector3.ZERO):
			prev = source
			source.x += velocity.x*2
			source.z += velocity.z*2
			source.y += (velocity.y + grav.y)*2
			velocity.y += (grav.y)*2
			wide += 0.03
		pass
	for i in range(0,40):
		if(velocity != Vector3.ZERO):
			
			prev = source
			source.x += velocity.x*2
			source.z += velocity.z*2
			source.y += (velocity.y + grav.y)*2
			velocity.y += (grav.y)*2
			wide += 0.03
			
			var temp_direc = source - prev
#			print(temp_direc)
			temp_direc = temp_direc.normalized()
			
			var left_direc = temp_direc.cross(Vector3.UP)
			left_direc = left_direc.normalized()
			set_normal(Vector3(0,0,1))
			set_uv(Vector2(0,0))
			add_vertex(prev + (left_direc * 2))

			set_normal(Vector3(0,0,1))
			set_uv(Vector2(0,0))
			add_vertex(prev - (left_direc * 2))
			
			
			set_normal(Vector3(0,0,1))
			set_uv(Vector2(0,0))
			add_vertex(prev + (temp_direc*3))
			
			
			
		pass
	# Prepare attributes for add_vertex
	set_normal(Vector3(0, 0, 1))
	set_uv(Vector2(0, 0))
	# Call last for each vertex, adds the above attributes.
	add_vertex(source + Vector3(0.2,0,0))

	set_normal(Vector3(0, 0, 1))
	set_uv(Vector2(0, 1))
	add_vertex(target)

	set_normal(Vector3(0, 0, 1))
	set_uv(Vector2(1, 1))
	add_vertex(source + Vector3(-0.2,0,0))	
	end()

#func _process(_delta):
#	# Clean up before drawing.
#	clear()
#
#	# Begin draw.
#	begin(Mesh.PRIMITIVE_TRIANGLES)
#
#	# Prepare attributes for add_vertex.
#	set_normal(Vector3(0, 0, 1))
#	set_uv(Vector2(0, 0))
#	# Call last for each vertex, adds the above attributes.
#	add_vertex(Vector3(-1, -1, 0))
#
#	set_normal(Vector3(0, 0, 1))
#	set_uv(Vector2(0, 1))
#	add_vertex(Vector3(-1, 1, 0))
#
#	set_normal(Vector3(0, 0, 1))
#	set_uv(Vector2(1, 1))
#	add_vertex(Vector3(1, 1, 0))
#
#	# End drawing.
#	end()
