extends VBoxContainer

onready var demo_row = $demo

func recreate_player_list(joined_player_data):
	for i in range(1,get_children().size()):
		get_child(i).queue_free()
	print(joined_player_data)
	for id in joined_player_data:
		var new_row = demo_row.duplicate()
		add_child(new_row)
		new_row.get_node("name").text = str(joined_player_data[id]["name"])
		new_row.get_node("id").text = str(id)
		new_row.get_node("post").text = str(joined_player_data[id]["is_host"])
		new_row.get_node("ready").text = str(joined_player_data[id]["ready"])
		new_row.visible = true
		pass
	pass
