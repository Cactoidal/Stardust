extends RayCast

func _process(delta):
	if is_colliding():
		if Input.is_action_just_pressed("3d_click"):
			if get_collider().name == "LeftButton":
				Global.chain_selector -= 1
				if Global.chain_selector < 0:
					Global.chain_selector = 3
				Global.destination_chain = Global.get_chain_info(Global.available_chains[Global.chain_selector])
				Global.launch_console.get_node("Destination").texture = Global.destination_chain["logo"]
			if get_collider().name == "RightButton":
				Global.chain_selector += 1
				if Global.chain_selector > 3:
					Global.chain_selector = 0
				Global.destination_chain = Global.get_chain_info(Global.available_chains[Global.chain_selector])
				Global.launch_console.get_node("Destination").texture = Global.destination_chain["logo"]
			if get_collider().name == "LaunchButton":
				Global.available_chains.erase(Global.destination_chain["name"])
				Global.available_chains.push_back(Global.current_chain["name"])
				Global.current_chain = Global.destination_chain
				Global.destination_chain = {}
				Global.launch_console.get_node("Destination").texture = Global.chainlink_logo
				Global.launch_console.get_node("LAUNCH").text = "IN TRANSIT"
				Global.start_flight_timer(Global.current_chain["flight_time"])
