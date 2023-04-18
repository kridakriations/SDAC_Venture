extends Control

onready var list_of_options = [
	get_node("primary_gun/primary_gun_list"),
	get_node("secondary_gun/secondary_gun_list")
]

func _ready():
	hide_all_options()
	
func hide_all_options():
	for i in list_of_options:
		i.hide()

func _on_hairstyle_mouse_entered():
	hide_all_options()
	$hairstyle/hairstyle_list.visible = true
	$hairstyle.texture_normal = load("res://assets/sprites/hairstyle_logo_hovered.png")
	
func _on_hairstyle_mouse_exited():
	hide_all_options()
	$hairstyle.texture_normal = load("res://assets/sprites/hairstyle_logo.png")


func _on_primary_gun_mouse_entered():
	hide_all_options()
	$primary_gun/primary_gun_list.visible = true
	$primary_gun.texture_normal = load("res://assets/sprites/hairstyle_logo_hovered.png")


func _on_primary_gun_mouse_exited():
	hide_all_options()
	$primary_gun.texture_normal = load("res://assets/sprites/hairstyle_logo.png")


func _on_secondary_gun_mouse_entered():
	hide_all_options()
	$secondary_gun/secondary_gun_list.visible = true
	$secondary_gun.texture_normal = load("res://assets/sprites/hairstyle_logo_hovered.png")


func _on_secondary_gun_mouse_exited():
	hide_all_options()
	$secondary_gun.texture_normal = load("res://assets/sprites/hairstyle_logo.png")
