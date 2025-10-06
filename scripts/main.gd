extends Node2D

@export var player_path: NodePath
@export var base_scroll_speed: float = 220.0

var player: Node2D
var last_x: float = 0.0
var scroll_speed: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

    if player_path == NodePath(""):
        player = get_node_or_null("../CharacterBody2D") as Node2D
    else:
        player = get_node_or_null(player_path) as Node2D

    GameState.reset_run()
    GameState.speed_changed.connect(_on_speed_changed)

    if player:
        last_x = player.global_position.x

    var do_autostart := false
    if "request_auto_start" in GameState:
        do_autostart = GameState.request_auto_start

    if do_autostart:
        GameState.request_auto_start = false
        get_tree().paused = false
        GameState.start_run()
    else:
        get_tree().paused = true

    _on_speed_changed(GameState.speed_mult)

func _on_speed_changed(m: float) -> void:
    scroll_speed = base_scroll_speed * m

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_start") and get_tree().paused:
        get_tree().paused = false
        GameState.start_run()

func _physics_process(_delta: float) -> void:
    if get_tree().paused or not GameState.running or player == null:
        return
    var new_x := player.global_position.x
    var dx := new_x - last_x
    if dx > 0.0:
        GameState.add_distance(dx)
    last_x = new_x
