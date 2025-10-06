extends Control

@export_file("*.tscn") var menu_scene_path := "res://scenes/menu.tscn"

@onready var back_button: Button = $MarginContainer/PanelContainer/VBoxContainer/BackButton
@onready var jump_label:   Label  = $MarginContainer/PanelContainer/VBoxContainer/JumpLabel
@onready var crouch_label: Label  = $MarginContainer/PanelContainer/VBoxContainer/CrouchLabel


func _ready() -> void:
    back_button.pressed.connect(_on_back)
    jump_label.text   = "Pular: Espaço"
    crouch_label.text = "Agachar: Seta ↓"
    

func _on_back() -> void:
    get_tree().change_scene_to_file(menu_scene_path)
