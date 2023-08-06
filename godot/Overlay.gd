extends Control

var user_address

var fuji_rpc = "https://avalanche-fuji-c-chain.publicnode.com"
var mumbai_rpc = "https://rpc-mumbai.maticvigil.com"
var sepolia_rpc = "https://endpoints.omniatech.io/v1/eth/sepolia/public"

var fuji_balance = "0"
var mumbai_balance = "0"
var sepolia_balance = "0"

var chain_selector = 0

func _ready():
	check_keystore()
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	user_address = Ccip.get_address(content)
	$Log/Address.text = user_address
	file.close()
	get_balance()
	$Start.connect("pressed", self, "get_balance")
	

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
