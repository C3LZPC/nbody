extends CanvasLayer


func num_points(num : int) -> void:
	$Sim_Settings/Sim_Settings/Particle_Count_Label.text = "Particles: " + str(num)

func _ready():
	var distributions = []
	distributions.append("Uniform: Box")
	distributions.append("Non-Uniform: Sphere")
	distributions.append("Uniform: Sphere")
	distributions.append("Non-Uniform: 3 Sphere")
	for i in distributions:
		$Sim_Settings/Sim_Settings/Distribution.add_item(i)
	
	var accelerations = []
	accelerations.append("None")
	accelerations.append("x0.1")
	accelerations.append("x1.0")
	for i in accelerations:
		$Sim_Settings/Sim_Settings/Initial_Acceleration.add_item(i)

func _process(_delta):
	var fps = Engine.get_frames_per_second()
	$Stats/Box/FPS/FPS.text = str(fps)
	$Stats/Box/Frame_Time/Time.text = str(1/fps) + " s"
