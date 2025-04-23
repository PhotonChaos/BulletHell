class_name Item
extends Area2D

## Type of powerup the item is
enum ItemType {
	 POINT = 0,
	 POWER,
	 SMALL_POINT,
	 BOMB,
	 LIFE,
	 FULL_POWER
}

var _sprite_map = {
	ItemType.POINT: preload("res://textures/items/point.png"),
	ItemType.SMALL_POINT: preload("res://textures/items/small_point.png")
}

# Value of the item, depends on item type:
# [enum ItemType.POINT]: Full point value given to player.
# [enum ItemType.POWER]: Power given to player.
# [enum ItemType.SMALL_POINT]: Points given to player, not dependent on point of collection.
# In all other cases, this is not used.
#var item_value_map: Dictionary[ItemType, int]

const GRAVITY = 20
const MAX_FALL_SPEED = 50

const MAGNET_SPEED = 300

# Item values
const POINT_VALUE_FULL = 10000
const POWER_VALUE = 10
const SMALL_POINT_VALUE = 50

## y-coordinate of max point value
const POINT_OF_COLLECTION = 50

var magnet_player = false
var _fall_speed = 0

@onready var sprite = $Sprite2D as Sprite2D

@export var item_type: ItemType


func _ready() -> void:
	if item_type in _sprite_map:
		sprite.texture = _sprite_map[item_type]


func apply(player: Player) -> void:
	if item_type == ItemType.POINT:
		var max_poc_dist = get_viewport_rect().size.y - POINT_OF_COLLECTION
		var poc_dist = player.global_position.y - POINT_OF_COLLECTION
		var percent = clamp(1 - (poc_dist / max_poc_dist), 0.2, 1)
		player.add_points(ceil(POINT_VALUE_FULL * percent))
	elif item_type == ItemType.SMALL_POINT:
		player.add_points(SMALL_POINT_VALUE)
	elif item_type == ItemType.BOMB:
		player.add_bombs(1)
	elif item_type == ItemType.LIFE:
		player.add_lives(1)

func _physics_process(delta: float) -> void:
	if GameController.get_player_pos().y <= POINT_OF_COLLECTION:
		magnet_player = true
	
	if magnet_player:
		position += (GameController.get_player_pos() - position).normalized() * MAGNET_SPEED * delta
	else:
		_fall_speed = min(_fall_speed + 0.5 * GRAVITY * delta, MAX_FALL_SPEED)
		position += Vector2(0, _fall_speed * delta)
		_fall_speed = min(_fall_speed + 0.5 * GRAVITY * delta, MAX_FALL_SPEED)
