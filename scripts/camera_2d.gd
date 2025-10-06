extends Camera2D

@export var target_path: NodePath
@export var x_offset: float = 290.0      
@export var y_offset: float = 0.0     
@export var smoothing: bool = true
@export var smoothing_speed: float = 10.0

var target: Node2D
var y_fixed: float

func _ready() -> void:
	
	target = get_node_or_null(target_path) as Node2D

	
	make_current()

	
	position_smoothing_enabled = smoothing
	position_smoothing_speed = smoothing_speed

	
	
	offset = Vector2.ZERO

	
	if target:
		y_fixed = target.global_position.y + y_offset
	else:
		
		y_fixed = global_position.y + y_offset

func _process(_dt: float) -> void:
	if not target:
		return
	
	global_position.x = target.global_position.x + x_offset

	global_position.y = y_fixed
