extends Control

func _ready():
	Global.launch_console = self
	$Destination.texture = Global.destination_chain["logo"]

	if Global.destination_chain["player_balance"] == 0:
		$Timer.text = "NO GAS THERE"
		$Timer.visible = true

