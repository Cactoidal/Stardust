extends Node

var user_address
var pilot

var current_chain = get_chain_info("Fuji")
var destination_chain = get_chain_info("Optimism")

var chain_selector = 0
var available_chains = ["Optimism", "Arbitrum", "Sepolia", "Mumbai"]

var fuji_rpc = "https://avalanche-fuji-c-chain.publicnode.com"
var mumbai_rpc = "https://rpc-mumbai.maticvigil.com"
var sepolia_rpc = "https://endpoints.omniatech.io/v1/eth/sepolia/public"
var optimism_rpc = "https://optimism-goerli.publicnode.com"
var arbitrum_rpc = "https://arbitrum-goerli.publicnode.com"

var balance_selector = 0
var fuji_balance = "0"
var mumbai_balance = "0"
var sepolia_balance = "0"
var optimism_balance = "0"
var arbitrum_balance = "0"

var fuji_faucet = "https://core.app/en/tools/testnet-faucet/?subnet=c&token=c"
var mumbai_faucet = "https://faucet.polygon.technology"
var sepolia_faucet = "https://sepolia-faucet.pk910.de"
var optimism_faucet = "https://app.optimism.io/faucet"
var arbitrum_faucet = "https://faucet.quicknode.com/arbitrum/goerli"

var fuji_stardust = "0x091ec5F9c7d12DfCa9468f662e2f395Cb9656c75"
var mumbai_stardust = "0xF0c3F3Ef23ACF07764e42342e85eE248A9bEd081"
var sepolia_stardust
var optimism_stardust
var arbitrum_stardust

var fuji_id = 43113
var mumbai_id = 80001
var sepolia_id = 11155111
var optimism_id = 420
var arbitrum_id = 421613

var fuji_selector = "CCF0A31A221F3C9B"
var mumbai_selector = "ADECC60412CE25A5"
var sepolia_selector = "DE41BA4FC9D91AD9"
var optimism_selector = "24F9B897EF58A922"
var arbitrum_selector = "54ABF9FB1AFEAF95"

var fuji_flight_time = 5
var optimism_flight_time = 25
var arbitrum_flight_time = 25
var mumbai_flight_time = 25
var sepolia_flight_time = 25

var fuji_logo = load("res://buttons/Avalanche.png")
var arbitrum_logo = load("res://buttons/arbitrum.png")
var optimism_logo = load("res://buttons/Optimism.png")
var sepolia_logo = load("res://buttons/Ethereum.png")
var mumbai_logo = load("res://buttons/Polygon.png")
var chainlink_logo = load("res://buttons/chainlink.png")

var launch_console

func get_chain_info(var chain):
	match chain:
		"Fuji": return {"name": "Fuji", "rpc": fuji_rpc, "chain_id": fuji_id, "chain_selector": fuji_selector, "flight_time": fuji_flight_time, "logo": fuji_logo, "player_balance": fuji_balance, "stardust_contract": fuji_stardust}
		"Optimism": return {"name": "Optimism", "rpc": optimism_rpc, "chain_id": optimism_id, "chain_selector": optimism_selector, "flight_time": optimism_flight_time, "logo": optimism_logo, "player_balance": optimism_balance, "stardust_contract": optimism_stardust}
		"Arbitrum": return {"name": "Arbitrum", "rpc": arbitrum_rpc, "chain_id": arbitrum_id, "chain_selector": arbitrum_selector, "flight_time": arbitrum_flight_time, "logo": arbitrum_logo, "player_balance": arbitrum_balance, "stardust_contract": arbitrum_stardust}
		"Mumbai": return {"name": "Mumbai", "rpc": mumbai_rpc, "chain_id": mumbai_id, "chain_selector": mumbai_selector, "flight_time": mumbai_flight_time, "logo": mumbai_logo, "player_balance": mumbai_balance, "stardust_contract": mumbai_stardust}
		"Sepolia": return {"name": "Sepolia", "rpc": sepolia_rpc, "chain_id": sepolia_id, "chain_selector": sepolia_selector, "flight_time": sepolia_flight_time, "logo": sepolia_logo, "player_balance": sepolia_balance, "stardust_contract": sepolia_stardust}

var flight_timer = 0
var in_flight = false
func start_flight_timer(var flight_time):
	launch_console.get_node("Timer").visible = true
	launch_console.get_node("Timer").text = String(flight_timer)
	flight_timer = flight_time
	in_flight = true
	

func _process(delta):
	if in_flight == true:
		flight_timer -= delta
		launch_console.get_node("Timer").text = String(flight_timer)
		if flight_timer <= 0:
			flight_timer = 0
			in_flight = false
			launch_console.get_node("Timer").visible = false
			launch_console.get_node("LAUNCH").text = "LAUNCH"
			destination_chain = get_chain_info(available_chains[0])
			launch_console.get_node("Destination").texture = destination_chain["logo"]
		
