extends Node2D

@export var player_path: NodePath
@export var floor_tilemap_path: NodePath
@export var coins: Array[PackedScene] = []

@export var use_fixed_height: bool = true
@export var fixed_height_px: int = 48
@export var heights_px: Array[int] = [28, 48, 72]

@export var line_spacing_px: int = 24
@export var line_count_range: Vector2i = Vector2i(3, 6)

@export var spawn_ahead_px: int = 900
@export var min_gap_px: int = 420
@export var rand_gap_px: int = 360

@export_range(0.0, 1.0, 0.01) var spawn_chance: float =  0.65
@export var max_on_screen: int = 12
@export var y_offset: int = 0

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
    if _count_alive() >= max_on_screen:
        return

    var px := int(player.global_position.x)
    var next_x := last_spawn_x + min_gap_px + rng.randi_range(0, rand_gap_px)
    if px + spawn_ahead_px >= next_x:
        last_spawn_x = next_x
        if rng.randf() < spawn_chance and GameState.can_spawn_coin(next_x):
            _spawn_pattern(next_x)
            GameState.confirm_coin_spawn(next_x)

func _spawn_pattern(xpos: int) -> void:
    var r := rng.randi_range(0, 2)
    if r == 0:
        _spawn_single(xpos)
    elif r == 1:
        _spawn_line(xpos)
    else:
        _spawn_small_arc(xpos)

func _spawn_single(xpos: int) -> void:
    var y: float = ground_y - _chosen_h()
    _instance_coin(Vector2(xpos, y))

func _spawn_line(xpos: int) -> void:
    var count := rng.randi_range(line_count_range.x, line_count_range.y)
    var y := _chosen_y()
    var start_x := xpos - int((count - 1) * 0.5 * line_spacing_px)
    for i in count:
        _instance_coin(Vector2(start_x + i * line_spacing_px, y))

func _spawn_small_arc(xpos: int) -> void:
    var count := rng.randi_range(3, 5)
    var base_h := _chosen_h()
    var amp: float = 0.0
    if not use_fixed_height:
        amp = float(rng.randi_range(10, 30))
    var start_x: int = xpos - int((count - 1) * 0.5 * line_spacing_px)
    for i in count:
        var fx: float = i - (count - 1) * 0.5
        var denom: float = maxf(1.0, float(count - 1))
        var y: float = ground_y - (base_h + amp * cos((fx / denom) * PI))
        _instance_coin(Vector2(start_x + i * line_spacing_px, y))

func _chosen_h() -> float:
    var h: float
    if use_fixed_height:
        h = float(fixed_height_px)
    else:
        h = float(heights_px.pick_random())
    return h

func _chosen_y() -> float:
    return ground_y - _chosen_h() + float(y_offset)

func _instance_coin(p: Vector2) -> void:
    if coins.is_empty():
        return
    var scene: PackedScene = coins.pick_random()
    var node := scene.instantiate() as Node2D
    add_child(node)
    node.global_position = p

func _count_alive() -> int:
    var n := 0
    for c in get_children():
        if c is Node2D:
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
