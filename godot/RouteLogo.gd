extends Sprite3D

func _ready():
	Global.route_logo = self
	texture = Global.current_chain["logo"]
