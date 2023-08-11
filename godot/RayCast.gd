extends RayCast

var pending_reward = 0
var check_cargo_sold_timer = 0
var previous_balance = 0

func _process(delta):
		if check_cargo_sold_timer > 0:
			check_cargo_sold_timer -= delta
			if check_cargo_sold_timer < 0:
				var sold = Global.check_cargo_sold()
				if sold == false:
					check_cargo_sold_timer = 7
				else:
					check_cargo_sold_timer = 0
					complete_cargo_sold()
	
	
		if is_colliding():
			Global.reticle.color = Color(1,1,1,1)
			if Input.is_action_just_pressed("3d_click"):
				
				if get_collider().name == "MusicThing":
					get_collider().get_parent().activate()
				
				if get_collider().name == "Anodyne":
					Global.cargo_console.anodyne()
				if get_collider().name == "Tech":
					Global.cargo_console.tech()
				if get_collider().name == "Contraband":
					Global.cargo_console.contraband()
				
				if get_collider().name == "ClaimDemo":
					var file = File.new()
					file.open("user://keystore", File.READ)
					var content = file.get_buffer(32)
					var source = Global.get_chain_info(Global.current_chain)
					var success = Ccip.make_claim(content, source["chain_id"], source["stardust_contract"], source["rpc"], Global.user_address)
					file.close()
					if success:
						get_collider().get_parent().get_node("Claim").text = "P L A C E D\nC L A I M"
					else:
						get_collider().get_parent().get_node("Claim").text = "T X\nE R R O R"
					
				if Global.in_flight == false:
					if get_collider().name == "LeftButton":
						Global.chain_selector -= 1
						if Global.chain_selector < 0:
							Global.chain_selector = 3
						if Global.must_sell == false:
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
						if Global.must_sell == false:
							Global.launch_console.get_node("LAUNCH").text = "LAUNCH"
						Global.launch_console.get_node("Timer").visible = false
						Global.destination_chain = Global.available_chains[Global.chain_selector]
						Global.launch_console.get_node("Destination").texture = Global.get_chain_info(Global.destination_chain)["logo"]
						if Global.get_chain_info(Global.destination_chain)["player_balance"] == 0:
							Global.launch_console.get_node("Timer").text = "NO GAS THERE"
							Global.launch_console.get_node("Timer").visible = true
					
					if get_collider().name == "LaunchButton":
						if Global.get_chain_info(Global.destination_chain)["player_balance"] > 0:
							
							if Global.must_sell == true:
								
								var file = File.new()
								file.open("user://keystore", File.READ)
								var content = file.get_buffer(32)
								var manifest = Global.cargo_console.read_manifest()
								
								pending_reward =  String((int(manifest[1]) * 2) + (int(manifest[2]) * 12) + (int(manifest[3]) * 22))
								
								previous_balance = parse_json(Global.pilot)["coinBalance"].hex_to_int()
								var source = Global.get_chain_info(Global.current_chain)
								var success = Ccip.declare_cargo(content, source["chain_id"], source["stardust_contract"], source["rpc"], manifest[0], manifest[1], manifest[2], manifest[3])
								file.close()
								if success:
									check_cargo_sold_timer = 7
									Global.launch_console.get_node("LAUNCH").text = "SELLING..."
								else:
									Global.launch_console.get_node("LAUNCH").text = "TX ERROR"
								return

							if Global.cargo_console.valid == true:
								
								var cargo = Global.cargo_console.create_manifest()
								
								var file = File.new()
								file.open("user://keystore", File.READ)
								var content = file.get_buffer(32)
								
								var source = Global.get_chain_info(Global.current_chain)
								var destination = Global.get_chain_info(Global.destination_chain)
							
								var success = Ccip.ccip_send(content, source["chain_id"], source["stardust_contract"], source["rpc"], destination["chain_selector"], destination["stardust_contract"], cargo)
								
								if success:
									Global.start_flight_timer(Global.get_chain_info(Global.current_chain)["flight_time"])
									Global.available_chains.erase(Global.get_chain_info(Global.destination_chain)["name"])
									Global.available_chains.push_back(Global.current_chain)
									
									Global.current_chain = Global.destination_chain
									Global.route_logo.texture = Global.get_chain_info(Global.current_chain)["logo"]
									Global.launch_console.get_node("Destination").texture = Global.chainlink_logo
									Global.launch_console.get_node("LAUNCH").text = "IN TRANSIT"
									Global.blockspace.warping = true
									Global.blockspace.arriving = false
									Global.must_sell = true
									
									Global.cargo_console.get_node("HoldUsed").visible = false
									Global.cargo_console.get_node("MoneySpent").visible = false
								
								else:
									Global.launch_console.get_node("LAUNCH").text = "TX ERROR"
								
								file.close()
								
							else:
								Global.launch_console.get_node("LAUNCH").text = "BAD CARGO"
						
		else:
			Global.reticle.color = Color(1,1,1,0.27)


func complete_cargo_sold():
	var outcome = parse_json(Global.pilot)["coinBalance"].hex_to_int() - previous_balance
	if outcome < 0:
		Global.reticle.get_parent().get_node("Reward").text = "CONTRABAND DETECTED! " + String(outcome) + " MONEY"
	else:
		Global.reticle.get_parent().get_node("Reward").text = "REWARD: +" + String(outcome) + " MONEY"
	Global.reticle.get_parent().get_node("Reward").visible = true
	Global.reticle.get_parent().get_parent().reward_visible_timer = 3
	var empty_manifest = File.new()
	empty_manifest.open("user://manifest", File.WRITE)
	empty_manifest.store_var([""])
	empty_manifest.close() 
	Global.launch_console.get_node("LAUNCH").text = "LAUNCH"
	Global.must_sell = false
	Global.cargo_console.update_money()
	
