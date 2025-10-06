
extends Area2D

@export var duration_ms: int = 2000
@export var radius: float   = 140.0

func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D or body.is_in_group("player"):
		GameState.start_magnet(duration_ms, 140.0)  

		queue_free()
