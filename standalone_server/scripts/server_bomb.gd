extends Area

var grav = Vector3(0,-0.01,0)
var velocity = Vector3.ZERO
var speed = 1
var thrower = null

func set_speed(direction):
	velocity = direction * speed
	
func _physics_process(delta):
	if(velocity != Vector3.ZERO):
		global_transform.origin.x += velocity.x
		global_transform.origin.z += velocity.z
		global_transform.origin.y += (velocity.y + grav.y)
		velocity.y += grav.y

func _on_bomb_area_entered(area):
	queue_free()
	pass


func _on_bomb_body_entered(body):
	queue_free()
	pass
