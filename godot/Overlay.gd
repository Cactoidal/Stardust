extends Control

var user_address

var fuji_rpc = "https://avalanche-fuji-c-chain.publicnode.com"
var mumbai_rpc = "https://rpc-mumbai.maticvigil.com"
var sepolia_rpc = "https://endpoints.omniatech.io/v1/eth/sepolia/public"
var optimism_rpc = "https://optimism-goerli.publicnode.com"
var arbitrum_rpc = "https://arbitrum-goerli.publicnode.com"

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

var chain_selector = 0

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

func _ready():
	check_keystore()
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	user_address = Ccip.get_address(content)
	$Log/Address.text = user_address
	file.close()
	get_balance()
	
	$Play.connect("pressed", self, "show_faucets")
	
	#$Start.connect("pressed", self, "get_balance")
	#$Start.connect("pressed", self, "create_pilot")
	
	#$Start.connect("pressed", self, "check_pilot")
	
	#$Network.connect("pressed", self, "ccip_send")
	
	$Log/Copy.connect("pressed",self,"copy_address")
	$Log/Advanced.connect("pressed", self, "open_config")
	$Log/Config/Arbitrum/RPC.text = arbitrum_rpc
	$Log/Config/Mumbai/RPC.text = mumbai_rpc
	$Log/Config/Optimism/RPC.text = optimism_rpc
	$Log/Config/Sepolia/RPC.text = sepolia_rpc
	$Log/Config/Fuji/RPC.text = fuji_rpc
	$Log/Config/Save.connect("pressed", self, "save_rpc_settings")
	
	$Log/Arbitrum.connect("pressed", self, "open_faucet",[arbitrum_faucet])
	$Log/Optimism.connect("pressed", self, "open_faucet",[optimism_faucet])
	$Log/Mumbai.connect("pressed", self, "open_faucet",[mumbai_faucet])
	$Log/Fuji.connect("pressed", self, "open_faucet",[fuji_faucet])
	$Log/Sepolia.connect("pressed", self, "open_faucet",[sepolia_faucet])
	

func check_keystore():
	var file = File.new()
	if file.file_exists("user://keystore") != true:
		var bytekey = Crypto.new()
		var content = bytekey.generate_random_bytes(32)
		file.open("user://keystore", File.WRITE)
		file.store_buffer(content)
		file.close()


func get_balance():
	Ccip.get_balance(user_address, fuji_rpc, self)
	Ccip.get_balance(user_address, mumbai_rpc, self)
	Ccip.get_balance(user_address, sepolia_rpc, self)
	Ccip.get_balance(user_address, optimism_rpc, self)
	Ccip.get_balance(user_address, arbitrum_rpc, self)


# Called from Rust
func set_balance(var chain_balance):
	match chain_selector:
		0: fuji_balance = float(chain_balance) / float(1e18)
		1: mumbai_balance = float(chain_balance) / float (1e18)
		2: sepolia_balance = float(chain_balance) / float(1e18)
		3: arbitrum_balance = float(chain_balance) / float(1e18)
		4: optimism_balance = float(chain_balance) / float(1e18)
	chain_selector += 1
	if chain_selector > 4:
		chain_selector = 0
		$Log/Fuji/Balance.text = "Fuji Balance: " + String(fuji_balance)
		$Log/Mumbai/Balance.text = "Mumbai Balance: " + String(mumbai_balance)
		$Log/Sepolia/Balance.text = "Sepolia Balance: " + String(sepolia_balance)
		$Log/Optimism/Balance.text = "OptG Balance: " + String(optimism_balance)
		$Log/Arbitrum/Balance.text = "ArbGBalance: " + String(arbitrum_balance)


func show_faucets():
	$Log.visible = true
	$ColorRect.color.a = 0.8

func copy_address():
	OS.set_clipboard(user_address)

func open_faucet(var url):
	OS.shell_open(url)

func open_config():
	$Log/Config.visible = true
	
func save_rpc_settings():
	arbitrum_rpc = $Log/Config/Arbitrum/RPC.text
	mumbai_rpc = $Log/Config/Mumbai/RPC.text
	optimism_rpc = $Log/Config/Optimism/RPC.text
	sepolia_rpc = $Log/Config/Sepolia/RPC.text
	fuji_rpc = $Log/Config/Fuji/RPC.text
	$Log/Config.visible = false

func create_pilot():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	Ccip.create_pilot(content, mumbai_id, mumbai_stardust, mumbai_rpc, "yenn")
	file.close()

func ccip_send():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	Ccip.ccip_send(content, mumbai_id, mumbai_stardust, mumbai_rpc, fuji_selector, fuji_stardust)
	file.close()

func ccip_send2():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	Ccip.ccip_send(content, fuji_id, fuji_stardust, fuji_rpc, mumbai_selector, mumbai_stardust)
	file.close()


func check_pilot():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	var located = false
	Ccip.pilot_info(content, mumbai_id, mumbai_stardust, mumbai_rpc, user_address, self)
	if parse_json(pilot).onChain == true:
		$Log/Pilot.text = "Mumbai"
		located = true
	Ccip.pilot_info(content, fuji_id, fuji_stardust, fuji_rpc, user_address, self)
	if parse_json(pilot).onChain == true:
		$Log/Pilot.text = "Fuji"
		located = true
	file.close()
	if located == false:
		$Log/Pilot.text = "In Transit"

func pilot_info():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	Ccip.pilot_info(content, mumbai_id, mumbai_stardust, mumbai_rpc, user_address, self)
	file.close()

var pilot
#Called from Rust
func set_pilot(var _pilot):
	pilot = _pilot
	


