
extends Area2D

@export var duration_ms: int = 2000

func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D or body.is_in_group("player"):
		GameState.start_shield(duration_ms)        

		queue_free()
