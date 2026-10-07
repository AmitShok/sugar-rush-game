extends Node
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if ok: print("PASS: "+message)
 else:
  failures+=1
  push_error("FAIL: "+message)
func _ready() -> void:
 call_deferred("run_tests")
func frames() -> void:
 for i: int in range(3): await get_tree().process_frame
func click(control: Control) -> void:
 var dimensions: Vector2=Vector2(get_window().size)
 var factor: float=minf(dimensions.x/1152.0,dimensions.y/720.0)
 var point: Vector2=(dimensions-Vector2(1152,720)*factor)*0.5+control.get_global_rect().get_center()*factor
 for pressed: bool in [true,false]:
  var event: InputEventMouseButton=InputEventMouseButton.new()
  event.position=point
  event.global_position=point
  event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=pressed
  get_window().push_input(event,false)
 await frames()
func run_tests() -> void:
 var main: Control=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 check(ProjectSettings.get_setting("application/config/name")=="Sugar Rush" and get_window().title.begins_with("Sugar Rush"),"Application and window are named Sugar Rush")
 check(main.get_node("Menu/Layout/Title").text=="SUGAR\nRUSH" and main.get_node("Play/UI_Hud/Layout/Logo").text=="SUGAR RUSH","Title and HUD use Sugar Rush")
 check(main.get_node("Menu").get_global_rect().end.y<=710,"Title menu fits with the Collection button")
 await capture("v7_title")
 await click(main.get_node("Menu/Layout/Collection"))
 var collection: Control=main.get_node("Collection")
 check(collection.visible and collection.page_count()==4,"Menu opens a four-page collection")
 check(collection.previous.disabled and not collection.next.disabled,"First-page navigation boundaries are correct")
 var seen: Dictionary={}
 for page: int in range(collection.page_count()):
  for button: TextureButton in collection.card_buttons:
   await click(button)
   var item: JokerData=collection.selected
   seen[item.id]=true
   check(collection.portrait.texture==item.icon and collection.description.text==item.description and collection.title.text==item.display_name,"Art and effect match the resource: "+item.display_name)
   check(collection.description.get_minimum_size().y<=150 and collection.title.get_minimum_size().y<=72,"Details fit: "+item.display_name)
  if page==0: await capture("v7_collection")
  if page<collection.page_count()-1: await click(collection.next)
 check(seen.size()==22 and collection.next.disabled,"Every Joker, including all six Supply Jokers, is reachable")
 await click(collection.previous)
 check(collection.page==2,"Previous returns to the preceding page")
 await click(collection.back)
 check(not collection.visible and GameManager.state=="menu","Back closes collection without starting a run")
 for dimensions: Vector2i in [Vector2i(800,500),Vector2i(720,960),Vector2i(1600,700)]:
  get_window().size=dimensions
  await frames()
  await click(main.get_node("Menu/Layout/Collection"))
  await click(collection.card_buttons[1])
  check(collection.visible and collection.selected.id==GameManager.config.jokers[1].id,"Collection click stays aligned at "+str(dimensions))
  var escape: InputEventKey=InputEventKey.new()
  escape.keycode=KEY_ESCAPE
  escape.pressed=true
  get_window().push_input(escape,false)
  await frames()
  check(not collection.visible,"Escape returns to the menu")
 print("RESULT: %s collection/name checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
func capture(name: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 var folder: String=OS.get_environment("SUGAR_CAPTURE_DIR")
 if not folder.is_empty(): get_viewport().get_texture().get_image().save_png(folder+"/"+name+".png")
