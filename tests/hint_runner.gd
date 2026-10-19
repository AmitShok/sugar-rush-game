extends "res://tests/consumable_runner.gd"
func run_tests() -> void:
 main=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 main.get_node("Menu/Layout/Seed").text="38038"
 main.start()
 GameManager.motion=false
 await frames()
 var board: GameBoard=main.board
 var button: Button=main.get_node("Play/Hint")
 var moves: int=GameManager.moves
 var score: int=GameManager.score
 GameManager.gummies=3
 GameManager.changed.emit()
 check(button.text=="Hint $1" and not button.disabled,"A new run advertises a $1 hint")
 await click(button)
 check(GameManager.gummies==2 and GameManager.hint_cost()==2 and button.text=="Hint $2","Click buys one hint and raises the displayed price")
 check(board.tiles.filter(func(t: SugarTile) -> bool: return t.hinted).size()==2,"Purchased hint highlights both candies")
 var key: InputEventKey=InputEventKey.new()
 key.keycode=KEY_H
 key.pressed=true
 key.echo=true
 board._unhandled_key_input(key)
 check(GameManager.gummies==2 and GameManager.hints_used==1,"Holding H cannot repeatedly spend money")
 key.echo=false
 board._unhandled_key_input(key)
 check(GameManager.gummies==0 and GameManager.hint_cost()==3 and button.disabled,"Keyboard uses the same rising price and disables unaffordable hints")
 check(board.tiles.filter(func(t: SugarTile) -> bool: return t.hinted).size()==2,"Keyboard hint is not overwritten by the cursor highlight")
 board.hint()
 check(GameManager.gummies==0 and GameManager.hints_used==2,"Insufficient funds never charge or raise the price")
 check(GameManager.moves==moves and GameManager.score==score,"Hints affect money, not moves or score")
 await frames()
 check(main.run_save.read_save().hints_used==2 and main.run_save.read_save().gummies==0,"Hint price and spending reach the saved checkpoint")
 await main.to_menu()
 main.continue_run()
 check(GameManager.hint_cost()==3 and GameManager.gummies==0,"Quit to Title and Continue preserve the hint price")
 GameManager.gummies=20
 GameManager.changed.emit()
 board.busy=true
 board.hint()
 board.busy=false
 board.paused=true
 board.hint()
 board.paused=false
 board.target_consumable="candy_hammer"
 board.hint()
 board.target_consumable=""
 check(GameManager.gummies==20 and GameManager.hints_used==2,"Busy, paused and targeting states never charge")
 var cells: Array[CandyState]=board.model.cells.duplicate()
 board.model.cells=[]
 board.hint()
 board.model.cells=cells
 check(GameManager.gummies==20 and GameManager.hints_used==2,"No available swap means no charge")
 GameManager.next_round()
 check(GameManager.hint_cost()==3,"The price carries into the next round")
 await frames()
 var legacy: Dictionary=main.run_save.snapshot()
 legacy.erase("hints_used")
 var file: ConfigFile=ConfigFile.new()
 file.set_value("run","data",legacy)
 file.save(main.run_save.path)
 check(main.run_save.restore() and GameManager.hint_cost()==1,"Older saves load with a $1 starting hint")
 GameManager.hints_used=7
 main.start()
 check(GameManager.hint_cost()==1,"Only a new run resets the price")
 await frames()
 if FileAccess.file_exists(main.run_save.path): DirAccess.remove_absolute(main.run_save.path)
 print("RESULT: %s hint checks, %s failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
