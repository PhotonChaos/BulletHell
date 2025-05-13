class_name SpellCard
extends Node2D
## This is a base class, it is an empty spell card.

# TODO: Add parameters for score to these signals
signal spell_started
signal spell_defeated
signal hp_changed(max: int, old: int, new: int)
signal time_changed(new: float)


@export var spell_name: String

@export_subgroup("Non-spell")
## HP of the unnamed attack before the spell.
@export var nonspell_hp: int = 2000

## Time limit of the unnamed attack before the spell.
@export_range(1, 1000) var nonspell_time_limit: int = 60

@export_subgroup("Spell")
## HP of the spell.
@export var spell_hp: int = 3500
## Time limit of the spell in seconds
@export_range(1, 1000) var spell_time_limit: int = 60

## Whether or not this is a survival spell. If true, the player cannot damage the boss, and must wait out the timer.
@export var is_timeout: bool

static var _turret_template: PackedScene = preload("res://scenes/boss_turret.tscn")

# References
var _level: Level = null
var _boss: Boss = null

# State variables
var on_spell = false
var started = false
var dying = false
var setup_complete = false

const WARMUP_DEFAULT: float = 2
var warmup_timer: float = WARMUP_DEFAULT

var hp_left: float = 0
var time_left: float = 0
## Lifetime of the attack in frames. Resets when the spell starts.
var lifetime: int = 0

####################
## Utility Functions

# TODO: Add utility functions for stuff like lifetime % something == 0

func spawn_turret(dest: Vector2, travel_time: float) -> BossTurret:
	var turret: BossTurret = _turret_template.instantiate()
	
	add_child(turret)
	
	var turretMove: Tween = get_tree().create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	turretMove.tween_property(turret, "global_position", dest, travel_time)
	
	return turret

func clear_turrets() -> void:
	for child in get_children():
		if child is BossTurret:
			child.queue_free()

####################
## Core Functions

## Damages the current attack by [param amount]
func damage(amount: int) -> void:
	hp_left -= amount if warmup_timer <= 0 else amount * (1- warmup_timer / WARMUP_DEFAULT)**3
	
	if on_spell:
		hp_changed.emit(spell_hp, hp_left+amount, hp_left)
	else: 
		hp_changed.emit(nonspell_hp, hp_left+amount, hp_left)
	
	if hp_left <= 0 and not dying:
		dying = true
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
		
	hp_changed.emit(hp_left, 0, hp_left)
	

## Custom movement function for both attacks. Called once per physics frame, before the attacks.
func movement() -> void:
	pass

## Called on the first frame of the nonspell, before [method nonspell] is called.
func nonspell_setup() -> void:
	pass

## The nonspell portion of the attack. Called once per physics frame.[br]
func nonspell() -> void:
	pass

## Called on the first frame of the spell, before [method spell] is called.
func spell_setup() -> void:
	pass
	
## The spell portion of the attack. Called once per physics frame.[br]
func spell() -> void:
	pass

## Called whenever the current step of the attack is defeated. If on a nonspell, begins the spell portion
func _defeat():
	_drop_spell_items()
	
	if on_spell:
		spell_defeated.emit()
	else:
		clear_turrets()
		time_left = spell_time_limit
		hp_left = spell_hp
		on_spell = true
		dying = false
		setup_complete = false
		lifetime = 0
		warmup_timer = WARMUP_DEFAULT
		spell_started.emit()

## Called to determine what items the attack should drop
func get_drops() -> Dictionary:
	return Item.get_drop_dict(0, 0, 0)

func _drop_spell_items() -> void:
	var items = get_drops()
	
	for itemType in [Item.ItemType.POINT, Item.ItemType.LIFE, Item.ItemType.BOMB]:
		if not itemType in items: 
			pass
		
		for i in range(items[itemType]):
			var pos = Vector2.from_angle(randf_range(0, TAU)) * randf_range(20, 40) + global_position
			var item = Item.new_item(itemType)
			item.global_position = pos
			get_parent().call_deferred("add_sibling", item)

func _physics_process(delta: float) -> void:
	if not started:
		return
	
	if not setup_complete and lifetime == 0:
		setup_complete = true
		
		if on_spell:
			spell_setup()
		else:
			nonspell_setup()
	
	if warmup_timer > 0:
		warmup_timer -= delta
		return
	
	time_left = max(0, time_left - delta)	
	time_changed.emit(time_left)
	
	movement()
	
	if on_spell:
		spell()
	else:
		nonspell()
	
	# Update lifetime after, so that it starts at zero.
	lifetime += 1

	if time_left <= 0:
		_defeat()
