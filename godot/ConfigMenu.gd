extends Node

var player

func _ready():
	
	$Log/Address.text = Global.user_address
	
	$Log/Back.connect("pressed",self,"close")
	$Log/Copy.connect("pressed",self,"copy_address")
	$Log/Refresh.connect("pressed", self, "get_balance")
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
	
	$Log/Fuji/Balance.text = "Fuji Balance: " + String(Global.fuji_balance)
	$Log/Mumbai/Balance.text = "Mumbai Balance: " + String(Global.mumbai_balance)
	$Log/Sepolia/Balance.text = "Sepolia Balance: " + String(Global.sepolia_balance)
	$Log/Optimism/Balance.text = "OptG Balance: " + String(Global.optimism_balance)
	$Log/Arbitrum/Balance.text = "ArbG Balance: " + String(Global.arbitrum_balance)
	
	$Log/Config/StardustAddresses/Sepolia/Address.text = Global.sepolia_stardust
	$Log/Config/StardustAddresses/Mumbai/Address.text = Global.mumbai_stardust
	$Log/Config/StardustAddresses/Fuji/Address.text = Global.fuji_stardust
	$Log/Config/StardustAddresses/Optimism/Address.text = Global.optimism_stardust
	$Log/Config/StardustAddresses/Arbitrum/Address.text = Global.arbitrum_stardust

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

func close():
	player.menu_open = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	queue_free()

func get_balance():
	Ccip.get_balance(Global.user_address, Global.fuji_rpc, self)
	Ccip.get_balance(Global.user_address, Global.mumbai_rpc, self)
	Ccip.get_balance(Global.user_address, Global.sepolia_rpc, self)
	Ccip.get_balance(Global.user_address, Global.optimism_rpc, self)
	Ccip.get_balance(Global.user_address, Global.arbitrum_rpc, self)
