extends Button

onready var panel_list = $Control/panel_list
var panel_visible = 0

func _on_left_button_pressed():
	print("left_button_pressed")
	panel_list.get_child(panel_visible).visible = false
	panel_visible += 1
	panel_visible += panel_list.get_child_count()
	panel_visible = panel_visible % panel_list.get_child_count()
	panel_list.get_child(panel_visible).visible = true

func _on_right_button_pressed():
	print("right_button_pressed")
	panel_list.get_child(panel_visible).visible = false
	panel_visible -= 1
	panel_visible += panel_list.get_child_count()
	panel_visible = panel_visible % panel_list.get_child_count()
	panel_list.get_child(panel_visible).visible = true

func clicked_image1(event):
	if(event.is_pressed() == true):
		$Control/full_image.texture = panel_list.get_child(panel_visible).get_child(0).texture
		$Control/full_image.visible = true
		panel_list.visible = false
func clicked_image2(event):
	if(event.is_pressed() == true):
		$Control/full_image.texture = panel_list.get_child(panel_visible).get_child(0).texture
		$Control/full_image.visible = true
		panel_list.visible = false


func _on_Button_pressed():
	$Control/full_image.visible = false
	panel_list.visible = true
