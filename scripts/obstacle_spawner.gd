extends Node2D

@export var player_path: NodePath
@export var floor_tilemap_path: NodePath
@export var obstacles: Array[PackedScene] = []

@export var spawn_ahead_px: int = 900
@export var min_gap_px: int = 360
@export var rand_gap_px: int = 280
@export var max_on_screen: int = 6
@export var y_offset: int = -50
@export_range(0.0, 1.0, 0.01) var spawn_chance: float = 0.7
@export var cleanup_back_px: int = 700

var player: Node2D
var ground_y: float = 0.0
var last_spawn_x: int = 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    if player_path == NodePath(""):
        player = get_node("../CharacterBody2D") as Node2D
    else:
        player = get_node(player_path) as Node2D
    rng.randomize()
    ground_y = _resolve_ground_y()
    last_spawn_x = int(player.global_position.x)

func _physics_process(_delta: float) -> void:
    if get_tree().paused:
        return
    _cleanup_old()
    if _count_alive() >= max_on_screen:
        return

    var px := int(player.global_position.x)
    var next_x := last_spawn_x + min_gap_px + rng.randi_range(0, rand_gap_px)
    if px + spawn_ahead_px >= next_x:
        last_spawn_x = next_x
        if rng.randf() < spawn_chance and GameState.can_spawn_obstacle(next_x):
            _spawn_obstacle(next_x)
            GameState.confirm_obstacle_spawn(next_x)

func _spawn_obstacle(xpos: int) -> void:
    if obstacles.is_empty():
        return
    var scene: PackedScene = obstacles.pick_random()
    var node := scene.instantiate() as Node2D
    add_child(node)
    node.add_to_group("obstacle")

    var ox := 0.0
    var oy := 0.0
    if "spawn_x_offset" in node:
        ox = float(node.spawn_x_offset)
    if "spawn_y_offset" in node:
        oy = float(node.spawn_y_offset)
    if node is CanvasItem and "spawn_z_index" in node:
        node.z_index = int(node.spawn_z_index)

    var base_y := ground_y + float(y_offset) + oy
    var bottom_off := _bottom_offset_from_origin(node)
    node.global_position = Vector2(xpos + ox, base_y - bottom_off)

func _cleanup_old() -> void:
    if not player:
        return
    var cutoff := player.global_position.x - float(cleanup_back_px)
    for c in get_children():
        if c is Node2D and c.is_in_group("obstacle"):
            if c.global_position.x < cutoff:
                c.queue_free()

func _count_alive() -> int:
    var n := 0
    for c in get_children():
        if c is Node2D and c.is_in_group("obstacle"):
            n += 1
    return n

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

func _bottom_offset_from_origin(n: Node) -> float:
    var spr := n.get_node_or_null("Sprite2D") as Sprite2D
    if not spr:
        spr = _find_first_sprite(n)
    if spr and spr.texture:
        var h: float = float(spr.texture.get_size().y) * abs(spr.scale.y)
        return spr.position.y + (h * 0.5 - spr.offset.y)
    return 0.0

func _find_first_sprite(n: Node) -> Sprite2D:
    for c in n.get_children():
        if c is Sprite2D:
            return c
        var s := _find_first_sprite(c)
        if s:
            return s
    return null
