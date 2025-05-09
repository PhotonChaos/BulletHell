class_name Boss
extends Area2D
## Base class for a Boss. Subclass this for special behaviour![br]
## Just load this up with spell cards if you don't need anything fancy

## Emits when the boss runs out of spell cards
signal boss_defeated

signal spell_card_started(name: String)

## Emits when the current spell card or nonspell has been defeated
signal phase_defeated(was_spell_card: bool)

## Emits when the spell card health changes
signal spell_hp_changed(max: int, old: int, new: int)

## Emits when the spell card time changes
signal spell_time_changed(new: int)


## The name that displays in dialogue and under the bosses health bar 
@export var boss_name: String

## The title of the boss that displays during dialogue
@export var boss_title: String

## When the boss should be immune to bomb damage
@export var bomb_immunity: BombImmunityLevel = BombImmunityLevel.NONE

## The attacks that the boss uses. Using int as a placeholder for the nodes
@export var spell_cards: Array[PackedScene]


enum BombImmunityLevel { ## The level of immunity a boss has to damage while a bomb is active (when not on a timeout spell)
	## Bombs will always damage the boss
	NONE = 0,
	## Bombs cannot damage the boss on their last spell card
	LAST_SPELL_ONLY, 
	## Bombs cannot damage the boss during spells, but can during nonspells
	SPELLS_ONLY, 
	 ## The boss cannot ever be damaged by bombs
	TOTAL
}

var _level: Level = null

## Spell Handling

var current_spell: SpellCard = null
var current_spell_index: int = -1;

## End of Spell Handling

func is_bomb_immune() -> bool:
	if bomb_immunity == BombImmunityLevel.NONE:
		return false
	elif bomb_immunity == BombImmunityLevel.LAST_SPELL_ONLY:
		return current_spell_index == len(spell_cards) - 1
	elif bomb_immunity == BombImmunityLevel.SPELLS_ONLY:
		return current_spell.on_spell
	elif bomb_immunity == BombImmunityLevel.TOTAL:
		return true
	else:
		return false


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
	current_spell.spell_defeated.connect(func(): phase_defeated.emit(true))
	current_spell.spell_defeated.connect(func(): _level.clear_bullet_wave(global_position, 2, true, true))
	current_spell.spell_started.connect(func(): phase_defeated.emit(false))
	current_spell.spell_started.connect(func(): _level.clear_bullet_wave(global_position, 1, true, true))
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


func damage(amount: int) -> void:
	if _level._bomb_active and is_bomb_immune():
		return
		
	current_spell.damage(amount)

func _ready() -> void:
	area_entered.connect(_on_hitbox_entered)
	next_spell()
	


func _on_hitbox_entered(area: Area2D) -> void:
	if area is PlayerShot and current_spell.started:
		area.queue_free()
		damage((area as PlayerShot).damage)
