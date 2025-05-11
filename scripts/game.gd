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
#  -1. Player Sprite
#   0. Default
#   5. Enemy Bullets
#  10. Player Hitbox

# TODO list
#  [*] Add a level system
#    [*] Make bullets a child of the Level node
#    [*] Level node is abstract, levels are subclasses of the base Level node
#    [*] Level base class has all the bullet spawn/clear methods
#    [*] Level base class has enemy spawning methods
#    [ ] Level base class has dialogue starting methods
# [ ] Figure out SFX for level stuff

@export var levels: Array[PackedScene]

@onready var bullet_sfx = $BulletSoundPlayer as AudioStreamPlayer2D
@onready var enemy_death_sfx = $EnemyDeathSoundPlayer as AudioStreamPlayer2D
@onready var main_ui = $UILayer/GameplayUI as GameplayUI
@onready var pause_ui = $PauseLayer/PauseMenu as PauseMenuUI

@onready var enemy_template: PackedScene = preload("res://scenes/enemy/enemy.tscn")
@onready var item_template: PackedScene = preload("res://scenes/pickup/item.tscn")

static var _game_instance: GameController = null

enum GameState {
	MAIN_MENU,
	GAME_STARTED,
	GAME_DIALOGUE,
	GAME_PAUSED,
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

## Returns the global position of the player.
static func get_player_pos() -> Vector2:
	if not _game_instance.player_ref:
		return Vector2.ZERO
	else:
		return _game_instance.player_ref.position


## SFX Methods
static func play_enemy_death_sfx():
	_game_instance.enemy_death_sfx.stop()
	_game_instance.enemy_death_sfx.play()


func is_ingame() -> bool:
	return state == GameState.GAME_STARTED or state == GameState.GAME_DIALOGUE or state == GameState.GAME_PAUSED


func is_paused() -> bool:
	return state == GameState.GAME_PAUSED


func _ready() -> void:
	_game_instance = self
	
	main_ui.set_boss_stats(false)
	
	player_ref = get_tree().get_first_node_in_group('player')
	player_ref._game_ref = self
	player_ref.emit_stats()
	
	state = GameState.GAME_STARTED
	_last_state = state
	
	pause_ui.hide()
	
	if len(levels) > 0:
		level_thread = Thread.new()
		play_next_level()


func _process(delta: float) -> void:
	sfx_cooldown = max(0, sfx_cooldown - delta)
	
	if sfx_cooldown <= 0 and play_sfx:
		play_sfx = false
		sfx_cooldown = 0.1
		
		bullet_sfx.play()


## Pauses or unpauses the game, depending on [param paused]. True to pause, false to unpause.[br]
## Does nothing if we aren't ingame.
func set_pause(paused: bool) -> void:
	if state == GameState.GAME_STARTED or state == GameState.GAME_DIALOGUE:
		_last_state = state
		state = GameState.GAME_PAUSED
		get_tree().paused = true
		
	elif state == GameState.GAME_PAUSED:
		state = _last_state
		get_tree().paused = false

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
	
	level_ref.boss_defeated.connect(func(): main_ui.set_boss_stats(false))
	level_ref.spell_started.connect(func(spell_name, boss_name):
		main_ui.set_boss_stats(true)
		main_ui.set_boss_name(boss_name)
		main_ui.set_spell_name(spell_name)
	)
	level_ref.spell_hp_updated.connect(func(max, old, new): main_ui.set_hp(new, max))
	level_ref.spell_time_updated.connect(func(time): main_ui.set_time(time))
	level_ref.boss_phases_changed.connect(func(old, new): main_ui.set_phases(new))
	
	add_child(level_ref)
	player_ref.reparent(level_ref)
	level_thread.start(level_ref.play)


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
	# TODO: Sound Effect


func _on_player_lives_changed(old: int, new: int) -> void:
	main_ui.set_lives(new)
	# TODO: Sound Effect 


func _on_player_score_changed(old: int, new: int) -> void:
	# TODO: Add the points text when the player picks up an item
	main_ui.set_score(new)


func _on_player_flash_changed(value: int, max: int) -> void:
	main_ui.set_flash_charge(value, max)
