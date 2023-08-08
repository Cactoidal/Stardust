extends Spatial

var arriving = false
var warping = false

var warp_color = [0,0,0]

var current_color

func _ready():
	Global.blockspace = self 
	if Global.start_in_warp == true:
		current_color = warp_color
	else:
		current_color = Global.current_chain["color"].duplicate()
	$WorldEnvironment.get_environment().background_color = Color(current_color[0],current_color[1],current_color[2],1.0)
	
func enter_warp(delta):
	for tone in range(3):
		if current_color[tone] < warp_color[tone]:
			current_color[tone] += delta
		if current_color[tone] > warp_color[tone]:
			current_color[tone] -= delta
	$WorldEnvironment.get_environment().background_color = Color(current_color[0],current_color[1],current_color[2],1.0)

func arrive(delta):
	for tone in range(3):
		if current_color[tone] < Global.current_chain["color"][tone]:
			current_color[tone] += delta
		if current_color[tone] > Global.current_chain["color"][tone]:
			current_color[tone] -= delta
	$WorldEnvironment.get_environment().background_color = Color(current_color[0],current_color[1],current_color[2],1)

var color_time = 0
func _process(delta):
	if color_time > 0:
		color_time -= delta
		if arriving == true:
			arrive(delta)
		if warping == true:
			enter_warp(delta)
