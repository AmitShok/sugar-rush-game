extends Control
@onready var board: GameBoard = $Play/GameBoard
const DESIGN_SIZE: Vector2i = Vector2i(1152,720)
var shake: Tween
var collection: Control
var candy_guide: Control
var route: Control
var route_new_run: bool = true
var toast_tween: Tween
func _ready() -> void:
 # A fixed logical canvas keeps drawing and native GUI input in the same space.
 # Physical window dimensions may change freely without changing game geometry.
 var window: Window = get_window()
 window.title = "Sugar Rush | v0.10 - Candy Upgrades"
 window.content_scale_size = DESIGN_SIZE
 window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
 window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
 window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
 window.min_size = Vector2i(640,400)
 UIStyle.apply(self)
 collection=preload("res://scripts/ui/collection.gd").new()
 collection.name="Collection"
 add_child(collection)
 collection.closed.connect(func() -> void: collection.hide(); $Menu/Layout/Collection.grab_focus())
 $Menu/Layout/Collection.pressed.connect(collection.open)
 route = preload("res://scripts/ui/round_map.gd").new()
 route.name="RoundMap"
 add_child(route)
 route.entered.connect(enter_route)
 route.returned.connect(close_route)
 $Shop.continue_requested.connect(next_route)
 candy_guide=preload("res://scripts/ui/candy_guide.gd").new()
 candy_guide.name="CandyGuide"
 add_child(candy_guide)
 candy_guide.closed.connect(close_candy_guide)
 $Play/CandyGuideButton.pressed.connect(show_candy_guide)
 $Shop/CandyGuideButton.pressed.connect(show_candy_guide)
 $Menu/Layout/Play.pressed.connect(begin_run)
 $Menu/Layout/Codex.pressed.connect(show_codex)
 $Menu/Layout/Quit.pressed.connect(func() -> void: get_tree().quit())
 $Play/Hint.pressed.connect(board.hint)
 $Play/Rules.pressed.connect(show_codex)
 $Play/MenuButton.pressed.connect(toggle_pause)
 $Shop/PauseButton.pressed.connect(toggle_pause)
 $Pause/Layout/Resume.pressed.connect(toggle_pause)
 $Pause/Layout/Options.pressed.connect(show_options.bind(true))
 $Pause/Layout/Back.pressed.connect(show_options.bind(false))
 $Pause/Layout/Quit.pressed.connect(func() -> void: get_tree().quit())
 $Pause/Layout/Abandon.pressed.connect(to_menu)
 $Pause/Layout/Motion.button_pressed = GameManager.motion
 $Pause/Layout/Sound.button_pressed = GameManager.sound
 $Pause/Layout/Motion.toggled.connect(func(value: bool) -> void: GameManager.motion = value; GameManager.save_preferences())
 $Pause/Layout/Sound.toggled.connect(func(value: bool) -> void: GameManager.sound = value; GameManager.save_preferences())
 $Codex/Layout/Close.pressed.connect(close_codex)
 $GameOverScreen.restart_requested.connect(begin_run)
 $GameOverScreen.menu_requested.connect(to_menu)
 GameManager.round_started.connect(round_started)
 GameManager.shop_opened.connect(open_shop)
 GameManager.run_ended.connect(end_run)
 GameManager.toast.connect(show_toast)
 board.special_triggered.connect(on_special)
 $Play/JokerInventory.inspect_requested.connect($Shop.inspect_owned)
 $Menu.visible = true
 $Play.visible = false
 fill_codex()
func show_candy_guide() -> void:
 if board.busy: return
 board.paused=true
 candy_guide.show_candies()
func close_candy_guide() -> void:
 candy_guide.visible=false
 board.paused=$Pause.visible or $Codex.visible
func begin_run() -> void:
 route_new_run=true
 route.show_round(0)
func next_route() -> void:
 route_new_run=false
 route.show_round(GameManager.round_index+1)
func enter_route() -> void:
 route.visible=false
 if route_new_run: start()
 else: GameManager.next_round()
func close_route() -> void:
 route.visible=false
func start() -> void:
 set_paused(false)
 $Menu.visible = false
 $GameOverScreen.visible = false
 $Pause.visible = false
 board.paused = false
 var seed_text: String = $Menu/Layout/Seed.text.strip_edges()
 GameManager.start_run(seed_text.to_int() if seed_text.is_valid_int() else 0)
func round_started() -> void:
 set_gameplay_visible(true)
 $Menu.visible = false
 $GameOverScreen.visible = false
 $Shop.visible = false
 $Play.visible = true
 $Play/RoundLabel.text = "BATCH %02d   /   %s" % [GameManager.round_index+1,GameManager.current_round().display_name.to_upper()]
 $Play/Seed.text = "SEED %s" % GameManager.run_seed
 show_toast(GameManager.current_round().description)
func open_shop() -> void:
 $Toast.text = ""
 board.juice.clear_effects()
 $Play.visible = true
 set_gameplay_visible(false)
 $Shop.visible = true
 $Shop.selected = null
 $Shop.refresh()
func end_run(won: bool) -> void:
 board.juice.clear_effects()
 $Play.visible = false
 $GameOverScreen.show_result(won)
func to_menu() -> void:
 set_paused(false)
 if board.busy:
  GameManager.state = "leaving"
  await board.resolution_finished
 GameManager.state = "menu"
 $Play.visible = false
 $Shop.visible = false
 $GameOverScreen.visible = false
 $Pause.visible = false
 $Menu.visible = true
 board.paused = false
func toggle_pause() -> void:
 if GameManager.state not in ["playing","shop"]: return
 set_paused(not $Pause.visible)
func set_paused(value: bool) -> void:
 $Pause.visible = value
 $PauseShade.visible = value
 board.paused = value
 get_tree().paused = value
 show_options(false)
func show_options(value: bool) -> void:
 $Pause/Layout/Title.text = "OPTIONS" if value else "PAUSED"
 for key: String in ["Motion","Sound","Back"]: $Pause/Layout.get_node(key).visible = value
 for key: String in ["Resume","Options","Abandon","Quit"]: $Pause/Layout.get_node(key).visible = not value
func show_codex() -> void:
 if board.busy: return
 $Codex.visible = true
 board.paused = true
func close_codex() -> void:
 $Codex.visible = false
 board.paused = false
func fill_codex() -> void:
 var text: String = "[font_size=27][color=#ffd06a]The confectioner's handbook[/color][/font_size]\n\nClick a candy, then an adjacent candy to swap. Or use arrows + Enter. H shows a free hint. Invalid swaps consume a move and break your streak.\n\n[b]Score = Candys x Mult[/b]\nCandy values: 10 / 14 / 20 / 30 / 45 / 70 Candys. Higher-value types spawn less often. Open Candy Guide to see current spawn odds. Match 3 for x1, 4 for x2, 5 for x3. Each cascade adds +0.5 Mult. Score only beats the quota; it never converts to cash. Start with $4. Small / Big / Boss clears pay $5 / $7 / $10, plus $1 per 3 unused moves (maximum $3). Rerolls start at $3 and rise by $2 per use; selling returns half price, rounded down.\n\nWin eighteen batches across six antes. Rounds end automatically once your score (after any poison tax) meets the quota. The final-move bonus applies only when starting a move with one left.\n\n[b]Your recipe[/b]\nEquip up to five different Jokers in any combination. All 4+ Jokers trigger together on matches of 4 or more; all 5+ Jokers join them on matches of 5 or more. Effects run in a fixed order: repaint, attract, hammer, ricochet, revive, gild, nuclear, wild. Buying order does not matter. Sell in the shop for half price. With no triggered Joker effect, four clears a line and five clears its color. Wild activations clear up to three of each color and do not trigger 4+/5+ effects, even with Labyrinth. Each candy scores once per cascade wave.\n\n[b]Board marks[/b]\nFrames mark blockers; padlocks mark locked colors. Match 3 including the candy inside either to break it. Framed tiles stay in place; align candies around them. Nearby matches also break them. Each broken tile gives its candy value plus 10 / 25 / 50 Candys for matches of 3 / 4 / 5+, before Mult. Gold outline = 80 + type upgrade bonus; caramel underline = 30 + type upgrade bonus; green outline = persistent x4 isotope; diamond overlay = Wild Prism. Blockers anchor gravity. Specials can destroy locked candies. Dead blocker positions remain available to Necromancer until revived.\n\n[b]Bosses[/b]\nInspector holds one color in place during falls. You can swap it and match 3 including it to break the locks. Heatwave blocks candies that remain untouched for four moves. A board with no legal moves reshuffles automatically, free of charge.\n\n"
 text += "[b]Candy upgrades[/b]\nShop > Candy Upgrades raises each type's value for this run. Repeat buys stack without using Joker slots. Each type starts at $4; its next price rises by $2 per buy. Bonuses also add to gold and caramel. Candy Guide shows current values. New runs reset all upgrades.\n\n"
 text += "[b]Supply Jokers[/b]\nEach doubles the spawn weight of its candy type. Weights are normalized together; different Supply Jokers stack. Odds apply to new random draws, not a guaranteed board composition.\n\n"
 for item: JokerData in GameManager.config.jokers:
  text += "[color=#f67899][b]%s[/b][/color] | %s | $%s\n%s\n\n" % [item.display_name,item.category,item.price,item.description]
 $Codex/Layout/Text.text = text
func show_toast(message: String) -> void:
 $Toast.text = message
 $Toast.modulate.a = 1.0
 if toast_tween: toast_tween.kill()
 toast_tween = create_tween()
 toast_tween.tween_interval(4.0)
 toast_tween.tween_property($Toast,"modulate:a",0.0,0.4)
func on_special(effect: String, _origin: Vector2) -> void:
 show_toast(effect.replace("_"," ").to_upper()+"!")
 if not GameManager.motion: return
 if shake: shake.kill()
 board.position = Vector2(452,216)
 shake = create_tween()
 for offset: Vector2 in [Vector2(4,-3),Vector2(-3,2),Vector2(2,-1),Vector2.ZERO]:
  shake.tween_property(board,"position",Vector2(452,216)+offset,0.045)
func _unhandled_key_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):
  if collection.visible: collection.closed.emit()
  elif candy_guide.visible: close_candy_guide()
  elif route.visible: close_route()
  elif $Codex.visible: close_codex()
  elif $Pause.visible and $Pause/Layout/Back.visible: show_options(false)
  else: toggle_pause()
  get_viewport().set_input_as_handled()

func set_gameplay_visible(value: bool) -> void:
 for path: String in ["CandyGuideButton","GameBoard","Hint","Rules","MenuButton","Instruction","MatchGuide","Seed"]:
  $Play.get_node(path).visible = value
