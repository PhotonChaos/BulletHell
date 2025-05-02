class_name Boss
extends Area2D
## Base class for a Boss. Subclass this for special behaviour![br]
## Just load this up with spell cards if you don't need anything fancy

## Emits when the boss runs out of spell cards
signal boss_defeated

signal spell_card_started(name: String)

## Emits when the current spell card has been defeated
signal spell_card_defeated

## Emits when the spell card health changes
signal spell_hp_changed(max: int, old: int, new: int)

## Emits when the spell card time changes
signal spell_time_changed(new: int)

## The name that displays in dialogue and under the bosses health bar 
@export var boss_name: String

## The title of the boss that displays during dialogue
@export var boss_title: String

## The attacks that the boss uses. Using int as a placeholder for the nodes
@export var spell_cards: Array[PackedScene]

var _level: Level = null

## Spell Handling

var current_spell: SpellCard = null
var current_spell_index: int = -1;

## End of Spell Handling


## Ends the current spell and begins the next one
func next_spell() -> void:
	if current_spell != null:
		current_spell.queue_free()
	
	current_spell_index += 1
	
	if current_spell_index >= len(spell_cards):
		boss_defeated.emit()
		queue_free()
		return
	
	current_spell = spell_cards[current_spell_index].instantiate()
	current_spell.spell_defeated.connect(next_spell)
	current_spell.hp_changed.connect(func(max: int, old: int, new: int): spell_hp_changed.emit(max, old, new))
	current_spell.time_changed.connect(func(new: float): spell_time_changed.emit(new))
	add_child(current_spell)
	
	spell_card_started.emit(current_spell.spell_name)
	
	current_spell.start(_level)
	

## Moves the boss to [param destination] over the course of [param move_duration] seconds.[br]
## Eases in and out for movement.
func move_to(destination: Vector2, move_duration: float) -> void:
	# TODO: Implement this.
	pass


func _ready() -> void:
	area_entered.connect(_on_hitbox_entered)
	next_spell()
	


func _on_hitbox_entered(area: Area2D) -> void:
	if area is PlayerShot and current_spell.started:
		area.queue_free()
		current_spell.damage((area as PlayerShot).damage)
