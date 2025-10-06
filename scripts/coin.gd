extends Area2D

@export var value: int = 1
@export var player_path: NodePath = NodePath("")   

var player: Node2D
var collected := false
var GS: Node = null

func _ready() -> void:
    add_to_group("coin")
    monitoring = true
    body_entered.connect(_on_body_entered)
    player = _find_player()
    GS = get_node_or_null("/root/GameState")   

func _physics_process(delta: float) -> void:
    if collected:
        return
    if GS == null:
        return
    if GS.magnet_radius <= 0.0 or player == null:
        return

    var v: Vector2 = player.global_position - global_position
    var d: float = v.length()
    if d <= GS.magnet_radius and d > 0.0:
        var step: float = float(GS.magnet_pull_speed) * delta
        if step > d:
            step = d
        global_position += v.normalized() * step

func _on_body_entered(body: Node) -> void:
    if collected:
        return
    if body is CharacterBody2D or body.is_in_group("player"):
        _collect()

func _collect() -> void:
    if collected:
        return
    collected = true

    if GS:
        GS.add_coin(value)
        print("Coin collected +", value, " | total=", GS.coins)
    else:
        print("Coin collected, mas GameState NÃO encontrado em /root/GameState")

    queue_free()

func _find_player() -> Node2D:
    if player_path != NodePath(""):
        var p := get_node_or_null(player_path) as Node2D
        if p:
            return p
    var arr := get_tree().get_nodes_in_group("player")
    if arr.size() > 0:
        return arr[0] as Node2D
    var p2 := get_node_or_null("../CharacterBody2D") as Node2D
    if p2:
        return p2
    return get_node_or_null("../../CharacterBody2D") as Node2D
