extends Node3D


const collision_treshhold = 1e-3


var G = 6.674e-11 # https://en.wikipedia.org/wiki/Gravitational_constant

var mesh = ArrayMesh.new()

var points = []
var masses = PackedFloat64Array()
var accelerations = []

func _ready():
	seed(123434423443524)
	$GUI/Sim_Settings/Sim_Settings/Reset.connect("pressed", reset_sim)
	$GUI/Sim_Settings/Sim_Settings/G.value = G
	
	$MeshInstance3D.mesh = mesh

func reset_sim():
	$Camera3D.reset_camera()
	G = $GUI/Sim_Settings/Sim_Settings/G.value
	var particle_num = $GUI/Sim_Settings/Sim_Settings/Particle_Count.value
	var distribution_option = $GUI/Sim_Settings/Sim_Settings/Distribution.get_selected_id()
	var accel_option = $GUI/Sim_Settings/Sim_Settings/Initial_Acceleration.get_selected_id()
	
	var sim_radius = 5.0
	var starting_mass = 1000.0
	
	points = []
	masses = PackedFloat64Array()
	accelerations = []
	
	
	for x in particle_num:
		var p = [0.0, 0.0, 0.0]
		
		if distribution_option == 0:
			#print("Uniform distribution: Box")
			p[0] = sim_radius * randf() - (sim_radius / 2.0)
			p[1] = sim_radius * randf() - (sim_radius / 2.0)
			p[2] = sim_radius * randf() - (sim_radius / 2.0)
		
		if distribution_option == 1:
			#print("Non-Uniform distribution: Sphere")
			var r = sim_radius * randf()
			var theta = randf() * 2.0 * PI
			var phi = randf() * PI
			p[0] = r * sin(phi) * cos(theta)
			p[1] = r * sin(phi) * sin(theta)
			p[2] = r * cos(phi)
		
		if distribution_option == 2:
			#print("Uniform distribution: Sphere")
			var r = sim_radius * randf()
			p[0] = (randf() - 0.5) * r
			p[1] = (randf() - 0.5) * r
			p[2] = (randf() - 0.5) * r
		
		if distribution_option == 3:
			#print("Non-Uniform distribution: 3 Sphere")
			var r = sim_radius * randf()
			var theta = randf() * 2.0 * PI
			var phi = randf() * PI
			var c = randf() * 3
			if c <= 1:
				p[0] = r * sin(phi) * cos(theta) + sim_radius
				p[1] = r * sin(phi) * sin(theta)
				p[2] = r * cos(phi)
			if 1 < c and c <= 2:
				p[0] = r * sin(phi) * cos(theta) - sim_radius / 2.0
				p[1] = r * sin(phi) * sin(theta) + sim_radius / 2.0
				p[2] = r * cos(phi)
			if 2 < c:
				p[0] = r * sin(phi) * cos(theta) - sim_radius / 2.0
				p[1] = r * sin(phi) * sin(theta) - sim_radius / 2.0
				p[2] = r * cos(phi)
		
		var m = starting_mass
		var a = [0.0, 0.0, 0.0]
		
		if accel_option == 1:
			a[0] = randf() * 0.1
			a[1] = randf() * 0.1
			a[2] = randf() * 0.1
		if accel_option == 2:
			a[0] = randf()
			a[1] = randf()
			a[2] = randf()
		
		points.append(p)
		masses.append(m)
		accelerations.append(a)
	
	redraw_mesh()

func redraw_mesh():
	if points.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		
		var p = PackedVector3Array()
		p.resize(points.size())
		for i in points.size():
			p[i] = Vector3(points[i][0], points[i][1], points[i][2])
		
		arrays[Mesh.ARRAY_VERTEX] = p
		
		mesh.clear_surfaces()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arrays)
		
		$GUI.num_points(points.size())




func assimilate(index_dict):
	for key in index_dict.keys():
		for val in index_dict[key]:
			
			var Fx = accelerations[key][0] * masses[key] + accelerations[val][0] * masses[val]
			var Fy = accelerations[key][1] * masses[key] + accelerations[val][1] * masses[val]
			var Fz = accelerations[key][2] * masses[key] + accelerations[val][2] * masses[val]
			
			var m = masses[key] + masses[val]
			
			accelerations[key][0] = Fx / m
			accelerations[key][1] = Fy / m
			accelerations[key][2] = Fz / m
			
			masses[key] = m
	
	for key in index_dict.keys():
		for val in index_dict[key]:
			points.remove_at(val)
			masses.remove_at(val)
			accelerations.remove_at(val)
			print("Removed: ", val)

func integrate(delta, index, dFx, dFy, dFz):
	accelerations[index][0] += dFx / masses[index]
	accelerations[index][1] += dFy / masses[index]
	accelerations[index][2] += dFz / masses[index]
	
	var vx = accelerations[index][0] * delta
	var vy = accelerations[index][1] * delta
	var vz = accelerations[index][2] * delta
	
	points[index][0] = points[index][0] + vx
	points[index][1] = points[index][1] + vy
	points[index][2] = points[index][2] + vz

func sim_naive(delta):
	# F = G * m1 * m2 / r**2
	# A += sum(F) / m
	# V = A * dt
	
	var points_to_del = {}
	
	var particle_num = points.size()
	for x in particle_num:
		var dFx = 0.0
		var dFy = 0.0
		var dFz = 0.0
		
		for y in particle_num:
			if x != y:
				var dir_Fx : float = points[y][0] - points[x][0]
				var dir_Fy : float = points[y][1] - points[x][1]
				var dir_Fz : float = points[y][2] - points[x][2]
				var r2 : float = dir_Fx * dir_Fx + dir_Fy * dir_Fy + dir_Fz * dir_Fz
				var m2 : float = masses[x] * masses[y]
				var F : float = G * m2 / r2
				var r = sqrt(r2)
				var dir_F2x = dir_Fx / r
				var dir_F2y = dir_Fy / r
				var dir_F2z = dir_Fz / r
				dFx += dir_F2x * F
				dFy += dir_F2y * F
				dFz += dir_F2z * F
				
				if r < collision_treshhold:
					if not (y in points_to_del.keys() and x in points_to_del[y]):
						if x in points_to_del.keys():
							points_to_del[x].append(y)
						else:
							points_to_del[x] = [y]
		
		integrate(delta, x, dFx, dFy, dFz)
	
	assimilate(points_to_del)

func sim_barnes_hut(delta):
	# https://patterns.eecs.berkeley.edu/?page_id=193
	
	var points_to_del = {}
	var forces = []
	var octree = OCTree.new(null, G)
	forces.resize(points.size())
	for index in len(points):
		octree.insert(index, points[index][0], points[index][1], points[index][2], masses[index])
	octree.compute_mass(points, masses)
	octree.get_forces(points, forces, collision_treshhold, points_to_del)
	#print(forces)
	for index in len(points):
		integrate(delta, index, forces[index][0], forces[index][1], forces[index][2])
	assimilate(points_to_del)

#func _physics_process(delta):
func _process(delta):
	
	#sim_naive(delta)
	sim_barnes_hut(delta)
	
	redraw_mesh()


