extends RayCast

func _process(delta):
		if is_colliding():
			Global.reticle.color = Color(1,1,1,1)
			if Input.is_action_just_pressed("3d_click"):
				
				if get_collider().name == "MusicThing":
					get_collider().get_parent().activate()
					
				if Global.in_flight == false:
					if get_collider().name == "LeftButton":
						Global.chain_selector -= 1
						if Global.chain_selector < 0:
							Global.chain_selector = 3
						Global.launch_console.get_node("LAUNCH").text = "LAUNCH"
						Global.launch_console.get_node("Timer").visible = false
						Global.destination_chain = Global.available_chains[Global.chain_selector]
						Global.launch_console.get_node("Destination").texture = Global.get_chain_info(Global.destination_chain)["logo"]
						if Global.get_chain_info(Global.destination_chain)["player_balance"] == 0:
							Global.launch_console.get_node("Timer").text = "NO GAS THERE"
							Global.launch_console.get_node("Timer").visible = true
							
					if get_collider().name == "RightButton":
						Global.chain_selector += 1
						if Global.chain_selector > 3:
							Global.chain_selector = 0
						Global.launch_console.get_node("LAUNCH").text = "LAUNCH"
						Global.launch_console.get_node("Timer").visible = false
						Global.destination_chain = Global.available_chains[Global.chain_selector]
						Global.launch_console.get_node("Destination").texture = Global.get_chain_info(Global.destination_chain)["logo"]
						if Global.get_chain_info(Global.destination_chain)["player_balance"] == 0:
							Global.launch_console.get_node("Timer").text = "NO GAS THERE"
							Global.launch_console.get_node("Timer").visible = true
					
					if get_collider().name == "LaunchButton":
						if Global.get_chain_info(Global.destination_chain)["player_balance"] > 0:
							
							var file = File.new()
							file.open("user://keystore", File.READ)
							var content = file.get_buffer(32)
							
							var source = Global.get_chain_info(Global.current_chain)
							var destination = Global.get_chain_info(Global.destination_chain)
						
							var success = Ccip.ccip_send(content, source["chain_id"], source["stardust_contract"], source["rpc"], destination["chain_selector"], destination["stardust_contract"])
							
							if success:
								Global.start_flight_timer(Global.get_chain_info(Global.destination_chain)["flight_time"])
								Global.available_chains.erase(Global.get_chain_info(Global.destination_chain)["name"])
								Global.available_chains.push_back(Global.current_chain)
								
								Global.current_chain = Global.destination_chain
								Global.route_logo.texture = Global.get_chain_info(Global.current_chain)["logo"]
								Global.launch_console.get_node("Destination").texture = Global.chainlink_logo
								Global.launch_console.get_node("LAUNCH").text = "IN TRANSIT"
								Global.blockspace.warping = true
								Global.blockspace.arriving = false
							
							else:
								Global.launch_console.get_node("LAUNCH").text = "TX ERROR"
							
							file.close()
						
		else:
			Global.reticle.color = Color(1,1,1,0.27)
						
