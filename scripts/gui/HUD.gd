class_name UserHUD extends Control

@onready var putting_hud = $PuttingHUD
@onready var round_timer = $TimeLeft

signal timeout

func _ready():
	Global.set_hud(self)

func update_text(text):
	putting_hud.update_text(text)

func start_timer():
	round_timer.start()

func stop_timer():
	round_timer.stop()

func _on_time_left_timeout():
	timeout.emit()
