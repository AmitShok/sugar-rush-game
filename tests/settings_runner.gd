extends Node
var failures: int=0
var checks: int=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if ok: print("PASS: "+message)
 else:
  failures+=1
  push_error(message)
func frames() -> void:
 for i: int in range(3): await get_tree().process_frame
func capture(name: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(OS.get_environment("SUGAR_CAPTURE_DIR")+"/"+name+".png")
func _ready() -> void:
 call_deferred("run_tests")
func run_tests() -> void:
 GameManager.preferences_path="user://test_crt_preferences.cfg"
 var main: Control=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 main.get_node("Menu/Layout/Options").pressed.emit()
 await frames()
 check(main.get_node("Pause/Layout/Volume").visible and get_tree().paused and GameManager.state=="menu","Title Options opens settings without starting a run")
 main.get_node("Pause/Layout/Back").pressed.emit()
 check(not get_tree().paused and not main.get_node("Pause").visible and main.get_node("Menu").visible,"Options Back returns to the title")
 main.get_node("Menu/Layout/Options").pressed.emit()
 var escape: InputEventKey=InputEventKey.new()
 escape.keycode=KEY_ESCAPE
 escape.pressed=true
 main._unhandled_key_input(escape)
 check(not get_tree().paused and not main.get_node("Pause").visible,"Escape from title Options returns to the title")
 main.start()
 GameManager.motion=false
 main.crt_layer.visible=true
 await frames()
 check(main.crt_layer.get_node("Screen").get_global_rect().size==Vector2(1152,720),"CRT covers the logical viewport")
 check(main.crt_layer.get_node("Screen").mouse_filter==Control.MOUSE_FILTER_IGNORE,"CRT overlay cannot intercept clicks")
 var hint: Control=main.get_node("Play/Hint")
 var info: Control=main.get_node("Play/Rules")
 var pause: Control=main.get_node("Play/MenuButton")
 check(info.position.x-hint.get_rect().end.x==12 and pause.position.x-info.get_rect().end.x==12,"Bottom buttons have equal 12px gaps without text expanding them")
 check(hint.position.x==452 and pause.get_rect().end.x==900,"Bottom buttons align with the board edges")
 await capture("crt_on")
 main.toggle_pause()
 main.show_options(true)
 await frames()
 var settings: Control=main.get_node("Pause/Layout")
 check(get_tree().paused and settings.get_node("CRT").visible and settings.get_node("Volume/Slider").visible,"CRT and volume options are usable while paused")
 check(main.get_node("Pause").get_global_rect().end.y<710,"Expanded options fit the screen")
 settings.get_node("CRT").button_pressed=false
 settings.get_node("Volume/Slider").value=37
 settings.get_node("Sound").button_pressed=false
 settings.get_node("Motion").button_pressed=false
 check(not main.crt_layer.visible and is_equal_approx(GameManager.master_volume,0.37) and AudioServer.is_bus_mute(0),"Controls apply CRT toggle, volume and mute immediately")
 await capture("crt_options_off")
 var slider: Control=settings.get_node("Volume/Slider")
 var point: Vector2=slider.get_global_rect().get_center()
 for pressed: bool in [true,false]:
  var event: InputEventMouseButton=InputEventMouseButton.new()
  event.position=point
  event.global_position=point
  event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=pressed
  get_window().push_input(event,false)
 await frames()
 check(GameManager.master_volume>0.45 and GameManager.master_volume<0.55,"Physical slider clicks work while paused")
 settings.get_node("Volume/Slider").value=37
 var file: ConfigFile=ConfigFile.new()
 check(file.load(GameManager.preferences_path)==OK and file.get_value("settings","crt_enabled")==false and is_equal_approx(float(file.get_value("settings","master_volume")),0.37),"Settings changes are written to the preferences file")
 GameManager.crt_enabled=true
 GameManager.sound=true
 GameManager.motion=true
 GameManager.master_volume=1.0
 GameManager.load_preferences()
 check(not GameManager.crt_enabled and not GameManager.sound and not GameManager.motion and is_equal_approx(GameManager.master_volume,0.37),"Loading the file restores all four settings")
 settings.get_node("Sound").button_pressed=true
 settings.get_node("Volume/Slider").value=0
 check(AudioServer.is_bus_mute(0),"Zero volume is silent")
 settings.get_node("Volume/Slider").value=100
 check(not AudioServer.is_bus_mute(0) and is_equal_approx(AudioServer.get_bus_volume_db(0),0.0),"Full volume restores master gain without stale mute")
 var before: int=GameManager.rng.state
 var pitches: Dictionary={}
 var bounded: bool=true
 for i: int in range(100):
  var pitch: float=GameManager.next_sound_pitch(0)
  bounded=bounded and pitch>=0.90 and pitch<=1.10
  pitches[pitch]=true
 check(bounded and pitches.size()>90,"Repeated pops get distinct pitches within ten percent")
 check(GameManager.rng.state==before,"Audio randomness does not change seeded gameplay RNG")
 check(GameManager.next_sound_pitch(100)<=2.2,"Cascade pitch is capped")
 main.set_paused(false)
 await capture("crt_off")
 settings.get_node("CRT").button_pressed=true
 await frames()
 await capture("crt_final_on")
 var legacy: ConfigFile=ConfigFile.new()
 legacy.set_value("settings","motion",false)
 legacy.set_value("settings","sound",false)
 legacy.save(GameManager.preferences_path)
 GameManager.load_preferences()
 check(not GameManager.motion and not GameManager.sound and GameManager.crt_enabled and is_equal_approx(GameManager.master_volume,0.8),"Older settings files retain choices and receive defaults for new options")
 get_tree().paused=false
 DirAccess.remove_absolute(ProjectSettings.globalize_path(GameManager.preferences_path))
 print("RESULT: %s CRT/audio/settings checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
