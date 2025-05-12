class_name Boss
extends Area2D
## Base class for a Boss. Subclass this for special behaviour![br]
## Just load this up with spell cards if you don't need anything fancy

## Emits when the boss runs out of spell cards
signal boss_defeated

## Name will be empty if it's a nonspell
signal spell_card_started(name: String)

## Emits when the current spell card or nonspell has been defeated
signal phase_defeated(was_spell_card: bool)

## Emits when the spell card health changes
signal spell_hp_changed(max: int, old: int, new: int)

## Emits when the spell card time changes
signal spell_time_changed(new: int)

signal phases_left_changed(old: int, new: int)

## The name that displays in dialogue and under the bosses health bar 
@export var boss_name: String

## The title of the boss that displays during dialogue
@export var boss_title: String

## When the boss should be immune to bomb damage
@export var bomb_immunity: BombImmunityLevel = BombImmunityLevel.NONE

## The music that plays in the background over the boss fight
@export var boss_theme: BGMAudio

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

const MOVEMENT_LEFT_BOUND: float = 40.0
const MOVEMENT_RIGHT_BOUND: float = 320

var _level: Level = null

## Spell Handling

var current_spell: SpellCard = null
var current_spell_index: int = -1;

## End of Spell Handling

## Movement Handling

class MovementDest:
	var target: Vector2
	var move_time: float
	var start_wait_time: float 
	var end_wait_time: float 
	var easing: Callable
	
	var _move_time_counter: float = 0
	
	func _init(_target: Vector2, _move_time: float, _start_wait_time: float, _end_wait_time: float, _easing: Callable = ease_in_out) -> void:
		target = _target
		move_time = _move_time
		start_wait_time = _start_wait_time
		end_wait_time = _end_wait_time
		easing = _easing
	
	## Produces the value that should be passed into movement lerp according to the easing function.
	func get_lerp_value() -> float:
		return easing.call(_move_time_counter / move_time)
	
	## Adds moved time to the 
	func add_move_time(time: float) -> void:
		_move_time_counter = min(move_time, _move_time_counter + time)
	
	## Consumes 0 <= [param x] <= 1 and produces a value in the range [0,1].[br]
	## Translates a percentage of move time into a linear easing curve.
	static func linear(x: float) -> float:
		return x
	
	## Consumes 0 <= [param x] <= 1 and produces a value in the range [0,1].[br]
	## Translates a percentage of move time into a quadratic easing curve.
	static func quadratic(x: float) -> float:
		return x*x
		
	## Consumes 0 <= [param x] <= 1 and produces a value in the range [0,1].[br]
	## Represents a curve that slows down as [param x] appproaches 1
	static func ease_out(x: float) -> float:
		return sin(PI*0.5*x)
	
	## Consumes 0 <= [param x] <= 1 and produces a value in the range [0,1].[br]
	## Represents a curve that slows down as [param x] appproaches 1
	static func ease_in_out(x: float) -> float:
		return 0.5*sin(PI*(x-0.5))+0.5


## Queue for the boss to move in
var move_queue: Array[MovementDest] = []
var _move_time: float = 0
## End of Movement Handling

## Returns true if the boss should not be harmed by bombs this frame
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


## Moves the boss to [param destination] over the course of [param move_duration] seconds.[br]
## Eases in and out for movement.
func move_to(destination: Vector2, move_duration: float, start_delay: float, end_delay: float) -> void:
	move_queue.push_back(MovementDest.new(destination, move_duration, start_delay, end_delay))

func clear_move_queue() -> void:
	move_queue.clear()

func damage(amount: int) -> void:
	if _level._bomb_active and is_bomb_immune():
		return
		
	current_spell.damage(amount)

## Ends the current spell and begins the next one
func next_spell() -> void:
	if current_spell != null:
		current_spell.queue_free()
	
	current_spell_index += 1
	
	phases_left_changed.emit(0, len(spell_cards)-current_spell_index-1)

	
	if current_spell_index >= len(spell_cards):
		boss_defeated.emit()
		queue_free()
		return
	
	current_spell = spell_cards[current_spell_index].instantiate()
	
	current_spell.spell_started.connect(func(): defeat_phase(false))
	current_spell.spell_defeated.connect(func(): defeat_phase(true))
	
	current_spell.hp_changed.connect(func(max: int, old: int, new: int): spell_hp_changed.emit(max, old, new))
	current_spell.time_changed.connect(func(new: float): spell_time_changed.emit(new))
	
	add_child(current_spell)
	
	spell_card_started.emit("")
	
	current_spell.start(_level)


func defeat_phase(card: bool) -> void:
	phase_defeated.emit(card)
	_level.clear_bullet_wave(global_position, 1, true, true)
	
	if card:
		next_spell()
	else:
		spell_card_started.emit(current_spell.spell_name)

func _ready() -> void:
	area_entered.connect(_on_hitbox_entered)
	next_spell()

func _physics_process(delta: float) -> void:
	if len(move_queue) > 0:
		var dest = move_queue[0]
		if dest.start_wait_time > 0:
			dest.start_wait_time -= delta
			return
		elif dest.get_lerp_value() < 1:
			dest.add_move_time(delta)
			position = position.lerp(dest.target, dest.get_lerp_value())
		elif dest.end_wait_time > 0:
			dest.end_wait_time -= delta
		else:
			move_queue.pop_front()

func _on_hitbox_entered(area: Area2D) -> void:
	if area is PlayerShot and current_spell.started:
		area.queue_free()
		damage((area as PlayerShot).damage)
