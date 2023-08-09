extends Control



func _ready():
	Global.launch_console = self
	$Destination.texture = Global.get_chain_info(Global.destination_chain)["logo"]

	if Global.get_chain_info(Global.destination_chain)["player_balance"] == 0:
		$Timer.text = "NO GAS THERE"
		$Timer.visible = true

