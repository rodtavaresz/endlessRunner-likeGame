extends CharacterBody2D

const OBSTACLE_LAYER := 2

var alive := true
@export var death_restart_delay := 1.0

@export var forward_speed := 240.0
@export var jump_force := 500.0
@export var gravity := 1200.0
@export var run_accel := 3000.0
@export var base_run_speed: float = 230.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = get_node_or_null("HurtBox")
@onready var sfx_jump: AudioStreamPlayer2D = $SFXJump


var run_speed: float
var crouch_playing := false

func _ready() -> void:
    sprite.animation_finished.connect(_on_anim_finished)
    sprite.flip_h = false
    run_speed = base_run_speed
    if Engine.has_singleton("GameState"):
        GameState.speed_changed.connect(_on_speed_changed)
        GameState.invincible_changed.connect(_on_invincible_changed)
        _on_invincible_changed(GameState.shield_on)

func _on_speed_changed(m: float) -> void:
    run_speed = base_run_speed * m

func _on_invincible_changed(active: bool) -> void:
    set_collision_mask_value(OBSTACLE_LAYER, not active)
    if hurtbox:
        hurtbox.monitoring = not active

func _physics_process(delta: float) -> void:
    if get_tree().paused or not GameState.running:
        return

    if not alive:
        velocity.x = 0.0
        move_and_slide()
        return

    if not is_on_floor():
        velocity.y += gravity * delta
    elif Input.is_action_just_pressed("ui_accept") and not crouch_playing:
        velocity.y = -jump_force
        if sfx_jump:
            sfx_jump.pitch_scale = randf_range(0.96, 1.04)  
            sfx_jump.play()


    velocity.x = move_toward(velocity.x, forward_speed, run_accel * delta)
    velocity.x = run_speed
    
    
    
    move_and_slide()
    _update_anim()

    for i in range(get_slide_collision_count()):
        var col := get_slide_collision(i)
        var other := col.get_collider()
        if other and other.is_in_group("obstacle"):
            if GameState.shield_on or GameState.invincible_m_left > 0.0:
                continue
            _on_hit_obstacle()
            break

func _update_anim() -> void:
    if crouch_playing:
        sprite.flip_h = false
        return
    if Input.is_action_just_pressed("ui_down") and is_on_floor():
        crouch_playing = true
        if collider:
            collider.scale.y = 0.5
        sprite.flip_h = false
        sprite.play("duck")
        return
    if not is_on_floor():
        _play_if_changed("jumping")
    else:
        _play_if_changed("run")
    sprite.flip_h = false

func _play_if_changed(anim_name: String) -> void:
    if sprite.animation != anim_name:
        sprite.play(anim_name)

func _on_anim_finished() -> void:
    if sprite.animation == "duck":
        crouch_playing = false
        if collider:
            collider.scale.y = 1.0
        if not is_on_floor():
            _play_if_changed("jumping")
        else:
            _play_if_changed("run")
        sprite.flip_h = false

func _on_hit_obstacle() -> void:
    if not alive:
        return
    if GameState.invincible_m_left > 0.0 or GameState.shield_on:
        return
    alive = false
    velocity = Vector2.ZERO
    GameState.add_death()
    GameState.end_run()
    await get_tree().create_timer(death_restart_delay).timeout
    get_tree().reload_current_scene()
 
