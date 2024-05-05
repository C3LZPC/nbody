extends Node3D


const collision_treshhold = 1e-3



var G = 6.674e-11 # https://en.wikipedia.org/wiki/Gravitational_constant

var mesh = ArrayMesh.new()

#var points = PackedVector3Array()
var points = []
var masses = PackedFloat64Array()
#var accelerations = PackedVector3Array()
var accelerations = []

func _ready():
	$GUI/Sim_Settings/Sim_Settings/Reset.connect("pressed", reset_sim)
	$GUI/Sim_Settings/Sim_Settings/G.value = G
	
	$MeshInstance3D.mesh = mesh

func reset_sim():
	G = $GUI/Sim_Settings/Sim_Settings/G.value
	var particle_num = $GUI/Sim_Settings/Sim_Settings/Particle_Count.value
	
	var sim_radius = 10
	var starting_mass = 1000.0
	
	#points = PackedVector3Array()
	points = []
	masses = PackedFloat64Array()
	#accelerations = PackedVector3Array()
	accelerations = []
	
	
	for x in particle_num:
		#var p = Vector3(sim_radius * randf() - (sim_radius / 2.0), 0, sim_radius * randf() - (sim_radius / 2.0))
		var p = [sim_radius * randf() - (sim_radius / 2.0), 0.0, sim_radius * randf() - (sim_radius / 2.0)]
		var m = starting_mass
		#var a = Vector3((randf() - 0.5) * 0.1, 0, (randf() - 0.5) * 0.1)
		var a = [0.0, 0.0, 0.0]
		
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
			"""
			if i == 0:
				print(p[i])
				print(points[i][0], ", ", points[i][1], ", ", points[i][2])
			"""
		
		arrays[Mesh.ARRAY_VERTEX] = p
		
		mesh.clear_surfaces()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arrays)
		
		$GUI.num_points(points.size())



func _process(delta):
	# F = G * m1 * m2 / r**2
	# A += sum(F) / m
	# V = A * dt
	
	var points_to_del = {}
	
	var particle_num = points.size()
	for x in particle_num:
		var dFx = 0.0
		var dFy = 0.0
		var dFz = 0.0
		var dm = 0.0
		
		for y in particle_num:
			if x != y:
				#var r2 : float = Vector3(points[x]).distance_squared_to(points[y])
				
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
				
				"""
				if x == 0:
					print("-----")
					print(F, " = ", G, " * ", m2, " / ", r2)
					print(dir_Fx, ", ", dir_Fy, ", ", dir_Fz)
					print(r)
					print(dir_F2x, ", ", dir_F2y, ", ", dir_F2z)
					print(dir_F2x * F, ", ", dir_F2y * F, ", ", dir_F2z * F)
					print(":")
					print(dFx, ", ", dFy, ", ", dFz)
				"""
				
				if r < collision_treshhold:
					if not (y in points_to_del.keys() and x in points_to_del[y]):
						if x in points_to_del.keys():
							points_to_del[x].append(y)
						else:
							points_to_del[x] = [y]
		
		accelerations[x][0] += dFx / masses[x]
		accelerations[x][1] += dFy / masses[x]
		accelerations[x][2] += dFz / masses[x]
		
		var vx = accelerations[x][0] * delta
		var vy = accelerations[x][1] * delta
		var vz = accelerations[x][2] * delta
		
		
		points[x][0] = points[x][0] + vx
		points[x][1] = points[x][1] + vy
		points[x][2] = points[x][2] + vz
		
		"""
		if x == 0:
			print("-----")
			print(accelerations[x][0], ", ", accelerations[x][1], ", ", accelerations[x][2])
			print(vx, ", ", vy, ", ", vz)
			#print(points[x].x + vx, ", ", points[x].y + vy, ", ", points[x].z + vz)
			#print(points[x].x, ", ", points[x].y, ", ", points[x].z)
			
			#print(points[x][0] + vx, ", ", points[x][1] + vy, ", ", points[x][2] + vz)
			print(points[x][0], ", ", points[x][1], ", ", points[x][2])
		"""
	
	for key in points_to_del.keys():
		for val in points_to_del[key]:
			
			var Fx = accelerations[key][0] * masses[key] + accelerations[val][0] * masses[val]
			var Fy = accelerations[key][1] * masses[key] + accelerations[val][1] * masses[val]
			var Fz = accelerations[key][2] * masses[key] + accelerations[val][2] * masses[val]
			
			var m = masses[key] + masses[val]
			
			accelerations[key][0] = Fx / m
			accelerations[key][1] = Fy / m
			accelerations[key][2] = Fz / m
			
			masses[key] = m
	
	for key in points_to_del.keys():
		for val in points_to_del[key]:
			points.remove_at(val)
			masses.remove_at(val)
			accelerations.remove_at(val)
			print("Removed: ", val)
	
	redraw_mesh()


