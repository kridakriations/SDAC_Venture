extends Panel

onready var score_list = $list
onready var score_list_row = $list/heading

var extra = []

func start_countdown():
	$Timer.start()
	pass
	
func _process(delta):
	$time_label.text = str(int($Timer.time_left))
	pass


func show_scores(new_scores):
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
	
	for id in new_scores:
		if(self_id != id):
			var new_row = score_list_row.duplicate()
			new_row.get_node("name").text = Server.player_detail_buffer[id]["player_name"]
			new_row.get_node("kills").text = str(new_scores[id]["KILLS"])
			new_row.get_node("death").text = str(new_scores[id]["DEATH"])
			new_row.get_node("score").text = str(new_scores[id]["SCORE"])
			score_list.add_child(new_row)
			extra.append(new_row)
	pass
