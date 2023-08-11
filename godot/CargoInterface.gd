extends Control

var anodyne_amount = 0
var tech_amount = 0
var contraband_amount = 0

var hold_size = 0
var money = 0

var valid = true


func _ready():
	if Global.start_in_warp == true:
		$HoldUsed.visible = false
		$MoneySpent.visible = false
	Global.cargo_console = self
	money = parse_json(Global.pilot)["coinBalance"].hex_to_int()
	hold_size = parse_json(Global.pilot)["holdSize"].hex_to_int()
	
	# to handle newly created pilots
	if money == 0:
		money = 50
	if hold_size == 0:
		hold_size = 100
		
	$MoneySpent/Amount.text = "0 / " + String(money)
	$HoldUsed/Amount.text = "0 / " + String(hold_size)

func update_numbers():
	valid = true
	var space_taken = (anodyne_amount + tech_amount + contraband_amount) * 10
	var current_spend = (tech_amount * 5) + (contraband_amount * 10)
	$MoneySpent/Amount.text = String(current_spend) + " / " + String(money)
	$HoldUsed/Amount.text = String(space_taken) + " / " + String(hold_size)
	if space_taken > hold_size:
		$HoldUsed/Amount.add_color_override("font_color", Color(1,0,0))
		valid = false
	else:
		$HoldUsed/Amount.add_color_override("font_color", Color(1,1,1))
	if current_spend > money:
		$MoneySpent/Amount.add_color_override("font_color", Color(1,0,0))
		valid = false
	else:
		$MoneySpent/Amount.add_color_override("font_color", Color(1,1,1))

func anodyne():
	anodyne_amount += 1
	if anodyne_amount >= 10:
		anodyne_amount = 0
	$AnodyneAmount.text = String(anodyne_amount)
	update_numbers()

func tech():
	tech_amount += 1
	if tech_amount >= 10:
		tech_amount = 0
	$TechAmount.text = String(tech_amount)
	update_numbers()

func contraband():
	contraband_amount += 1
	if contraband_amount >= 10:
		contraband_amount = 0
	$ContrabandAmount.text = String(contraband_amount)
	update_numbers()

func create_manifest():
	var file = File.new()
	var bytes = Crypto.new()
	var salt = String(bytes.generate_random_bytes(32)).sha256_text()
	file.open("user://manifest", File.WRITE)
	file.store_var([salt, String(anodyne_amount), String(tech_amount), String(contraband_amount)])
	file.close()
	var cargo = salt + "00" + String(anodyne_amount) + "00" + String(tech_amount) + "00" + String(contraband_amount)
	return cargo


func read_manifest():
	var file = File.new()
	file.open("user://manifest", File.READ)
	var content = file.get_var()
	file.close()
	return content

func update_money():
	money = parse_json(Global.pilot)["coinBalance"].hex_to_int()
	$HoldUsed.visible = true
	$MoneySpent.visible = true
	update_numbers()
