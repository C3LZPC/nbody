extends RefCounted
class_name OCTree

var parent = null
var G = 0.0

var nodes = {
	0: null,
	1: null,
	2: null,
	3: null,
	4: null,
	5: null,
	6: null,
	7: null
}

var m = 0.0
var cm_x = 0.0
var cm_y = 0.0
var cm_z = 0.0

func _init(p, grav_constant):
	parent = p
	G = grav_constant

#func _get(property):
#	return nodes[property]

func get_centroid():
	var c = 0
	var d = {
		"x": 0.0,
		"y": 0.0,
		"z": 0.0,
	}
	for k in nodes.keys():
		if nodes[k] != null and nodes[k] is OCLeaf:
			c += 1
			d["x"] += nodes[k].x
			d["y"] += nodes[k].y
			d["z"] += nodes[k].z
		
		if nodes[k] != null and nodes[k] is OCTree:
			c += 1
			var b = nodes[k].get_centroid()
			d["x"] += b["x"]
			d["y"] += b["y"]
			d["z"] += b["z"]
	
	if c >= 1:
		d["x"] = d["x"] / c
		d["y"] = d["y"] / c
		d["z"] = d["z"] / c
	else:
		d["x"] = 0.0
		d["y"] = 0.0
		d["z"] = 0.0
	
	return d

func get_subtree_index(point_x, point_y, point_z):
	for k in nodes.keys():
		if nodes[k] == null:
			return k
	
	var d = get_centroid()
	if point_x > d["x"]:
		if point_y > d["y"]: # 0 - 3
			if point_z > d["z"]:
				return 0
			else:
				return 1
		else:
			if point_z > d["z"]:
				return 2
			else:
				return 3
	else:
		if point_y > d["y"]: # 4 - 7
			if point_z > d["z"]:
				return 4
			else:
				return 5
		else:
			if point_z > d["z"]:
				return 6
			else:
				return 7

func insert(index, point_x, point_y, point_z, mass):
	var idx = get_subtree_index(point_x, point_y, point_z)
	
	if nodes[idx] is OCTree:
		#print("Adding to an existing tree: ", index)
		nodes[idx].insert(index, point_x, point_y, point_z, mass)
		return
	
	elif nodes[idx] is OCLeaf:
		#print("Adding a new tree: ", index)
		var leaf = nodes[idx]
		nodes[idx] = OCTree.new(self, G)
		nodes[idx].insert(index, point_x, point_y, point_z, mass)
		nodes[idx].insert(leaf.i, leaf.x, leaf.y, leaf.z, leaf.m)
		return
	
	else: # nodes[idx] is null
		#print("Adding leaf: ", index)
		nodes[idx] = OCLeaf.new(self, index, point_x, point_y, point_z, mass)
		return

func compute_mass(points, masses):
	m = 0.0
	var weighted_cms = []
	for index in 8:
		if nodes[index] == null:
			continue
		
		if nodes[index] is OCLeaf:
			m += nodes[index].m
			weighted_cms.append([nodes[index].x * nodes[index].m, nodes[index].y * nodes[index].m, nodes[index].z * nodes[index].m])
		
		if nodes[index] is OCTree:
			nodes[index].compute_mass(points, masses)
			m += nodes[index].m
			weighted_cms.append([nodes[index].cm_x * nodes[index].m, nodes[index].cm_y * nodes[index].m, nodes[index].cm_z * nodes[index].m])
	
	cm_x = 0.0
	cm_y = 0.0
	cm_z = 0.0
	for e in weighted_cms:
		cm_x += e[0]
		cm_y += e[1]
		cm_z += e[2]
	cm_x = cm_x / m
	cm_y = cm_y / m
	cm_z = cm_z / m

func get_forces(points, forces, collision_treshhold, points_to_del):
	for x in 8:
		if nodes[x] == null:
			continue
		
		if nodes[x] is OCLeaf:
			var dFx = 0.0
			var dFy = 0.0
			var dFz = 0.0
			
			for y in 8:
				if nodes[y] == null:
					continue
				
				if nodes[y] is OCLeaf and nodes[y].i != nodes[x].i:
					var dir_Fx : float = points[nodes[y].i][0] - points[nodes[x].i][0]
					var dir_Fy : float = points[nodes[y].i][1] - points[nodes[x].i][1]
					var dir_Fz : float = points[nodes[y].i][2] - points[nodes[x].i][2]
					var r2 : float = dir_Fx * dir_Fx + dir_Fy * dir_Fy + dir_Fz * dir_Fz
					var m2 : float = nodes[y].m * nodes[x].m
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
				
				if nodes[y] is OCTree:
					var dir_Fx : float = nodes[y].cm_x - nodes[x].x
					var dir_Fy : float = nodes[y].cm_y - nodes[x].y
					var dir_Fz : float = nodes[y].cm_z - nodes[x].z
					var r2 : float = dir_Fx * dir_Fx + dir_Fy * dir_Fy + dir_Fz * dir_Fz
					var m2 : float = nodes[y].m * nodes[x].m
					var F : float = G * m2 / r2
					var r = sqrt(r2)
					var dir_F2x = dir_Fx / r
					var dir_F2y = dir_Fy / r
					var dir_F2z = dir_Fz / r
					dFx += dir_F2x * F
					dFy += dir_F2y * F
					dFz += dir_F2z * F
			
			#print("Adding forces ", dFx, ", ", dFy, ", ", dFz, " to node ", nodes[x].i)
			forces[nodes[x].i] = [dFx, dFy, dFz]
		
		if nodes[x] is OCTree:
			nodes[x].get_forces(points, forces, collision_treshhold, points_to_del)
	
	#TODO: parent trees?

