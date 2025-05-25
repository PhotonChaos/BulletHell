class_name GameController
extends Node2D

# Collision Layers:
#  1. Player rigidbody
#  2. Bullets, enemies, bosses
#  3. Player shots
#  4. Powerups

# Sprite Layers (lower is further back):
#  -5. Player/Boss Death Wave
#  -4. Bomb Sprite
#  -3. Flash Bomb Sprite
#  -2. Player Shots
#  -1. Boss Sprite
#   0. Default (Player Sprite Here)
#   5. Enemy Bullets
#  10. Player Hitbox

# TODO list
# [ ] Level base class has dialogue starting methods
# [ ] Figure out SFX for level stuff

@export var levels: Array[PackedScene]

@onready var bullet_sfx = $BulletSoundPlayer as AudioStreamPlayer2D
@onready var enemy_death_sfx = $EnemyDeathSoundPlayer as AudioStreamPlayer2D
@onready var boss_death_sfx = $BossDeathSoundPlayer as AudioStreamPlayer2D
@onready var game_bgm: AudioStreamPlayer = $GameBGM
@onready var main_ui = $UILayer/GameplayUI as GameplayUI
@onready var pause_ui = $PauseLayer/PauseMenu as PauseMenuUI
@onready var game_over_ui = $GameOverLayer/GameOverMenu as GameOverMenu
@onready var results_ui = $ScoreSummaryLayer/EndScoreScreen as EndScoreScreen

@onready var enemy_template: PackedScene = preload("res://scenes/enemy/enemy.tscn")
@onready var item_template: PackedScene = preload("res://scenes/pickup/item.tscn")

@onready var _sfx_boss_phase_defeat = preload("res://audio/SFX/boss_beat.wav") as AudioStreamWAV
@onready var _sfx_boss_full_defeat  = preload("res://audio/SFX/boss_full_kill.wav") as AudioStreamWAV

static var _game_instance: GameController = null

enum GameState {
	MAIN_MENU,
	GAME_STARTED,
	GAME_DIALOGUE,
	GAME_PAUSED,
	GAME_OVER,
	RESULTS_SCREEN,
	END_CREDITS
}

var state: GameState = GameState.MAIN_MENU

## Only used for pausing. Do not use this anywhere else
var _last_state: GameState = state

var play_sfx: bool = false
var sfx_cooldown: float = 0

var current_level: int = -1
var level_ref: Level = null
var player_ref: Player = null
var level_thread: Thread = null

var dialogue_chain: DialogueChain = null
var dialogue_pause: bool = false

## Returns the global position of the player.
static func get_player_pos() -> Vector2:
	if not _game_instance.player_ref:
		return Vector2.ZERO
	else:
		return _game_instance.player_ref.position


## Dialogue UI Methods

static func open_dialogue(chain: DialogueChain):
	_game_instance.call_deferred("_open_dialogue", chain)


static func close_dialogue():
	_game_instance.call_deferred("_close_dialogue")
	

## Runs the next link in the dialogue chain. Keeps running links until it runs a text link.
func _advance_dialogue():
	var result = dialogue_chain.run_next_link()
	
	while result == DialogueChain.DIALOGUE_EVENT or result == DialogueChain.DIALOGUE_CALLBACK:
		result = dialogue_chain.run_next_link()
	
	if result == "":
		_close_dialogue()


func _open_dialogue(chain: DialogueChain):
	state = GameState.GAME_DIALOGUE
	dialogue_chain = chain
	dialogue_chain.new_text.connect(main_ui.dialogue_line)
	main_ui.show_dialogue().tween_callback(_advance_dialogue)

	
func _close_dialogue():
	state = GameState.GAME_STARTED
	dialogue_chain = null
	main_ui.hide_dialogue()



## SFX Methods
static func play_enemy_death_sfx():
	_game_instance.enemy_death_sfx.stop()
	_game_instance.enemy_death_sfx.play()


static func update_boss_pos(boss_x: float, boss_width: float):
	_game_instance.main_ui.set_boss_pos(boss_x, boss_width)


func play_boss_death_sfx(full_kill: bool) -> void:
	if full_kill:
		boss_death_sfx.stream = _sfx_boss_full_defeat
	else:
		boss_death_sfx.stream = _sfx_boss_phase_defeat
		
	boss_death_sfx.play()


func play_bgm(song: BGMAudio) -> void:
	if not song:
		print("Tried to play null song.")
		return
	
	main_ui.show_bgm_credit(song.artist, song.song_name)
	game_bgm.stream = song.audio
	game_bgm.play()

## Info methods

func is_ingame() -> bool:
	return state == GameState.GAME_STARTED or state == GameState.GAME_DIALOGUE or state == GameState.GAME_PAUSED


func is_paused() -> bool:
	return state == GameState.GAME_PAUSED


## Standard Methods
func _ready() -> void:
	print(OS.get_thread_caller_id())
	_game_instance = self
	
	main_ui.set_boss_stats(false)
	
	player_ref = get_tree().get_first_node_in_group('player')
	player_ref._game_ref = self
	player_ref.emit_stats()
	
	state = GameState.GAME_STARTED
	_last_state = state
	
	pause_ui.hide()
	game_over_ui.hide()
	results_ui.hide()
	
	game_bgm.finished.connect(func(): game_bgm.play())
	
	if len(levels) > 0:
		level_thread = Thread.new()
		play_next_level()


func _process(delta: float) -> void:
	sfx_cooldown = max(0, sfx_cooldown - delta)
	
	if sfx_cooldown <= 0 and play_sfx:
		play_sfx = false
		sfx_cooldown = 0.1
		
		bullet_sfx.play()
		
	if state == GameState.GAME_DIALOGUE and Input.is_action_just_pressed("primary") and not dialogue_pause:
		_advance_dialogue()


## Pauses or unpauses the game, depending on [param paused]. True to pause, false to unpause.[br]
## Sets the game state to [enum GameState.GAME_PAUSED]. 
func set_pause(paused: bool) -> void:
	if state == GameState.GAME_PAUSED:
		state = _last_state
		get_tree().paused = false
	else:
		_last_state = state
		state = GameState.GAME_PAUSED
		get_tree().paused = true

func play_next_level() -> void:
	current_level += 1
	
	# Destroy current level
	if level_ref:
		player_ref.reparent(self)
		level_ref.queue_free()
	
	# Construct next level
	level_ref = levels[current_level].instantiate()
	
	level_ref.setup(player_ref)
	
	# Connect signals
	level_ref.level_finished.connect(_on_level_finished)
	level_ref.bullet_fired.connect(_on_bullet_fired)
	level_ref.bgm_changed.connect(play_bgm)
	level_ref.dialogue_started.connect(GameController.open_dialogue)
	level_ref.dialogue_controls.connect(func(paused): dialogue_pause = paused)
	
	level_ref.boss_defeated.connect(func(): 
		main_ui.set_boss_stats(false)
		play_boss_death_sfx(true)
		
		state = GameState.RESULTS_SCREEN
		
		get_tree().create_timer(3).timeout.connect(func():
			results_ui.show()
			results_ui.end_transition(player_ref._lives, player_ref._bombs, 0, player_ref.score)
			player_ref.add_points(results_ui.calculate_bonus(player_ref._lives, player_ref._bombs, 0))
		)
	)
	level_ref.boss_defeated.connect(func(): game_bgm.stop())
	
	level_ref.spell_started.connect(func(spell_name, boss_name):
		main_ui.set_boss_stats(true)
		main_ui.set_boss_name(boss_name)
		main_ui.set_spell_name(spell_name)
	)
	level_ref.spell_hp_updated.connect(func(max, old, new): main_ui.set_hp(new, max))
	level_ref.spell_time_updated.connect(func(time): main_ui.set_time(time))
	level_ref.boss_phases_changed.connect(func(old, new): main_ui.set_phases(new))
	level_ref.boss_phase_defeated.connect(func(): play_boss_death_sfx(false))
	
	add_child(level_ref)
	player_ref.reparent(level_ref)
	level_thread.start(level_ref.play)

## Instantly restarts the game.
func restart_game() -> void:
	if player_ref.get_parent() != self:
		player_ref.reparent(self)
		
	_game_instance = null
	get_tree().paused = false
	get_tree().reload_current_scene()

################
# Event Methods
#

func _on_bullet_fired() -> void:
	play_sfx = true


func _on_level_finished() -> void:
	if current_level + 1 == len(levels):
		print_rich("[color=green][b]You Win!!!![/b][/color]")
	else:
		play_next_level()


func _on_bullet_bounds_area_exited(area: Area2D) -> void:
	# Triggers whenever a bullet exits the area
	# TODO: Figure out how this works with object pooling
	area.queue_free()  # Only bullets and enemies should be on layer 2


func _on_player_bombs_changed(old: int, new: int) -> void:
	main_ui.set_bombs(new)


func _on_player_lives_changed(old: int, new: int) -> void:
	if new <= 0:
		set_pause(true)
		state = GameState.GAME_OVER
		game_over_ui.show()
	
	main_ui.set_lives(new-1)


func _on_player_score_changed(old: int, new: int) -> void:
	# TODO: Add the points text when the player picks up an item
	main_ui.set_score(new)

func _on_player_high_score_changed(old: int, new: int) -> void:
	main_ui.set_high_score(new)

func _on_player_flash_changed(value: int, max: int) -> void:
	main_ui.set_flash_charge(value, max)


func _on_game_over_menu_restart() -> void:
	game_over_ui.hide()
	set_pause(false)
	call_deferred("restart_game")
	

func _on_end_score_screen_restart() -> void:
	call_deferred("restart_game")
