extends Control

var user_address
var pilot

var create_player_pilot = false

var current_chain = "Fuji"
var destination_chain = "Optimism"

var chain_selector = 0
var available_chains = ["Optimism", "Arbitrum", "Sepolia", "Mumbai", "Fuji"]

var fuji_rpc = "https://avalanche-fuji-c-chain.publicnode.com"
var mumbai_rpc = "https://rpc-mumbai.maticvigil.com"
var sepolia_rpc = "https://endpoints.omniatech.io/v1/eth/sepolia/public"
var optimism_rpc = "https://optimism-goerli.publicnode.com"
var arbitrum_rpc = "https://endpoints.omniatech.io/v1/arbitrum/goerli/public"

var balance_selector = 0
var fuji_balance = 0
var mumbai_balance = 0
var sepolia_balance = 0
var optimism_balance = 0
var arbitrum_balance = 0

var fuji_faucet = "https://core.app/en/tools/testnet-faucet/?subnet=c&token=c"
var mumbai_faucet = "https://faucet.polygon.technology"
var sepolia_faucet = "https://sepolia-faucet.pk910.de"
var optimism_faucet = "https://app.optimism.io/faucet"
var arbitrum_faucet = "https://faucet.quicknode.com/arbitrum/goerli"


var fuji_stardust = "0x8e2735402D348E4f3183E15C13dD2b4e14e148E9"
var mumbai_stardust = "0xA8FaA189B6625AF213243fB346d463789d506480"
var sepolia_stardust = "0x9C9315eb4E542C910301c17E81F40192124fD778"
var optimism_stardust = "0xf09839D028B59c6eDF4D0BF0Af7961D7fbEbE9F0"
var arbitrum_stardust = "0xE67dD115DDB112771c519926d1F7c4F9e973c960"

var fuji_id = 43113
var mumbai_id = 80001
var sepolia_id = 11155111
var optimism_id = 420
var arbitrum_id = 421613

var fuji_selector = "ccf0a31a221f3c9b"
var mumbai_selector = "adecc60412ce25a5"
var sepolia_selector = "de41ba4fc9d91ad9"
var optimism_selector = "24f9b897ef58a922"
var arbitrum_selector = "54abf9fb1afeaf95"

var fuji_flight_time = 300
var optimism_flight_time = 1500
var arbitrum_flight_time = 1500
var mumbai_flight_time = 1500
var sepolia_flight_time = 1500

var fuji_logo = load("res://buttons/Avalanche.png")
var arbitrum_logo = load("res://buttons/arbitrum.png")
var optimism_logo = load("res://buttons/Optimism.png")
var sepolia_logo = load("res://buttons/Ethereum.png")
var mumbai_logo = load("res://buttons/Polygon.png")
var chainlink_logo = load("res://buttons/chainlink.png")

var fuji_color = [1.0, 0.0, 0.3]
var mumbai_color = [0.48, 0.0, 0.9]
var optimism_color = [1.0, 0.0, 0.1]
var arbitrum_color = [0.18, 0.18, 0.68]
var sepolia_color = [1.0, 1.0, 0.68]

var launch_console
var cargo_console
var blockspace

var entering_port_timer = -1
var entering_port = false

var start_in_warp = false
var route_logo
var reticle

var must_sell = false
	

func get_chain_info(var chain):
	match chain:
		"Fuji": return {"name": "Fuji", "rpc": fuji_rpc, "chain_id": fuji_id, "chain_selector": fuji_selector, "flight_time": fuji_flight_time, "logo": fuji_logo, "player_balance": fuji_balance, "stardust_contract": fuji_stardust, "color": fuji_color}
		"Optimism": return {"name": "Optimism", "rpc": optimism_rpc, "chain_id": optimism_id, "chain_selector": optimism_selector, "flight_time": optimism_flight_time, "logo": optimism_logo, "player_balance": optimism_balance, "stardust_contract": optimism_stardust, "color": optimism_color}
		"Arbitrum": return {"name": "Arbitrum", "rpc": arbitrum_rpc, "chain_id": arbitrum_id, "chain_selector": arbitrum_selector, "flight_time": arbitrum_flight_time, "logo": arbitrum_logo, "player_balance": arbitrum_balance, "stardust_contract": arbitrum_stardust, "color": arbitrum_color}
		"Mumbai": return {"name": "Mumbai", "rpc": mumbai_rpc, "chain_id": mumbai_id, "chain_selector": mumbai_selector, "flight_time": mumbai_flight_time, "logo": mumbai_logo, "player_balance": mumbai_balance, "stardust_contract": mumbai_stardust, "color": mumbai_color}
		"Sepolia": return {"name": "Sepolia", "rpc": sepolia_rpc, "chain_id": sepolia_id, "chain_selector": sepolia_selector, "flight_time": sepolia_flight_time, "logo": sepolia_logo, "player_balance": sepolia_balance, "stardust_contract": sepolia_stardust, "color": sepolia_color}

var flight_timer = 0
var in_flight = false
func start_flight_timer(var flight_time):
	blockspace.color_time = 3
	launch_console.get_node("Timer").visible = true
	launch_console.get_node("Timer").text = String(flight_timer)
	flight_timer = flight_time
	in_flight = true
	

func _process(delta):
	
	if entering_port_timer > -1:
		entering_port_timer -= delta
		if entering_port_timer < 0:
			if check_pilot() == true:
				complete_flight()
				
	if in_flight == true && entering_port == false:
		flight_timer -= delta
		launch_console.get_node("Timer").text = String(flight_timer)
		if flight_timer <= 0:
			flight_timer = 0
			if check_pilot() == true:
				complete_flight()


func check_pilot():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	var located = false
	
	for lookup in ["Optimism", "Arbitrum", "Sepolia", "Fuji", "Mumbai"]:
		if located == false:
			var chain = get_chain_info(lookup)
			Ccip.pilot_info(content, chain["chain_id"], chain["stardust_contract"], chain["rpc"], user_address, self)
			if parse_json(pilot).onChain == true:
				current_chain = lookup
				located = true
				available_chains.erase(lookup)
				destination_chain = available_chains[0]
				chain_selector = 0
				entering_port_timer = -1
				entering_port = false
				return true
	
	if located == false:
		entering_port = true
		entering_port_timer = 20
		launch_console.get_node("LAUNCH").text = "ARRIVING..."
		return false
	
	file.close()

#Called from Rust
func set_pilot(var _pilot):
	pilot = _pilot

func check_cargo_sold():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	Ccip.pilot_info(content, get_chain_info(current_chain)["chain_id"], get_chain_info(current_chain)["stardust_contract"], get_chain_info(current_chain)["rpc"], user_address, self)
	file.close()
	if parse_json(pilot).cargo == "0x":
		return true

func complete_flight():
	blockspace.warping = false
	blockspace.arriving = true
	blockspace.color_time = 3
	in_flight = false
	must_sell = true
	destination_chain = available_chains[0]
	chain_selector = 0
	launch_console.get_node("Destination").texture = get_chain_info(destination_chain)["logo"]
	launch_console.get_node("LAUNCH").text = "SELL CARGO"
	if get_chain_info(destination_chain)["player_balance"] == 0:
		launch_console.get_node("Timer").text = "NO GAS THERE"
	else:
		launch_console.get_node("Timer").visible = false
