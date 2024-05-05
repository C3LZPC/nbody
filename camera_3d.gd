extends Camera3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func reset_camera():
	self.position = Vector3(0, 8, 0)
	self.rotation_degrees = Vector3(-90, 0, 0) 
