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

const _sprite_map = {
	ItemType.POINT: preload("res://textures/items/point_alt.png"),
	ItemType.SMALL_POINT: preload("res://textures/items/small_point.png"),
	ItemType.LIFE: preload("res://textures/UI/heart_icon.png"),
	ItemType.BOMB: preload("res://textures/UI/bomb_icon.png")
}

const _sound_map = {
	ItemType.POINT: preload("res://audio/SFX/click(5).wav"),
	#ItemType.SMALL_POINT: preload("res://audio/SFX/click(5).wav"),  # Do not add this to the map. We handle this sound differently
	ItemType.LIFE: preload("res://audio/SFX/life_gain.wav"),
	ItemType.BOMB: preload("res://audio/SFX/bomb_gain.wav")
}

# Value of the item, depends on item type:
# [enum ItemType.POINT]: Full point value given to player.
# [enum ItemType.POWER]: Power given to player.
# [enum ItemType.SMALL_POINT]: Points given to player, not dependent on point of collection.
# In all other cases, this is not used.
#var item_value_map: Dictionary[ItemType, int]

const GRAVITY = 40
const MAX_FALL_SPEED = 120

const MAGNET_SPEED = 300

# Item values
const POINT_VALUE_FULL = 10000
const POWER_VALUE = 10
const SMALL_POINT_VALUE = 50
const BOMB_POINT_VALUE = 1000
const LIFE_POINT_VALUE = 5000

## y-coordinate of max point value
const POINT_OF_COLLECTION = 50

var magnet_player = false
var _fall_speed = 0

@onready var sprite = $Sprite2D as Sprite2D

@export var item_type: ItemType


const _item_template: PackedScene = preload("res://scenes/pickup/item.tscn")

static func get_drop_dict(points: int, bombs: int, lives: int) -> Dictionary:
	return {
		ItemType.POINT: points,
		ItemType.BOMB: bombs,
		ItemType.LIFE: lives
	}
	
static func new_item(type: ItemType):
	var item = _item_template.instantiate() as Item
	item.item_type = type
	return item

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
		player.add_points(BOMB_POINT_VALUE)
	elif item_type == ItemType.LIFE:
		player.add_lives(1)
		player.add_points(LIFE_POINT_VALUE)
		
	if item_type in _sound_map:
		var stream = AudioStreamPlayer2D.new()
		stream.stream = _sound_map[item_type]
		stream.finished.connect(func(): stream.queue_free())
		player.add_child(stream)
		stream.play()


func _physics_process(delta: float) -> void:
	if GameController.get_player_pos().y <= POINT_OF_COLLECTION:
		magnet_player = true
	
	if magnet_player:
		position += (GameController.get_player_pos() - position).normalized() * MAGNET_SPEED * delta
	else:
		_fall_speed = min(_fall_speed + 0.5 * GRAVITY * delta, MAX_FALL_SPEED)
		position += Vector2(0, _fall_speed * delta)
		_fall_speed = min(_fall_speed + 0.5 * GRAVITY * delta, MAX_FALL_SPEED)
