extends VBoxContainer

onready var demo_node = get_node("demo")
var player_labels = {}

func add_player(id):
	var new_node = demo_node.duplicate()
	new_node.show()
	add_child(new_node)
	new_node.get_node("id").text = str(id)
	new_node.get_node("health").text = str(GameData.player_max_health)
	player_labels[id] = new_node	
	
func add_player_name(id,player_name):
	if(id in player_labels):
		player_labels[id].get_node("name").text = player_name
	pass
	
func delete_player(id):
	if(id in player_labels):
		player_labels[id].queue_free()
		player_labels.erase(id)
	
func change_health(id,new_health):
	if(id in player_labels):
		player_labels[id].get_node("health").text = str(new_health)
	pass
