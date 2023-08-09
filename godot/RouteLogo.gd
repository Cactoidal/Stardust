extends Sprite3D

func _ready():
	Global.route_logo = self
	texture = Global.get_chain_info(Global.current_chain)["logo"]


