extends Button


onready var senstivity_value = $Control/senstivity_value
onready var music_volume_value = $Control/music_volume_value
onready var sfx_volume_value = $Control/sfx_volume_value

func _ready():
#	print("linear for db 80 ",db2linear(6))
#	print("linear for db -10 ",db2linear(-10))
	$Control/senstivity_slider.value = Gamedata.senstivity_value
	set_settings()
	pass

func _on_senstivity_slider_value_changed(value):
	senstivity_value.text = str(value)
	
	pass



func _on_sound_effect_slider_value_changed(value):
	pass
#	print(value," ",linear2db(value))
#	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("sfx"),linear2db(value))
#	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("gun_sfx"),linear2db(value*4))


func _on_sfx_mute_button_pressed():
	pass
#	print(AudioServer.is_bus_mute(AudioServer.get_bus_index("sfx")))


func _on_music_sound_slider_value_changed(value):
	pass # Replace with function body.

func set_settings():
	var settings = Gamedata.load_file(Gamedata.settings_file_address)
	if(settings.empty() == false):
		$Control/senstivity_slider.value = settings["senstivity_value"]
		$Control/music_sound_slider.value = settings["music_value"]
		$Control/sound_effect_slider.value = settings["sfx_value"]
		$Control/sfx_mute_button.pressed = settings["sfx_mute"]		
		$Control/shading_checkbox.pressed = settings["shading"]
		$Control/shadows_check_box.pressed = settings["shadows"]
		$Control/render_distance_slider.value = settings["render_distance"]
	else:
		_on_reset_button_pressed()
	_on_apply_button_pressed()

func _on_Control_visibility_changed():
	if($Control.visible == true):
		set_settings()

func _on_apply_button_pressed():
#	print(OS.get_user_data_dir())
	var new_settings = {}
	new_settings["senstivity_value"] = $Control/senstivity_slider.value
	new_settings["music_value"] = $Control/music_sound_slider.value
	new_settings["sfx_value"] = $Control/sound_effect_slider.value
	new_settings["sfx_mute"] = $Control/sfx_mute_button.pressed	
	new_settings["shading"] = $Control/shading_checkbox.pressed
	new_settings["shadows"] = $Control/shadows_check_box.pressed
	new_settings["render_distance"] = $Control/render_distance_slider.value
	
	Gamedata.save_file(new_settings,Gamedata.settings_file_address)
	
	Gamedata.senstivity_value = new_settings["senstivity_value"]
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("sfx"),linear2db(new_settings["sfx_value"]))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("gun_sfx"),linear2db(new_settings["sfx_value"]*4))
	
#	var is_mute = AudioServer.is_bus_mute(AudioServer.get_bus_index("sfx"))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("sfx"),(new_settings["sfx_mute"]))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("gun_sfx"),(new_settings["sfx_mute"]))




func _on_render_distance_slider_value_changed(value):
	$Control/render_distance_value.text = str(value)
	pass # Replace with function body.



func _on_reset_button_pressed():
	$Control/senstivity_slider.value = Gamedata.settings["senstivity_value"]
	$Control/music_sound_slider.value = Gamedata.settings["music_value"]
	$Control/sound_effect_slider.value = Gamedata.settings["sfx_value"]
	$Control/sfx_mute_button.pressed = Gamedata.settings["sfx_mute"]		
	$Control/shading_checkbox.pressed = Gamedata.settings["shading"]
	$Control/shadows_check_box.pressed = Gamedata.settings["shadows"]
	$Control/render_distance_slider.value = Gamedata.settings["render_distance"]
	pass
