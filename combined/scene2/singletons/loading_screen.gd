extends Control

export var path = "res://scene2/first_Screen.tscn"
var current_scene = null
var loader = null

func _ready():
	visible = true
#	get_parent().get_node("start_scene").visible = false
	change_scene(path)
	pass
	
func test_func():
	print("test")
	pass	

func change_scene(scene_path):
	visible = true
	if(loader == null):
		loader = ResourceLoader.load_interactive(scene_path)
		if(current_scene != null):
			current_scene.visible = false
			current_scene.queue_free()
			current_scene = null
	

func _process(delta):
	if(loader == null):
		return
	var err = loader.poll()
	if(err == ERR_FILE_EOF):
		var resource = loader.get_resource()
		loader = null
		
		set_new_scence(resource)
		
	elif(err == OK):
		pass
	else:
		loader = null
		pass



func set_new_scence(scence_resource):
	print("loaded ")
	current_scene = scence_resource.instance()
	print(current_scene.name)
	get_node("/root").call_deferred("add_child",current_scene)
	visible = false

