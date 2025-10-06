extends Node2D
@onready var player: Node2D = $"../CharacterBody2D"

var chunks: Array[TileMap] = []
var w_px: int = 0
var base_y: int = 0

func _ready() -> void:
	for n: Node in get_children():
		if n is TileMap:
			chunks.append(n as TileMap)
	assert(chunks.size() >= 3) 

	var tm0: TileMap = chunks[0]
	var used: Rect2i = tm0.get_used_rect()
	var ts: Vector2i = tm0.tile_set.tile_size
	w_px = used.size.x * ts.x
	if w_px <= 0:
		push_warning("Chunks vazios: pinte o chão nos TileMaps.")
		return


	chunks.sort_custom(Callable(self, "_sort_chunks"))
	base_y = int(round(chunks[0].global_position.y))
	var start_x: int = int(round(chunks[0].global_position.x))
	for i in range(chunks.size()):
		chunks[i].global_position = Vector2(start_x + i * w_px, base_y)

func _sort_chunks(a: TileMap, b: TileMap) -> bool:
	return a.global_position.x < b.global_position.x

func _physics_process(_delta: float) -> void:
	if w_px <= 0: return

	
	chunks.sort_custom(Callable(self, "_sort_chunks"))

	
	while int(player.global_position.x) > int(chunks[1].global_position.x) + w_px:
		var left  := chunks[0]
		var right := chunks[chunks.size() - 1]
		var next_x: int = int(right.global_position.x) + w_px
		left.global_position = Vector2(next_x, base_y) 
		
		chunks.push_back(chunks.pop_front())
