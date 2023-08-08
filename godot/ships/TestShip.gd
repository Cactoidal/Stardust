extends Spatial

var start_pos

func _ready():
	start_pos = global_transform.origin

var slide = 0.0025
func _process(delta):
	global_transform.origin.x += slide
	rotate_z(slide / 5)
	rotate_x(-slide / 20)
	if global_transform.origin.x > start_pos.x + 0.5 || global_transform.origin.x < start_pos.x - 0.2:
		slide *= -1
