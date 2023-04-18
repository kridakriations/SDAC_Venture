extends Spatial

var main_id
onready var torso = $"%body"
onready var head = $"%head"
onready var gun_node = $"%gun_node"
onready var left_leg = $"%left_leg"
onready var right_leg = $"%right_leg"

var is_dormant = false

func add_primary_gun(gun_code):
	var new_gun_model = load(GameData.primary_gun_collision_models[gun_code])
	var new_gun = new_gun_model.instance()
	gun_node.add_child(new_gun)

func add_secondary_gun(gun_code):
	var new_gun_model = load(GameData.secondary_gun_collision_models[gun_code])
	var new_gun = new_gun_model.instance()
	gun_node.add_child(new_gun)
	gun_node.move_child(new_gun,1)

func make_dormant():
	if(is_dormant == true):
		return
	is_dormant = true
	get_node("body/CollisionShape").disabled = true
	get_node("body/head/CollisionShape").disabled = true
	get_node("body/legs_node/left_leg/left_leg_area/CollisionShape").disabled = true
	get_node("body/legs_node/right_leg/left_leg_area/CollisionShape").disabled = true
#	gun_node.get_child(0).get_node("right_upper_arm/CollisionShape").disabled = true
#	gun_node.get_child(0).get_node("right_upper_arm/right_lower_arm/CollisionShape").disabled = true
#	gun_node.get_child(0).get_node("left_upper_arm/CollisionShape").disabled = true
#	gun_node.get_child(0).get_node("left_upper_arm/left_lower_arm/CollisionShape").disabled = true
#	gun_node.get_child(1).get_node("right_upper_arm/CollisionShape").disabled = true
#	gun_node.get_child(1).get_node("right_upper_arm/right_lower_arm/CollisionShape").disabled = true
#	gun_node.get_child(1).get_node("left_upper_arm/CollisionShape").disabled = true
#	gun_node.get_child(1).get_node("left_upper_arm/left_lower_arm/CollisionShape").disabled = true
#
	
func make_alive():
	if(is_dormant == false):
		return
	is_dormant = false
	get_node("body/CollisionShape").disabled = false
	get_node("body/head/CollisionShape").disabled = false
	get_node("body/legs_node/left_leg/left_leg_area/CollisionShape").disabled = false
	get_node("body/legs_node/right_leg/left_leg_area/CollisionShape").disabled = false
#	gun_node.get_child(0).get_node("right_upper_arm/CollisionShape").disabled = false
#	gun_node.get_child(0).get_node("right_upper_arm/right_lower_arm/CollisionShape").disabled = false
#	gun_node.get_child(0).get_node("left_upper_arm/CollisionShape").disabled = false
#	gun_node.get_child(0).get_node("left_upper_arm/left_lower_arm/CollisionShape").disabled = false
#	gun_node.get_child(1).get_node("right_upper_arm/CollisionShape").disabled = false
#	gun_node.get_child(1).get_node("right_upper_arm/right_lower_arm/CollisionShape").disabled = false
#	gun_node.get_child(1).get_node("left_upper_arm/CollisionShape").disabled = false
#	gun_node.get_child(1).get_node("left_upper_arm/left_lower_arm/CollisionShape").disabled = false
