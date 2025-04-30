class_name SpellCard
extends Node2D
## This is a base class, it is an empty spell card.

# TODO: Add parameters for score to these signals
signal spell_started
signal spell_defeated

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

var on_spell = false

var time_left: float = 0

func damage(amount: int) -> void:
	spell_hp -= amount
	
	if spell_hp <= 0:
		if on_spell:
			_defeat()
		else:
			spell_started.emit()
			on_spell = true
		

func _defeat():
	spell_defeated.emit()
	queue_free()
	

## Begins the spell. Starts with nonspell portion, then will switch to the spell portion automatically
func start(level: Level) -> void:
	time_left = nonspell_time_limit

## The nonspell portion of the attack
func _nonspell() -> void:
	pass

func _spell() -> void:
	pass

func _process(delta: float) -> void:
	time_left -= delta
	
	if time_left <= 0:
		if on_spell:
			_defeat()
			return
		else:
			spell_started.emit()
			on_spell = true
		
