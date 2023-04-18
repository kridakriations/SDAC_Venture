extends Control


func _on_Control_visibility_changed():
	if(visible == true):
		Server.start_searching()
		pass
	else:
		Server.known_servers.clear()
		for i in range(1,$server_list_scroller/server_list.get_child_count()):
			$server_list_scroller/server_list.get_child(i).queue_free()
