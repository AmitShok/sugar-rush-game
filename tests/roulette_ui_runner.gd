extends Node
var checks: int=0
var failures: int=0
var main: Control
var board: GameBoard
var roulette: JokerData
func check(ok: bool, message: String) -> void:
 checks+=1
 if ok: print("PASS: "+message)
 else:
  failures+=1
  push_error(message)
func frames() -> void:
 for i: int in range(3): await get_tree().process_frame
func _ready() -> void:
 call_deferred("run_tests")
func markers_correct() -> bool:
 for i: int in range(64):
  if board.tiles[i].roulette != (GameManager.jokers.has("roulette") and board.model.cells[i].color==GameManager.poison): return false
 return true
func run_tests() -> void:
 main=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 GameManager.start_run(38)
 GameManager.motion=false
 board=main.get_node("Play/GameBoard")
 for item: JokerData in GameManager.config.jokers:
  if item.id=="roulette": roulette=item
 check(markers_correct(),"No roulette badges without the Joker")
 GameManager.jokers.add(roulette)
 GameManager.start_round()
 check(GameManager.poison>=0 and markers_correct(),"Round chooses a type and marks all its candies")
 var inventory: Control=main.get_node("Play/JokerInventory")
 var card: JokerCardButton=inventory.get_node("Layout/Slots").get_child(0).get_child(0)
 var tip: Control=card._make_custom_tooltip("")
 var description: String=tip.get_child(0).get_child(1).text
 check(description.contains(GameManager.config.candies[GameManager.poison].display_name) and description.contains("Not matched yet"),"Actual custom Joker tooltip names chosen candy and pending penalty")
 tip.free()
 for color: int in range(6):
  GameManager.poison=color
  board.model.cells[0].color=color
  board.model.cells[0].blocker=2
  board.model.cells[1].color=color
  board.model.cells[1].coating=2
  board.model.cells[2].color=color
  board.model.cells[2].coating=1
  board.sync_tiles(false)
  check(markers_correct() and board.tiles[0].roulette and board.tiles[1].roulette and board.tiles[2].roulette,"Markers include locked, gold and caramel candies of type "+str(color))
 GameManager.poison=0
 board.sync_tiles(false)
 GameManager.award({"total":10,"chips":10,"mult":1},0)
 check(GameManager.poison_cleared and GameManager.joker_description(roulette).contains("penalty avoided") and markers_correct(),"Matched status updates without removing active bonus markers")
 GameManager.start_round()
 check(not GameManager.poison_cleared and markers_correct(),"New round resets status and redraws the newly chosen type")
 var legal: Vector2i=board.model.legal_moves()[0]
 await board.attempt_swap(legal.x,legal.y)
 check(markers_correct(),"Markers follow real swaps, clears and refills")
 GameManager.start_round()
 await frames()
 card=inventory.get_node("Layout/Slots").get_child(0).get_child(0)
 var event: InputEventMouseMotion=InputEventMouseMotion.new()
 event.position=card.get_global_rect().get_center()
 event.global_position=event.position
 get_window().push_input(event,false)
 await get_tree().create_timer(1.0).timeout
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png(OS.get_environment("SUGAR_CAPTURE_DIR")+"/roulette_markers.png")
 for round_id: int in [0,2,5]:
  GameManager.round_index=round_id
  GameManager.start_round()
  for color: int in range(6):
   GameManager.poison=color
   GameManager.changed.emit()
   await frames()
   var hud: Control=main.get_node("Play/UI_Hud")
   check(hud.get_global_rect().end.y<=710 and hud.get_node("Layout/Curse").get_global_rect().end.y<=710,"Roulette and boss rule fit HUD: round %s, type %s" % [round_id,color])
 GameManager.jokers.remove(roulette)
 board.sync_tiles(false)
 check(markers_correct(),"Removing the Joker removes all badges")
 GameManager.start_run(39)
 check(GameManager.poison==-1 and markers_correct(),"Fresh run has no stale target or badges")
 print("RESULT: %s roulette UI checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
