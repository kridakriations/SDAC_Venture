extends Panel




onready var score_list = $list
onready var score_list_row = $list/heading

var extra = []




func show_scores(new_scores):
	visible = true
	var self_id = Server.network.get_unique_id()
	for row in extra:
		row.queue_free()
	extra.clear()
	
	if(self_id in new_scores):
		var new_row = score_list_row.duplicate()
		new_row.get_node("name").text = str(Server.player_name)
		new_row.get_node("kills").text = str(new_scores[self_id]["KILLS"])
		new_row.get_node("death").text = str(new_scores[self_id]["DEATH"])
		new_row.get_node("score").text = str(new_scores[self_id]["SCORE"])
		score_list.add_child(new_row)
		extra.append(new_row)
		$grade_card/name.text = str(Server.player_name)
		$grade_card/primary_gun.text = Server.player_char.gun_node.get_child(0).gun_type
		$grade_card/accuracy.text = str(new_scores[self_id]["ACCURACY"])
		$grade_card/kills.text = str(new_scores[self_id]["KILLS"])
		$grade_card/deaths.text = str(new_scores[self_id]["DEATH"])
		$grade_card/headshots.text = str(new_scores[self_id]["HEADSHOTS"])
		$grade_card/shots_fired.text = str(new_scores[self_id]["SHOTS_FIRED"])
	for id in new_scores:
		if(self_id != id):
			var new_row = score_list_row.duplicate()
			new_row.get_node("name").text = str(Server.player_detail_buffer[id]["player_name"])
			new_row.get_node("kills").text = str(new_scores[id]["KILLS"])
			new_row.get_node("death").text = str(new_scores[id]["DEATH"])
			new_row.get_node("score").text = str(new_scores[id]["SCORE"])
			score_list.add_child(new_row)
			extra.append(new_row)



func _on_Button_pressed():
	Server.end_game()
	var own_id = Server.network.get_unique_id()
	if(Server.joined_player_data[own_id]["is_host"] == "HOST"):
		LoadingScreen.change_scene("res://host_scene.tscn")
	else:
		LoadingScreen.change_scene("res://main_scene.tscn")



func _on_to_main_menu_pressed():
	Server.close_connection()
