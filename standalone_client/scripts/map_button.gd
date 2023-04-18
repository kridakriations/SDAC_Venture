extends Button

onready var game_settings_panel = get_node("game_settings")


func _on_close_game_settings_pressed():
	game_settings_panel.visible = false


func _on_map_button_pressed():
	game_settings_panel.visible = true


func _on_OptionButton_item_selected(index):
	get_parent().curr_map_code = index


func _on_SpinBox_value_changed(value):
	get_parent().curr_game_time = value
