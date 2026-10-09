extends Node
var failures: int=0
var checks: int=0
func check(ok: bool, message: String) -> void:
 checks+=1
 if ok: print("PASS: "+message)
 else:
  failures+=1
  push_error("FAIL: "+message)
func _ready() -> void:
 call_deferred("run_tests")
func frames() -> void:
 for i: int in range(3): await get_tree().process_frame
func run_tests() -> void:
 var main: Control=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 main.get_node("Menu/Layout/Play").pressed.emit()
 var route: Control=main.get_node("RoundMap")
 check(route.visible and GameManager.state=="menu" and route.target_index==0,"Starting a run previews the ante before gameplay")
 check(route.cards.size()==3 and route.subtitle.text.contains("2 rounds") and route.subtitle.text.contains("INSPECTOR"),"Preview shows Small, Big and Inspector two clears ahead")
 await frames()
 check(route.enter_button.get_global_rect().end.y<=710,"Route confirmation stays on canvas")
 await capture("v5_round_map")
 route.enter_button.pressed.emit()
 GameManager.motion=false
 check(GameManager.state=="playing" and GameManager.round_index==0 and not route.visible,"Confirming starts exactly the first round")
 await frames()
 await capture("v5_gameplay")
 var expected_bosses: Array[String]=["INSPECTOR","HEATWAVE","INSPECTOR","HEATWAVE","INSPECTOR","HEATWAVE"]
 for index: int in range(GameManager.config.rounds.size()-1):
  GameManager.score=GameManager.current_round().quota
  GameManager.settle_round()
  main.get_node("Shop/Actions/Continue").pressed.emit()
  await frames()
  check(route.visible and route.target_index==index+1 and GameManager.round_index==index,"Leaving shop previews next round without skipping current index "+str(index))
  var before_cash: int=GameManager.gummies
  route.back_button.pressed.emit()
  check(not route.visible and GameManager.state=="shop" and GameManager.gummies==before_cash,"Back returns to shop without another payout")
  main.get_node("Shop/Actions/Continue").pressed.emit()
  check(route.subtitle.text.contains(expected_bosses[(index+1)/3]),"Correct upcoming boss for ante "+str((index+1)/3+1))
  check(route.heading.text.contains("/ 6"),"Route shows all six antes")
  if (index+1)%3==2:
   check(route.subtitle.text.begins_with("BOSS NEXT"),"Boss warning appears before entering boss")
   await capture("v5_boss_preview")
  route.enter_button.pressed.emit()
  check(GameManager.round_index==index+1 and GameManager.state=="playing","Confirmed transition starts one round")
  await frames()
  check(main.get_node("Play/UI_Hud").get_global_rect().end.y<=710,"HUD including route and boss rule fits")
  var hud: Control=main.get_node("Play/UI_Hud")
  check(hud.get_node("Layout/Ante").text.ends_with("06") and hud.get_node("Layout/Route").text.to_upper().contains(expected_bosses[(index+1)/3]),"HUD previews the current ante boss beyond round nine")
  check(route.enter_button.get_global_rect().end.y<=710,"Late-round map stays on canvas")
  if (index+1)%3==2: await capture("v5_boss_gameplay")
 GameManager.score=GameManager.current_round().quota
 GameManager.settle_round()
 check(GameManager.state=="over" and not route.visible,"Final boss ends the run without a nonexistent next round")
 var files_ok: bool=true
 var folder: DirAccess=DirAccess.open("res://assets/exported")
 for file: String in folder.get_files():
  if file.ends_with(".png"): files_ok=files_ok and FileAccess.file_exists("res://assets/source/aseprite/"+file.get_basename()+".aseprite")
 check(files_ok,"Every exported raster texture has a matching editable Aseprite master")
 check(main.theme.default_font.resource_path.ends_with(".fnt") and main.theme.get_stylebox("normal","Button") is StyleBoxTexture,"Text and UI skins use Aseprite-exported textures")
 check(main.get_node("Background").material==null,"Table uses exported Aseprite art instead of runtime shader")
 print("RESULT: %s route/art checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
func capture(name: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 var folder: String=OS.get_environment("SUGAR_CAPTURE_DIR")
 if not folder.is_empty(): get_viewport().get_texture().get_image().save_png(folder+"/"+name+".png")
