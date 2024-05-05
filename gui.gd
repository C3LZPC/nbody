extends CanvasLayer


func num_points(num : int) -> void:
	$Sim_Settings/Sim_Settings/Particle_Count_Label.text = "Particles: " + str(num)

func _ready():
	var distributions = ["Uniform"]
	for i in distributions:
		$Sim_Settings/Sim_Settings/Distribution.add_item(i)

func _process(delta):
	var fps = Engine.get_frames_per_second()
	$Stats/Box/FPS/FPS.text = str(fps)
	$Stats/Box/Frame_Time/Time.text = str(1/fps) + " s"
