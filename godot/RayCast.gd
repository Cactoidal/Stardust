extends RayCast

func _process(delta):
	if Global.in_flight == false:
		if is_colliding():
			if Input.is_action_just_pressed("3d_click"):
				
				if get_collider().name == "LeftButton":
					Global.chain_selector -= 1
					if Global.chain_selector < 0:
						Global.chain_selector = 3
					Global.launch_console.get_node("Timer").visible = false
					Global.destination_chain = Global.get_chain_info(Global.available_chains[Global.chain_selector])
					Global.launch_console.get_node("Destination").texture = Global.destination_chain["logo"]
					if Global.destination_chain["player_balance"] == 0:
						Global.launch_console.get_node("Timer").text = "NO GAS THERE"
						Global.launch_console.get_node("Timer").visible = true
						
				if get_collider().name == "RightButton":
					Global.chain_selector += 1
					if Global.chain_selector > 3:
						Global.chain_selector = 0
					Global.launch_console.get_node("Timer").visible = false
					Global.destination_chain = Global.get_chain_info(Global.available_chains[Global.chain_selector])
					Global.launch_console.get_node("Destination").texture = Global.destination_chain["logo"]
					if Global.destination_chain["player_balance"] == 0:
						Global.launch_console.get_node("Timer").text = "NO GAS THERE"
						Global.launch_console.get_node("Timer").visible = true
				
				if get_collider().name == "LaunchButton":
					if Global.destination_chain["player_balance"] > 0:
						
						var file = File.new()
						file.open("user://keystore", File.READ)
						var content = file.get_buffer(32)
						#Ccip.ccip_send(content, Global.fuji_id, Global.fuji_stardust, Global.fuji_rpc, Global.mumbai_selector, Global.mumbai_stardust)
						Ccip.ccip_send(content, Global.current_chain["chain_id"], Global.current_chain["stardust_contract"], Global.current_chain["rpc"], Global.destination_chain["chain_selector"], Global.destination_chain["stardust_contract"])
						file.close()
						
						Global.start_flight_timer(Global.current_chain["flight_time"])
						Global.available_chains.erase(Global.destination_chain["name"])
						Global.available_chains.push_back(Global.current_chain["name"])
						
						Global.current_chain = Global.destination_chain
						Global.destination_chain = {}
						Global.launch_console.get_node("Destination").texture = Global.chainlink_logo
						Global.launch_console.get_node("LAUNCH").text = "IN TRANSIT"
						Global.blockspace.warping = true
						Global.blockspace.arriving = false
						
						
						
