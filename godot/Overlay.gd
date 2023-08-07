extends Control

var user_address

var fuji_rpc = "https://avalanche-fuji-c-chain.publicnode.com"
var mumbai_rpc = "https://rpc-mumbai.maticvigil.com"
var sepolia_rpc = "https://endpoints.omniatech.io/v1/eth/sepolia/public"

var fuji_balance = "0"
var mumbai_balance = "0"
var sepolia_balance = "0"

var chain_selector = 0

var fuji_stardust = "0x091ec5F9c7d12DfCa9468f662e2f395Cb9656c75"
var mumbai_stardust = "0xF0c3F3Ef23ACF07764e42342e85eE248A9bEd081"
var sepolia_stardust

var fuji_id = 43113
var mumbai_id = 80001
var sepolia_id = 11155111

var fuji_selector = "CCF0A31A221F3C9B"
var mumbai_selector = "ADECC60412CE25A5"
var sepolia_selector = "DE41BA4FC9D91AD9"

func _ready():
	check_keystore()
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	user_address = Ccip.get_address(content)
	$Log/Address.text = user_address
	file.close()
	get_balance()
	#$Start.connect("pressed", self, "get_balance")
	$Start.connect("pressed", self, "create_pilot")
	$Network.connect("pressed", self, "ccip_send")
	

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


# Called from Rust
func set_balance(var chain_balance):
	match chain_selector:
		0: fuji_balance = chain_balance
		1: mumbai_balance = chain_balance
		2: sepolia_balance = chain_balance
	chain_selector += 1
	if chain_selector > 2:
		chain_selector = 0
		$Log/Fuji.text = "Fuji Balance: " + String(fuji_balance)
		$Log/Mumbai.text = "Mumbai Balance: " + String(mumbai_balance)
		$Log/Sepolia.text = "Sepolia Balance: " + String(sepolia_balance)


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
