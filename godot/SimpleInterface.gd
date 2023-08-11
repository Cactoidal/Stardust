extends Control



func _ready():
	Global.launch_console = self
	$Destination.texture = Global.get_chain_info(Global.destination_chain)["logo"]

	if Global.get_chain_info(Global.destination_chain)["player_balance"] == 0:
		$Timer.text = "NO GAS THERE"
		$Timer.visible = true
	
	if Global.start_in_warp == true:
		$Destination.texture = load("res://buttons/chainlink.png")

	if parse_json(Global.pilot)["cargo"] != "0x":
		Global.must_sell = true
		$LAUNCH.text = "SELL CARGO"
