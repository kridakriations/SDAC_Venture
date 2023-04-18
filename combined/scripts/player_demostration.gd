extends Spatial

onready var gun_node = $"%gun_node"
onready var body_mesh = $"%body_mesh"
onready var jacket_mesh = $"%jacket_mesh"
onready var left_upper_leg_mesh = $"%left_upper_leg_mesh"
#onready var left_lower_leg_mesh = $"%left_lower_leg_mesh"
onready var right_upper_leg_mesh = $"%right_upper_leg_mesh"
#onready var right_lower_leg_mesh = $"%right_lower_leg_mesh"

var gun_no = 0

func _ready():
	jacket_mesh.visible = false
	gun_node.get_child((gun_no + 1)%2).visible = false



func change_complete_outfit(outfit_code):
	if(outfit_code["jacket"] == 0):
		jacket_mesh.visible = false
		body_mesh.mesh.surface_set_material(0,(Gamedata.color[outfit_code["shirt"]]))
		gun_node.get_child(gun_no).change_outfit(outfit_code)
	else:
		jacket_mesh.visible = true
		jacket_mesh.mesh.surface_set_material(0,(Gamedata.color[outfit_code["jacket"]]))
		body_mesh.mesh.surface_set_material(0,(Gamedata.color[outfit_code["shirt"]]))
		gun_node.get_child(gun_no).change_outfit(outfit_code)
		
	left_upper_leg_mesh.mesh.surface_set_material(0,(Gamedata.color[outfit_code["pants"]]))
	left_upper_leg_mesh.mesh.surface_set_material(1,(Gamedata.color[outfit_code["shoes"]]))

	right_upper_leg_mesh.mesh.surface_set_material(0,(Gamedata.color[outfit_code["pants"]]))
	right_upper_leg_mesh.mesh.surface_set_material(1,(Gamedata.color[outfit_code["shoes"]]))




func change_secondary_gun(gun_code):
	gun_node.get_child(1).queue_free()
	var new_gun = Gamedata.secondary_guns_demostration[gun_code].instance()
	gun_node.add_child(new_gun)
	gun_node.move_child(new_gun,1)
	pass

func change_primary_gun(gun_code):
	gun_node.get_child(0).queue_free()
	var new_gun = Gamedata.primary_guns_demostration[gun_code].instance()
	gun_node.add_child(new_gun)
	gun_node.move_child(new_gun,0)
	pass
