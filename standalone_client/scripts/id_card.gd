extends Control



var curr_outfit = 0
var curr_secondary_gun = 0
var curr_primary_gun = 0
var curr_map_code = 0
var curr_game_time = 4

var outfit_code = {
	"shirt":6,
	"jacket":5,
	"shoes":5,
	"pants":3
}

var dormant = false

func _ready():
	var new_outfit = Gamedata.load_file(Gamedata.outfit_file_address)
	if(new_outfit.empty()):
		print("here")
		$player.change_complete_outfit(Gamedata.default_outfit_code)
	else:
		$player.change_complete_outfit(new_outfit)
		outfit_code = new_outfit
	

func _on_swap_gun_pressed():
	$player.swap_gun()


func _on_secondary_gun_next_pressed():
	curr_secondary_gun += 1
	curr_secondary_gun = curr_secondary_gun % Gamedata.total_secondary_guns
	$player.change_secondary_gun(curr_secondary_gun)
	$secondary_gun_shower.text = Gamedata.secondary_guns_name[curr_secondary_gun]
	$player.change_complete_outfit(outfit_code)

func _on_secondary_gun_prev_pressed():
	curr_secondary_gun -= 1
	curr_secondary_gun = curr_secondary_gun % Gamedata.total_secondary_guns
	$player.change_secondary_gun(curr_secondary_gun)
	$secondary_gun_shower.text = Gamedata.secondary_guns_name[curr_secondary_gun]
	$player.change_complete_outfit(outfit_code)

func _on_primary_gun_next_pressed():
	curr_primary_gun += 1
	curr_primary_gun = curr_primary_gun % Gamedata.total_primary_guns
	$player.change_primary_gun(curr_primary_gun)
	$primary_gun_shower.text = Gamedata.primary_guns_name[curr_primary_gun]
	$player.change_complete_outfit(outfit_code)
	
func _on_primary_gun_prev_pressed():
	curr_primary_gun -= 1
	curr_primary_gun = curr_primary_gun % Gamedata.total_primary_guns
	$player.change_primary_gun(curr_primary_gun)
	$primary_gun_shower.text = Gamedata.primary_guns_name[curr_primary_gun]
	$player.change_complete_outfit(outfit_code)
	
func _on_hairstyle_list_item_selected(index):
	get_parent().press_button()


func _on_shoes_list_item_selected(index):
	outfit_code["shoes"] = index
	$player.change_complete_outfit(outfit_code)
	get_parent().press_button()

func _on_pant_list_item_selected(index):
	outfit_code["pants"] = index
	$player.change_complete_outfit(outfit_code)
	get_parent().press_button()

func _on_jacket_list_item_selected(index):
	outfit_code["jacket"] = index
	$player.change_complete_outfit(outfit_code)
	get_parent().press_button()

func _on_tshirt_list_item_selected(index):
	outfit_code["shirt"] = index
	$player.change_complete_outfit(outfit_code)
	get_parent().press_button()

func _on_primary_gun_list_item_selected(index):
	curr_primary_gun = index
	$player.change_primary_gun(curr_primary_gun)
	$primary_gun.text = Gamedata.primary_guns_name[curr_primary_gun]
	$player.change_complete_outfit(outfit_code)
	get_parent().press_button()

func _on_secondary_gun_list_item_selected(index):
	curr_secondary_gun = index
	$player.change_secondary_gun(curr_secondary_gun)
	$secondary_gun.text = Gamedata.secondary_guns_name[curr_secondary_gun]
	$player.change_complete_outfit(outfit_code)
	get_parent().press_button()

func make_dormant():
	$primary_gun_shower.get_child(0).visible = false
	$primary_gun_shower.get_child(1).visible = false
#	$secondary_gun_shower.get_child(0).visible = false
#	$secondary_gun_shower.get_child(1).visible = false
	$dress/outfit_shower.get_node("outfit_next").visible = false
	$dress/outfit_shower.get_node("outfit_prev").visible = false
#	mouse_filter = Control.MOUSE_FILTER_STOP
	dormant = true
	pass

func make_active():
	$primary_gun_shower.get_child(0).visible = true
	$primary_gun_shower.get_child(1).visible = true
	$secondary_gun_shower.get_child(0).visible = true
	$secondary_gun_shower.get_child(1).visible = true
	$dress/outfit_shower.get_node("outfit_next").visible = true
	$dress/outfit_shower.get_node("outfit_prev").visible = true
	dormant = false
#	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pass





func _on_save_outfit_button_pressed():
	Gamedata.save_file(outfit_code,Gamedata.outfit_file_address)
	pass
