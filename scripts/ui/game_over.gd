extends PanelContainer
signal restart_requested
signal menu_requested
func _ready() -> void:
 $Layout/Restart.pressed.connect(func() -> void: restart_requested.emit())
 $Layout/Menu.pressed.connect(func() -> void: menu_requested.emit())
func show_result(won: bool) -> void:
 $Layout/Eyebrow.text = "RECIPE PERFECTED" if won else "THE BATCH IS BURNT"
 $Layout/Title.text = "Sweet victory." if won else "One more taste?"
 $Layout/Details.text = "Round %s / 9 | %s / %s score\nCash $%s | Seed %s" % [GameManager.round_index+1,GameManager.score,GameManager.current_round().quota,GameManager.gummies,GameManager.run_seed]
 visible = true
