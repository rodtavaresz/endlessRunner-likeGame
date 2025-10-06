extends Node2D

@export var player_path: NodePath
@export var floor_tilemap_path: NodePath
@export var powerups: Array[PackedScene] = []

@export var spawn_ahead_px: int = 800
@export var min_gap_px: int = 900
@export var rand_gap_px: int = 700
@export var chance: float = 0.2         
@export var y_offset: int = -72            
@export var cleanup_back_px: int = 700

var player: Node2D
var ground_y: float = 0.0
var last_spawn_x: int = 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_resolve_player()
	ground_y = _resolve_ground_y()

	if player:
		last_spawn_x = int(player.global_position.x)
	else:
		last_spawn_x = int(global_position.x)
		
		call_deferred("_resolve_player")

func _physics_process(_delta: float) -> void:
	if get_tree().paused or powerups.is_empty():
		return

	if not player:
		_resolve_player()
		return

	_cleanup_old()

	var px := int(player.global_position.x)
	var next_x := last_spawn_x + min_gap_px + rng.randi_range(0, rand_gap_px)

	if px + spawn_ahead_px >= next_x:
		last_spawn_x = next_x
		if rng.randf() < chance:
			
			_spawn_powerup(next_x)

func _spawn_powerup(xpos: int) -> void:
	var scene: PackedScene = powerups.pick_random()
	var node := scene.instantiate() as Node2D
	add_child(node)

	
	var ox := 0.0
	var oy := 0.0
	if "spawn_x_offset" in node:
		ox = float(node.spawn_x_offset)
	if "spawn_y_offset" in node:
		oy = float(node.spawn_y_offset)

	var y := ground_y + float(y_offset) + oy
	node.global_position = Vector2(xpos + ox, y)

func _cleanup_old() -> void:
	var cutoff := player.global_position.x - float(cleanup_back_px)
	for c in get_children():
		if c is Node2D and c.global_position.x < cutoff:
			c.queue_free()

func _resolve_player() -> void:
	if is_instance_valid(player):
		return

	if player_path != NodePath(""):
		player = get_node_or_null(player_path) as Node2D
		if player:
			return

	var by_group := get_tree().get_nodes_in_group("player")
	if by_group.size() > 0:
		player = by_group[0] as Node2D
		return

	var p := get_node_or_null("../CharacterBody2D") as Node2D
	if p:
		player = p
		return

func _resolve_ground_y() -> float:
	var tm := get_node_or_null(floor_tilemap_path) as TileMap
	if tm:
		return _top_of_ground_y(tm)

	var ground := get_node_or_null("../Ground")
	if ground:
		var t := _find_first_tilemap(ground)
		if t:
			return _top_of_ground_y(t)

	var marker := get_node_or_null("../GroundY") as Marker2D
	if marker:
		return marker.global_position.y

	return global_position.y

func _find_first_tilemap(n: Node) -> TileMap:
	if n is TileMap:
		return n
	for c in n.get_children():
		var t := _find_first_tilemap(c)
		if t:
			return t
	return null

func _top_of_ground_y(tm: TileMap) -> float:
	var used: Rect2i = tm.get_used_rect()
	var cs: Vector2i = tm.tile_set.tile_size
	var top_cell: Vector2i = used.position
	var top_left_local: Vector2 = tm.map_to_local(top_cell) - cs * 0.5
	var top_world: Vector2 = tm.to_global(top_left_local)
	return round(top_world.y)
