class_name Enemy 
extends Node2D

signal die

## Called every enemy tick. Function of type Callable(age: int, pos: Vector2, level: Level)
var tick_func: Callable = Callable()

## Called when the enemy dies. Function of type Callable(age: int, pos: Vector2, level: Level)
var death_func: Callable = Callable()

## Lerp stuff
var destination: Vector2 = Vector2.ZERO
var target_dest: bool = true
var interp_time: float = 2.0

## Time in seconds between calls of the [method Enemy.tick] method
var tick_duration: float = 0
var _tick_counter: float = 0

# Dependency injection for the callables
var _lifetime: float
var _level_ref: Level = null

var _start_pos: Vector2

func _ready() -> void:
	_lifetime = 0
	_start_pos = position
	
	if _level_ref == null:
		print_rich("[color=red]ERROR: Enemy spawned with no level reference![/color]")

func _physics_process(delta: float) -> void:
	_lifetime += delta
	
	if tick_duration > 0:
		_tick_counter += delta
	
	if _tick_counter >= tick_duration:
		_tick_counter -= tick_duration
		tick()
		
	if target_dest:
		position = _start_pos.lerp(destination, clamp(_lifetime / interp_time, 0, 1))

		if _lifetime >= interp_time:
			position = destination
			target_dest = false

## Called in the _process method. [param age] is the amount of time since the enemy was spawned.
func tick():
	if tick_func.get_argument_count() > 0:
		tick_func.call(_lifetime, global_position, _level_ref)


## Called once when the enemy dies
func death():
	if death_func:
		death_func.call(_lifetime, global_position, _level_ref)


func _on_killable_dead() -> void:
	death()
	die.emit()
	
	GameController.play_enemy_death_sfx()
	_level_ref.spawn_item(global_position, Item.ItemType.POINT)
	
	queue_free()
