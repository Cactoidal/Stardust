extends Control

var ship_interior = load("res://ShipInterior.tscn")

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
	$Log/Start.connect("pressed", self, "start_game")
	$Log/Refresh.connect("pressed", self, "get_balance")
	$PilotMaker/Create.connect("pressed", self, "create_pilot")
	$PilotMaker/Advanced.connect("pressed", self, "open_config")
	
	$Log/Copy.connect("pressed",self,"copy_address")
	$Log/Advanced.connect("pressed", self, "open_config")
	$Config/Arbitrum/RPC.text = Global.arbitrum_rpc
	$Config/Mumbai/RPC.text = Global.mumbai_rpc
	$Config/Optimism/RPC.text = Global.optimism_rpc
	$Config/Sepolia/RPC.text = Global.sepolia_rpc
	$Config/Fuji/RPC.text = Global.fuji_rpc
	$Config/Save.connect("pressed", self, "save_rpc_settings")
	
	
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
		3: Global.optimism_balance = float(chain_balance) / float(1e18)
		4: Global.arbitrum_balance = float(chain_balance) / float(1e18)
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
	$Config.visible = true
	
func save_rpc_settings():
	Global.arbitrum_rpc = $Config/Arbitrum/RPC.text
	Global.mumbai_rpc = $Config/Mumbai/RPC.text
	Global.optimism_rpc = $Config/Optimism/RPC.text
	Global.sepolia_rpc = $Config/Sepolia/RPC.text
	Global.fuji_rpc = $Config/Fuji/RPC.text
	$Config.visible = false
	

var gas_ok = false
var in_flight = false

func check_pilot():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	var located = false
	
	for lookup in ["Optimism", "Arbitrum", "Sepolia", "Fuji", "Mumbai"]:
		var chain = Global.get_chain_info(lookup)
		Ccip.pilot_info(content, chain["chain_id"], chain["stardust_contract"], chain["rpc"], Global.user_address, self)
		if parse_json(Global.pilot).onChain == true:
			print(lookup)
			Global.current_chain = lookup
			located = true
			gas_ok = true
			Global.available_chains.erase(lookup)
			Global.destination_chain = Global.available_chains[0]
			Global.chain_selector = 0
			#set location indicators inside ship
		
		
	if located == false:
		get_departure_time()
		if ephem_departure_time == 0:
			get_balance()
			var enabled_chains = 0
			for another_lookup in ["Optimism", "Arbitrum", "Sepolia", "Fuji", "Mumbai"]:
				if Global.get_chain_info(another_lookup)["player_balance"] > 0:
					Global.current_chain = another_lookup
					enabled_chains += 1
			if enabled_chains >= 2:
				Global.available_chains.erase(Global.current_chain)
				Global.destination_chain = Global.available_chains[0]
				Global.chain_selector = 0
				Global.create_player_pilot = true
				gas_ok = true
					
		else:
			in_flight = true
	file.close()


var ephem_departure_time = 0
var chain_check
func get_departure_time():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	for lookup in ["Optimism", "Arbitrum", "Sepolia", "Fuji", "Mumbai"]:
		var chain = Global.get_chain_info(lookup)
		chain_check = lookup
		Ccip.get_departure(content, chain["chain_id"], chain["stardust_contract"], chain["rpc"], Global.user_address, self)
	file.close()
	
#Called from Rust
func set_departure_time(var departure):
	if int(departure) > ephem_departure_time:
		ephem_departure_time = int(departure)
		Global.current_chain = chain_check


func pilot_info():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	Ccip.pilot_info(content, Global.mumbai_id, Global.mumbai_stardust, Global.mumbai_rpc, Global.user_address, self)
	file.close()

#Called from Rust
func set_pilot(var _pilot):
	Global.pilot = _pilot

func start_game():
	check_pilot()
	
	if Global.create_player_pilot == true:
		$Log.visible = false
		$PilotMaker.visible = true
		$PilotMaker/Origin.text = "Origin Chain: " + Global.current_chain
	else:
		if gas_ok == true:
			var into_ship = ship_interior.instance()
			get_parent().get_parent().add_child(into_ship)
			get_parent().queue_free()
		elif in_flight == true:
			Global.in_flight = true
			Global.start_in_warp = true
			Global.entering_port = true
			Global.entering_port_timer = -0.1
			Global.destination_chain = Global.available_chains[0]
			var into_ship = ship_interior.instance()
			get_parent().get_parent().add_child(into_ship)
			get_parent().queue_free()
		else:
			$Log/Start.text = "Get Gas On 2 Chains"

func create_pilot():
	if $PilotMaker/Name.text.length() > 0:
		var file = File.new()
		file.open("user://keystore", File.READ)
		var content = file.get_buffer(32)
		var success = Ccip.create_pilot(content, Global.get_chain_info(Global.current_chain)["chain_id"], Global.get_chain_info(Global.current_chain)["stardust_contract"], Global.get_chain_info(Global.current_chain)["rpc"], $PilotMaker/Name.text)
		file.close()
		if success:
			var into_ship = ship_interior.instance()
			get_parent().get_parent().add_child(into_ship)
			get_parent().queue_free()
		else:
			$PilotMaker/Create.text = "TX ERROR"
			


