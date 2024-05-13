extends RefCounted
class_name OCLeaf


var p = null
var i = -1
var x = 0.0
var y = 0.0
var z = 0.0
var m = 0.0

func _init(parent, index, point_x, point_y, point_z, mass):
	p = parent
	i = index
	x = point_x
	y = point_y
	z = point_z
	m = mass
