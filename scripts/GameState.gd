extends Node

signal coins_changed(value)
signal high_score_changed(value)
signal deaths_changed(value)
signal score_changed(value)
signal run_started
signal run_ended
signal speed_changed(mult)

signal invincible_changed(active: bool)
signal magnet_changed(active: bool, radius: float)

var coins: int = 0
var high_score: int = 0
var deaths: int = 0
var score: int = 0
var running: bool = false

const SAVE_PATH := "user://save.cfg"
const SAVE_SECTION := "stats"


const SPEED_EVERY := 5000
const SPEED_MAX   := 25000
const SPEED_STEP  := 0.5
var speed_mult: float = 1.0


const SPAWN_EXCLUDE_RADIUS := 128.0
var last_coin_x: float = -1.0e9
var last_obstacle_x: float = -1.0e9


var invincible_m_left: float = 0.0
var magnet_m_left: float     = 0.0
var magnet_radius: float     = 0.0
var magnet_pull_speed: float = 400.0


var shield_on: bool = false

func _ready() -> void:
    _load_data()

func reset_run() -> void:
    coins = 0
    score = 0
    running = false
    speed_mult = 1.0
    last_coin_x = -1.0e9
    last_obstacle_x = -1.0e9
    clear_invincible()
    clear_magnet()
    coins_changed.emit(coins)
    score_changed.emit(score)
    speed_changed.emit(speed_mult)

func start_run() -> void:
    running = true
    run_started.emit()
    _recalc_speed()

func end_run() -> void:
    running = false
    if score > high_score:
        high_score = score
        high_score_changed.emit(high_score)
        _save_data()
    run_ended.emit()

func add_coin(n := 1) -> void:
    coins += n
    coins_changed.emit(coins)

func add_death() -> void:
    deaths += 1
    deaths_changed.emit(deaths)
    _save_data()

func add_distance(dx: float) -> void:
    if not running:
        return
    
    score += int(round(dx))
    score_changed.emit(score)
    _recalc_speed()
    
    if invincible_m_left > 0.0:
        invincible_m_left -= dx
        if invincible_m_left <= 0.0:
            clear_invincible()
    if magnet_m_left > 0.0:
        magnet_m_left -= dx
        if magnet_m_left <= 0.0:
            clear_magnet()

func _recalc_speed() -> void:
    var steps: int = int(score / SPEED_EVERY)
    var max_steps: int = int(SPEED_MAX / SPEED_EVERY)
    if steps > max_steps:
        steps = max_steps
    var new_mult := 1.0 + float(steps) * SPEED_STEP
    if not is_equal_approx(new_mult, speed_mult):
        speed_mult = new_mult
        speed_changed.emit(speed_mult)



func start_shield(meters: float) -> void:
    invincible_m_left = max(invincible_m_left, meters)
    if not shield_on:
        shield_on = true
        invincible_changed.emit(true)

func clear_invincible() -> void:
    if invincible_m_left != 0.0 or shield_on:
        invincible_m_left = 0.0
        shield_on = false
        invincible_changed.emit(false)

func start_magnet(meters: float, radius: float) -> void:
    magnet_m_left = max(magnet_m_left, meters)
    magnet_radius = radius
    magnet_changed.emit(true, magnet_radius)

func clear_magnet() -> void:
    if magnet_m_left != 0.0 or magnet_radius != 0.0:
        magnet_m_left = 0.0
        magnet_radius = 0.0
        magnet_changed.emit(false, 0.0)



func can_spawn_coin(x: float, radius := SPAWN_EXCLUDE_RADIUS) -> bool:
    return abs(x - last_obstacle_x) >= float(radius)

func confirm_coin_spawn(x: float) -> void:
    last_coin_x = x

func can_spawn_obstacle(x: float, radius := SPAWN_EXCLUDE_RADIUS) -> bool:
    return abs(x - last_coin_x) >= float(radius)

func confirm_obstacle_spawn(x: float) -> void:
    last_obstacle_x = x



func reset_high_score() -> void:
    high_score = 0
    high_score_changed.emit(high_score)
    _save_data()

func _save_data() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value(SAVE_SECTION, "high_score", high_score)
    cfg.set_value(SAVE_SECTION, "deaths", deaths)
    cfg.save(SAVE_PATH)

func _load_data() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) == OK:
        high_score = int(cfg.get_value(SAVE_SECTION, "high_score", 0))
        deaths     = int(cfg.get_value(SAVE_SECTION, "deaths", 0))
