extends Level

var boss_flag = false
var end_dialogue_flag = false

func _play() -> void:
	sleep(1)
	(func(): boss_defeated.connect(func(): boss_flag = true)).call_deferred()
	
	var chain: DialogueChain = DialogueChain.new_from_script("res://resources/dialogue_scripts/lucas_kalligan_text.txt")
	chain.add_callback(func(): boss_flag = true)
	start_dialogue(chain)

	while not boss_flag:
		sleep(0.1)
	
	sleep(3)
	
	chain = DialogueChain.new_from_script("res://resources/dialogue_scripts/lucas_kalligan_after.txt")
	chain.add_callback(func(): end_dialogue_flag = true)
	start_dialogue(chain)
	
	while not end_dialogue_flag:
		sleep(0.1)
