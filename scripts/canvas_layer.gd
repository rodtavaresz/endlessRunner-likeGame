extends CanvasLayer

@onready var start_overlay: Control        = $MarginContainer
@onready var start_panel: PanelContainer   = $MarginContainer/CenterContainer/StartPanel

@onready var coins_label: Label  = $MarginContainer2/HBoxContainer/CoinsLabel
@onready var high_label: Label   = $MarginContainer3/HBoxContainer2/HighLabel
@onready var score_label: Label  = $MarginContainer4/HBoxContainer3/ScoreLabel

func _ready() -> void:
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0, 0, 0, 0.80)
    sb.corner_radius_top_left = 10
    sb.corner_radius_top_right = 10
    sb.corner_radius_bottom_left = 10
    sb.corner_radius_bottom_right = 10
    sb.content_margin_left = 12
    sb.content_margin_right = 12
    sb.content_margin_top = 8
    sb.content_margin_bottom = 8
    start_panel.add_theme_stylebox_override("panel", sb)

    start_overlay.visible = true
    _refresh_all()

    GameState.coins_changed.connect(func(v): coins_label.text = "Bananas : " + str(v))
    GameState.high_score_changed.connect(func(v): high_label.text = "Highscore: " + str(v))
    GameState.score_changed.connect(func(v): score_label.text = "Score: " + str(v))

    GameState.run_started.connect(func():
        start_overlay.visible = false
        score_label.text = "Score: " + str(GameState.score)
    )
    GameState.run_ended.connect(func():
        start_overlay.visible = true
    )

func _refresh_all() -> void:
    coins_label.text = "Bananas: " + str(GameState.coins)
    high_label.text  = "Highscore: " + str(GameState.high_score)
    score_label.text = "Score: " + str(GameState.score)
