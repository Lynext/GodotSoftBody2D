extends Node


func _ready():
	pass

func getVectorByLA (length, angle):
	angle = deg2rad(angle)
	var vector = Vector2(cos(angle), sin(angle)) * length
	return vector
