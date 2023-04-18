extends VBoxContainer

onready var top_row = $top_row

var rows = {}

func _ready():
	pass

func intialize(players_detail_data):
	for id in rows:
		rows[id].queue_free()
	rows = {}
	
	
	for id in players_detail_data:
		var new_row = top_row.duplicate()
		add_child(new_row)
		rows[id] = new_row
		new_row.get_node("name").text = str(id)
		new_row.get_node("kills").text = str(0)
		new_row.get_node("death").text = str(0)
		new_row.get_node("score").text = str(0)
	
func change_score(id,player_score):
	if(id in rows):
		rows[id].get_node("kills").text = str(player_score[id]["KILLS"])
		rows[id].get_node("death").text = str(player_score[id]["DEATH"])
		rows[id].get_node("score").text = str(player_score[id]["SCORE"])

