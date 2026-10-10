extends "res://tests/consumable_runner.gd"
func run_tests() -> void:
 main=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 main.run_save.path="user://test_boot_resume.cfg"
 if OS.get_environment("SUGAR_SAVE_PHASE")=="write":
  main.start()
  GameManager.motion=false
  GameManager.moves=7
  GameManager.gummies=23
  GameManager.consumables.assign(["golden_glaze"])
  main.board.model.cells[0].coating=2
  main.board.model.cells[0].age=3
  main.quit_game()
  return
 main.refresh_continue()
 check(not main.get_node("Menu/Layout/Continue").disabled,"New process discovers save created before shutdown")
 await click(main.get_node("Menu/Layout/Continue"))
 check(GameManager.moves==7 and GameManager.gummies==23 and GameManager.consumables==["golden_glaze"],"Continue after reboot restores run inventory and counters")
 check(main.board.model.cells[0].coating==2 and main.board.model.cells[0].age==3,"Continue after reboot restores exact candy state")
 DirAccess.remove_absolute(main.run_save.path)
 print("RESULT: %s reboot checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
