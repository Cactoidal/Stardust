extends Control

func _ready():
	check_keystore()
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	Global.user_address = Ccip.get_address(content)
	$Log/Address.text = Global.user_address
	file.close()
	get_balance()
	
	$Play.connect("pressed", self, "show_faucets")
	
	#$Start.connect("pressed", self, "get_balance")
	#$Start.connect("pressed", self, "create_pilot")
	
	#$Start.connect("pressed", self, "check_pilot")
	
	#$Network.connect("pressed", self, "ccip_send")
	
	$Log/Copy.connect("pressed",self,"copy_address")
	$Log/Advanced.connect("pressed", self, "open_config")
	$Log/Config/Arbitrum/RPC.text = Global.arbitrum_rpc
	$Log/Config/Mumbai/RPC.text = Global.mumbai_rpc
	$Log/Config/Optimism/RPC.text = Global.optimism_rpc
	$Log/Config/Sepolia/RPC.text = Global.sepolia_rpc
	$Log/Config/Fuji/RPC.text = Global.fuji_rpc
	$Log/Config/Save.connect("pressed", self, "save_rpc_settings")
	
	$Log/Arbitrum.connect("pressed", self, "open_faucet",[Global.arbitrum_faucet])
	$Log/Optimism.connect("pressed", self, "open_faucet",[Global.optimism_faucet])
	$Log/Mumbai.connect("pressed", self, "open_faucet",[Global.mumbai_faucet])
	$Log/Fuji.connect("pressed", self, "open_faucet",[Global.fuji_faucet])
	$Log/Sepolia.connect("pressed", self, "open_faucet",[Global.sepolia_faucet])
	

func check_keystore():
	var file = File.new()
	if file.file_exists("user://keystore") != true:
		var bytekey = Crypto.new()
		var content = bytekey.generate_random_bytes(32)
		file.open("user://keystore", File.WRITE)
		file.store_buffer(content)
		file.close()


func get_balance():
	Ccip.get_balance(Global.user_address, Global.fuji_rpc, self)
	Ccip.get_balance(Global.user_address, Global.mumbai_rpc, self)
	Ccip.get_balance(Global.user_address, Global.sepolia_rpc, self)
	Ccip.get_balance(Global.user_address, Global.optimism_rpc, self)
	Ccip.get_balance(Global.user_address, Global.arbitrum_rpc, self)


# Called from Rust
func set_balance(var chain_balance):
	match Global.balance_selector:
		0: Global.fuji_balance = float(chain_balance) / float(1e18)
		1: Global.mumbai_balance = float(chain_balance) / float (1e18)
		2: Global.sepolia_balance = float(chain_balance) / float(1e18)
		3: Global.arbitrum_balance = float(chain_balance) / float(1e18)
		4: Global.optimism_balance = float(chain_balance) / float(1e18)
	Global.balance_selector += 1
	if Global.balance_selector > 4:
		Global.balance_selector = 0
		$Log/Fuji/Balance.text = "Fuji Balance: " + String(Global.fuji_balance)
		$Log/Mumbai/Balance.text = "Mumbai Balance: " + String(Global.mumbai_balance)
		$Log/Sepolia/Balance.text = "Sepolia Balance: " + String(Global.sepolia_balance)
		$Log/Optimism/Balance.text = "OptG Balance: " + String(Global.optimism_balance)
		$Log/Arbitrum/Balance.text = "ArbG Balance: " + String(Global.arbitrum_balance)


func show_faucets():
	$Log.visible = true
	$ColorRect.color.a = 0.8

func copy_address():
	OS.set_clipboard(Global.user_address)

func open_faucet(var url):
	OS.shell_open(url)

func open_config():
	$Log/Config.visible = true
	
func save_rpc_settings():
	Global.arbitrum_rpc = $Log/Config/Arbitrum/RPC.text
	Global.mumbai_rpc = $Log/Config/Mumbai/RPC.text
	Global.optimism_rpc = $Log/Config/Optimism/RPC.text
	Global.sepolia_rpc = $Log/Config/Sepolia/RPC.text
	Global.fuji_rpc = $Log/Config/Fuji/RPC.text
	$Log/Config.visible = false

func create_pilot():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	Ccip.create_pilot(content, Global.mumbai_id, Global.mumbai_stardust, Global.mumbai_rpc, "yenn")
	file.close()

func ccip_send():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	Ccip.ccip_send(content, Global.mumbai_id, Global.mumbai_stardust, Global.mumbai_rpc, Global.fuji_selector, Global.fuji_stardust)
	file.close()

func ccip_send2():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	Ccip.ccip_send(content, Global.fuji_id, Global.fuji_stardust, Global.fuji_rpc, Global.mumbai_selector, Global.mumbai_stardust)
	file.close()


func check_pilot():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	var located = false
	Ccip.pilot_info(content, Global.mumbai_id, Global.mumbai_stardust, Global.mumbai_rpc, Global.user_address, self)
	if parse_json(Global.pilot).onChain == true:
		$Log/Pilot.text = "Mumbai"
		Global.current_chain = "Mumbai"
		located = true
	Ccip.pilot_info(content, Global.fuji_id, Global.fuji_stardust, Global.fuji_rpc, Global.user_address, self)
	if parse_json(Global.pilot).onChain == true:
		$Log/Pilot.text = "Fuji"
		Global.current_chain = "Fuji"
		located = true
	file.close()
	if located == false:
		$Log/Pilot.text = "In Transit"

func pilot_info():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	Ccip.pilot_info(content, Global.mumbai_id, Global.mumbai_stardust, Global.mumbai_rpc, Global.user_address, self)
	file.close()

#Called from Rust
func set_pilot(var _pilot):
	Global.pilot = _pilot
	


