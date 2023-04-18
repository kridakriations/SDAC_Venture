extends Spatial

onready var gun_node = $"%gun_node"
onready var body_mesh = $"%body_mesh"
onready var jacket_mesh = $"%jacket_mesh"
onready var left_upper_leg_mesh = $"%left_upper_leg_mesh"
onready var right_upper_leg_mesh = $"%right_upper_leg_mesh"


var gun_no = 0

func _ready():
	jacket_mesh.visible = false
	gun_node.get_child((gun_no + 1)%2).visible = false
	pass


func make_dormant(make_invisible = true):
	visible = false
	$body/CollisionShape.disabled = true
	$body/head/CollisionShape.disabled = true
	pass

func make_active(make_visible = true):
	visible = true
	$body/CollisionShape.disabled = false
	$body/head/CollisionShape.disabled = false
	pass

func reload_gun():
	gun_node.get_child(gun_no).reload()

func swap_gun():
	gun_node.get_child(gun_no).visible = false
	gun_no = (gun_no + 1)%2
	gun_node.get_child(gun_no).visible = true

func shoot(target):
	gun_node.get_child(gun_no).shoot(target)

func change_complete_outfit(outfit_code):
	if(outfit_code["jacket"] == 0):
		jacket_mesh.visible = false
		body_mesh.set_surface_material(0,(Gamedata.color[outfit_code["shirt"]]))
		gun_node.get_child(gun_no).change_outfit(outfit_code)
		gun_node.get_child((gun_no+1)%2).change_outfit(outfit_code)
	else:
		jacket_mesh.visible = true
		jacket_mesh.set_surface_material(0,(Gamedata.color[outfit_code["jacket"]]))
		body_mesh.set_surface_material(0,(Gamedata.color[outfit_code["shirt"]]))
		gun_node.get_child(gun_no).change_outfit(outfit_code)
		gun_node.get_child((gun_no+1)%2).change_outfit(outfit_code)
		
	left_upper_leg_mesh.set_surface_material(0,(Gamedata.color[outfit_code["pants"]]))
	left_upper_leg_mesh.set_surface_material(1,(Gamedata.color[outfit_code["shoes"]]))

	right_upper_leg_mesh.set_surface_material(0,(Gamedata.color[outfit_code["pants"]]))
	right_upper_leg_mesh.set_surface_material(1,(Gamedata.color[outfit_code["shoes"]]))




func change_secondary_gun(gun_code):
	gun_node.get_child(1).queue_free()
	var new_gun_model = load(Gamedata.secondary_guns_enemy[gun_code])
	var new_gun = new_gun_model.instance()
	gun_node.add_child(new_gun)
	gun_node.move_child(new_gun,1)
	if(gun_no == 0):
		new_gun.visible = false
	pass


func change_primary_gun(gun_code):
	gun_node.get_child(0).queue_free()
	var new_gun_model = load(Gamedata.primary_guns_enemy[gun_code])
	var new_gun = new_gun_model.instance()
	gun_node.add_child(new_gun)
	gun_node.move_child(new_gun,0)
	if(gun_no == 1):
		new_gun.visible = false
	pass
