extends "res://tests/consumable_runner.gd"
func run_tests() -> void:
 main=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 var saver: Node=main.run_save
 var fixture: String=OS.get_environment("SUGAR_SAVE_FIXTURE")
 if not fixture.is_empty():
  var source: ConfigFile=ConfigFile.new()
  check(source.load(fixture)==OK,"Existing player save can be read without modifying it")
  source.save(saver.path)
  check(saver.has_save() and saver.restore(),"Existing player save with negative candy ages loads")
  if not saver.has_save():
   get_tree().quit(1)
   return
  check(saver.snapshot()==source.get_value("run","data"),"Existing player save restores all fields without data loss")
 main.start()
 GameManager.motion=false
 var board: GameBoard=main.board
 var move: Vector2i=board.model.legal_moves()[0]
 board.attempt_swap(move.x,move.y)
 while board.busy: await frames()
 await frames()
 var has_new: bool=false
 for candy: CandyState in board.model.cells: has_new=has_new or candy.age==-1
 check(has_new,"Real match refill produces the valid -1 age sentinel")
 var expected: Dictionary=saver.snapshot()
 main.toggle_pause()
 await frames()
 await click(main.get_node("Pause/Layout/Abandon"))
 check(not main.get_node("Menu/Layout/Continue").disabled,"Continue remains enabled after a real match and Quit to Title")
 await click(main.get_node("Menu/Layout/Continue"))
 check(saver.snapshot()==expected,"Physical Continue restores the exact post-match run")
 var malformed: Dictionary=expected.duplicate(true)
 malformed.board.cells[0][3]=-2
 var file: ConfigFile=ConfigFile.new()
 file.set_value("run","data",malformed)
 file.save(saver.path)
 check(not saver.has_save(),"Invalid ages below the sentinel remain rejected")
 DirAccess.remove_absolute(saver.path)
 print("RESULT: %s refill/save checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
