extends Spatial

var activated = false

func _ready():
	pass 
	
func _process(delta):
	if activated == true:
		$Player/CSGCombiner.rotate_y(0.01)


func activate():
	if activated == false:
		activated = true
		$Music.playing = true
	else:
		activated = false
		$Music.playing = false
