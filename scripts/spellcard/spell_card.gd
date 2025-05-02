class_name SpellCard
extends Node2D
## This is a base class, it is an empty spell card.

# TODO: Add parameters for score to these signals
signal spell_started
signal spell_defeated
signal hp_changed(old: int, new: int)

@export var spell_name: String

@export_subgroup("Non-spell")
## HP of the unnamed attack before the spell.
@export var nonspell_hp: int

## Time limit of the unnamed attack before the spell.
@export_range(1, 1000) var nonspell_time_limit: int

@export_subgroup("Spell")
## HP of the spell.
@export var spell_hp: int
## Time limit of the spell in seconds
@export_range(1, 1000) var spell_time_limit: int

## Whether or not this is a survival spell. If true, the player cannot damage the boss, and must wait out the timer.
@export var is_timeout: bool

# References
var _level: Level = null
var _boss: Boss = null

# State variables
var on_spell = false
var started = false

var hp_left: float = 0
var time_left: float = 0
## Lifetime of the attack in frames. Resets when the spell starts.
var lifetime: int = 0

####################
## Utility Functions

# TODO: Add these

####################
## Core Functions

## Damages the current attack by [param amount]
func damage(amount: int) -> void:
	hp_left -= amount
	
	hp_changed.emit(hp_left+amount, hp_left)
	
	if hp_left <= 0:
		_defeat()


## Begins the spell. Starts with nonspell portion, then will switch to the spell portion automatically
func start(level: Level) -> void:
	_level = level
	_boss = get_parent() as Boss
	started = true
	
	if nonspell_hp > 0 and nonspell_time_limit > 0:
		hp_left = nonspell_hp
		time_left = nonspell_time_limit
	else:
		hp_left = spell_hp
		time_left = spell_time_limit
		on_spell = true
	

## The nonspell portion of the attack. Called once per physics frame.
func nonspell() -> void:
	pass

## The spell portion of the attack. Called once per physics frame.
func spell() -> void:
	pass

## Called whenever the current step of the attack is defeated. If on a nonspell, begins the spell portion
func _defeat():	
	if on_spell:
		spell_defeated.emit()
	else:
		_level.clear_all_bullets(true)
		time_left = spell_time_limit
		hp_left = spell_hp
		on_spell = true
		lifetime = 0
		
		spell_started.emit()


func _physics_process(delta: float) -> void:
	if not started:
		return
		
	time_left -= delta
	lifetime += 1
	
	if on_spell:
		spell()
	else:
		nonspell()
		
	if time_left <= 0:
		_defeat()
