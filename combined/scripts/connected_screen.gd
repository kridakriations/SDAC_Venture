extends Control

func _on_disconnect_pressed():
	Server.network.close_connection()
	get_parent().get_node("anim").play("disconnected")
	Server.disconnection_drill()
	pass
