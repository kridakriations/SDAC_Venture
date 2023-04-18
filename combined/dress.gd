extends Control

var dress_options = [
	"tshirt","jacket","pant","shoes"
]


var dress_option_value = 0

func _ready():
	hide_all_options()
	
func hide_all_options():
	for i in dress_options:
		get_node("outfit_shower").get_node(i).visible = false




func _on_outfit_shower_mouse_entered():
	if(get_parent().dormant == true):
		return
	hide_all_options()
	get_node("outfit_shower").get_node(dress_options[dress_option_value]).visible = true

func _on_outfit_shower_mouse_exited():
	hide_all_options()


func _on_outfit_prev_pressed():
	dress_option_value -= 1
	dress_option_value = dress_option_value % 4
	get_node("outfit_shower").text = dress_options[dress_option_value]
	pass



func _on_outfit_next_pressed():
	dress_option_value += 1
	dress_option_value = dress_option_value % 4
	get_node("outfit_shower").text = dress_options[dress_option_value]


func _on_save_outfit_button_pressed():
	pass # Replace with function body.
