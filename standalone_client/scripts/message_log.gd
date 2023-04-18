extends Control

onready var message_container = $message_container
onready var demo_node = $message_container/demo_node

func add_message(mes_data):
	if(mes_data["TYPE"] == "DEATH"):
		var new_label = demo_node.duplicate()
		new_label.visible = true
		message_container.add_child(new_label)
		if(mes_data["BODY"]["VICTIM"] != Server.network.get_unique_id()):
			if(mes_data["BODY"]["VICTIM"] in Server.player_instances):
				Server.player_instances[mes_data["BODY"]["VICTIM"]].make_dormant()
				
				#adding soul
				var new_soul = Server.soul_model.instance()
				Server.world_node.add_child(new_soul)
				new_soul.global_transform.origin = Server.player_instances[mes_data["BODY"]["VICTIM"]].global_transform.origin
				new_soul.get_node("Particles").emitting = true
		if(mes_data["BODY"]["SHOOTER"] == Server.network.get_unique_id() and mes_data["BODY"]["SHOT_TYPE"] == "HEADSHOT"):
			Server.player_char.show_headshot()
			pass
		new_label.bbcode_text = "[b][color=white]" + str(mes_data["BODY"]["SHOOTER_NAME"]) + "[/color][/b]" + " [color=black][b]KILLED[/b][/color] " + "[b][color=#62009e]"+ str(mes_data["BODY"]["VICTIM_NAME"]) + "[/color][/b]"
		if(message_container.get_child_count() > 6):
			message_container.get_child(1).queue_free()
	if(mes_data["TYPE"] == "SPAWN"):
		var pl_id = mes_data["BODY"]["PLAYER_ID"]
		if (pl_id in Server.player_instances):
			Server.player_instances[pl_id].global_transform.origin = mes_data["BODY"]["NEW_POS"]
			Server.player_instances[pl_id].make_active()
