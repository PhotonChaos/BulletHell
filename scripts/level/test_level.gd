extends Level

var boss_flag = false
var end_dialogue_flag = false

func _build_level() -> void:
	sleep(2)
	var chain = DialogueChain.new().add_link("L", "skibidi", "none", "Hello there nerdass")
	chain.add_link("L", "skibidi", "none", "Hello there nerdass2")
	chain.add_link("L", "skibidi", "none", "Hello there nerdass3")
	chain.add_link("L", "skibidi", "none", "Hello there nerdass4")
	chain.add_callback(open_gate)
	start_dialogue(chain)
	lock_gate()
	
	spawn_boss("crystal_boss", BOSS_DEFAULT_POSITION, BOSS_OFFSCREEN_POSITION)
	sleep(3)
	add_script_func(func(): _boss_ref.call_deferred("start"))
	lock_gate()
	sleep(10000)
