extends Control


func _ready():
	$panel/senstivity_slider.value = Gamedata.senstivity_value
	$panel/senstivity_label.text = str(Gamedata.senstivity_value)
	set_settings()
#	_on_apply_button_pressed()

func _on_senstivity_slider_value_changed(value):
	$panel/senstivity_label.text = str(value)
	
func _on_render_distance_slider_value_changed(value):
	$panel/render_distance_value.text = str(value)

func set_settings():
	var settings = Gamedata.load_file(Gamedata.settings_file_address)
	if(settings.empty() == false):
		$panel/senstivity_slider.value = settings["senstivity_value"]
		$panel/music_sound_slider.value = settings["music_value"]
		$panel/sound_effect_slider.value = settings["sfx_value"]
		$panel/sfx_mute_button.pressed = settings["sfx_mute"]		
		$panel/shading_checkbox.pressed = settings["shading"]
		$panel/shadows_check_box.pressed = settings["shadows"]
		$panel/render_distance_slider.value = settings["render_distance"]
	else:
		_on_reset_button_pressed()
	_on_apply_button_pressed()

func _on_pause_screen_visibility_changed():
	if(visible == true):
		set_settings()

func _on_apply_button_pressed():
	var new_settings = {}
	new_settings["senstivity_value"] = $panel/senstivity_slider.value
	new_settings["music_value"] = $panel/music_sound_slider.value
	new_settings["sfx_value"] = $panel/sound_effect_slider.value
	new_settings["sfx_mute"] = $panel/sfx_mute_button.pressed	
	new_settings["shading"] = $panel/shading_checkbox.pressed
	new_settings["shadows"] = $panel/shadows_check_box.pressed
	new_settings["render_distance"] = $panel/render_distance_slider.value
	
	Gamedata.save_file(new_settings,Gamedata.settings_file_address)
	
	Gamedata.senstivity_value = new_settings["senstivity_value"]
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("sfx"),linear2db(new_settings["sfx_value"]))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("gun_sfx"),linear2db(new_settings["sfx_value"]*4))
	
#	var is_mute = AudioServer.is_bus_mute(AudioServer.get_bus_index("sfx"))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("sfx"),(new_settings["sfx_mute"]))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("gun_sfx"),(new_settings["sfx_mute"]))

	#applying graphics settings
	if(new_settings["shading"] == true):
		if(get_parent().map_id == 0):
			get_parent().get_node("level").get_child(0).get_node("BakedLightmap").light_data = load("res://light_maps/test6.lmbake")
		if(get_parent().map_id == 1):
			get_parent().get_node("level").get_child(0).get_node("BakedLightmap").light_data = load("res://light_maps/dio_test10.lmbake")
	else:
		get_parent().get_node("level").get_child(0).get_node("BakedLightmap").light_data = null
	
	if(new_settings["shadows"] == true):
		get_parent().get_node("level").get_child(0).get_node("DirectionalLight").shadow_enabled = true
	elif(new_settings["shadows"] == false):
		get_parent().get_node("level").get_child(0).get_node("DirectionalLight").shadow_enabled = false

	get_parent().get_node("abhishek").get_node("body/head/Camera").far = new_settings["render_distance"]

func _on_reset_button_pressed():
	$panel/senstivity_slider.value = Gamedata.settings["senstivity_value"]
	$panel/music_sound_slider.value = Gamedata.settings["music_value"]
	$panel/sound_effect_slider.value = Gamedata.settings["sfx_value"]
	$panel/sfx_mute_button.pressed = Gamedata.settings["sfx_mute"]		
	$panel/shading_checkbox.pressed = Gamedata.settings["shading"]
	$panel/shadows_check_box.pressed = Gamedata.settings["shadows"]
	$panel/render_distance_slider.value = Gamedata.settings["render_distance"]
