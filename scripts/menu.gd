extends Control

@export_file("*.tscn") var main_scene_path    := "res://scenes/main.tscn"
@export_file("*.tscn") var options_scene_path := "res://scenes/options.tscn"

@onready var play_button:    Button              = $VBoxContainer/PlayButton
@onready var reset_button:   Button              = $VBoxContainer/ZerarHighScore
@onready var options_button: Button              = $VBoxContainer/OptionsButton   
@onready var confirm_reset:  ConfirmationDialog  = $ConfirmReset
@onready var high_menu_label: Label              = $VBoxContainer/Label

func _ready() -> void:
    play_button.pressed.connect(_on_play)
    options_button.pressed.connect(_on_options)
    reset_button.pressed.connect(_on_ask_reset)
    confirm_reset.confirmed.connect(_on_reset_confirmed)

    if Engine.has_singleton("GameState"):
        GameState.high_score_changed.connect(_on_high_changed)

    _refresh_menu()

func _on_play() -> void:
    get_tree().change_scene_to_file(main_scene_path)

func _on_options() -> void:
    get_tree().change_scene_to_file(options_scene_path)

func _on_ask_reset() -> void:
    confirm_reset.title = "Confirmar"
    confirm_reset.dialog_text = "Tem certeza que deseja zerar o High Score?"
    confirm_reset.get_ok_button().text = "Sim"
    confirm_reset.get_cancel_button().text = "Cancelar"
    confirm_reset.popup_centered()

func _on_reset_confirmed() -> void:
    GameState.reset_high_score()
    _refresh_menu()

func _on_high_changed(_v: int) -> void:
    _refresh_menu()

func _refresh_menu() -> void:
    high_menu_label.text = "Highscore: " + str(GameState.high_score)
