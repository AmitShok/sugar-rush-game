extends Control
@onready var board: GameBoard = $Play/GameBoard
const DESIGN_SIZE: Vector2i = Vector2i(1152,720)
var shake: Tween
var collection: Control
var item_panel: Control
var pack_panel: Control
var candy_guide: Control
var route: Control
var route_new_run: bool = true
# Seed chosen when the new-run route opens, so its skip Tags can be previewed.
var pending_seed: int = 0
var options_from_menu: bool = false
var crt_layer: CanvasLayer
var toast_tween: Tween
var run_save: Node
var quitting: bool=false
var joker_details: Control
func _enter_tree() -> void:
 # The game currently ships only English text and a fixed LTR layout. Set its
 # locale before child UI is built: unattached Controls otherwise use the OS
 # locale and can mirror their offsets before inheriting the parent's direction.
 TranslationServer.set_locale("en")
func _ready() -> void:
 # A fixed logical canvas keeps drawing and native GUI input in the same space.
 # Physical window dimensions may change freely without changing game geometry.
 var window: Window = get_window()
 window.title = "Sugar Rush | v0.31 - Sugar Beats"
 window.content_scale_size = DESIGN_SIZE
 window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
 window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
 window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
 if not OS.has_feature("web"): window.min_size = Vector2i(640,400)
 UIStyle.apply(self)
 apply_button_roles()
 add_backdrop_drift()
 crt_layer=CanvasLayer.new()
 crt_layer.name="CRT"
 crt_layer.layer=100
 add_child(crt_layer)
 var overlay: ColorRect=ColorRect.new()
 overlay.name="Screen"
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var crt_material: ShaderMaterial=ShaderMaterial.new()
 # Reduce mobile WebGL work: keep web CRT as a blended overlay without
 # the screen texture copies and multi-sample glow used on desktop.
 crt_material.shader=preload("res://shaders/crt_web.gdshader") if OS.has_feature("web") else preload("res://shaders/crt.gdshader")
 overlay.material=crt_material
 crt_layer.add_child(overlay)
 crt_layer.visible=GameManager.crt_enabled
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
 route.skipped.connect(skip_route)
 item_panel=preload("res://scripts/ui/consumable_panel.gd").new()
 item_panel.name="Consumables"
 add_child(item_panel)
 item_panel.closed.connect(close_items)
 item_panel.use_requested.connect(use_item)
 pack_panel=preload("res://scripts/ui/pack_panel.gd").new()
 pack_panel.name="PackPanel"
 add_child(pack_panel)
 $Shop.consumables_requested.connect(open_items)
 $Shop.continue_requested.connect(next_route)
 candy_guide=preload("res://scripts/ui/candy_guide.gd").new()
 candy_guide.name="CandyGuide"
 add_child(candy_guide)
 candy_guide.closed.connect(close_candy_guide)
 $Play/CandyGuideButton.pressed.connect(show_candy_guide)
 $Shop/CandyGuideButton.pressed.connect(show_candy_guide)
 $Menu/Layout/Play.pressed.connect(begin_run)
 $Menu/Layout/Options.pressed.connect(open_menu_options)
 $Menu/Layout/Quit.pressed.connect(quit_game)
 $Play/Hint.pressed.connect(board.hint)
 $Play/Shaker.icon=UIStyle.texture("sugar_shaker")
 $Play/Shaker.pressed.connect(open_items)
 GameManager.changed.connect(refresh_consumables)
 refresh_consumables()
 $Play/Rules.pressed.connect(show_codex)
 $Play/MenuButton.pressed.connect(toggle_pause)
 $Shop/PauseButton.pressed.connect(toggle_pause)
 $Pause/Layout/Resume.pressed.connect(toggle_pause)
 $Pause/Layout/Options.pressed.connect(show_options.bind(true))
 $Pause/Layout/Back.pressed.connect(close_options)
 $Pause/Layout/Quit.pressed.connect(quit_game)
 $Pause/Layout/Abandon.pressed.connect(to_menu)
 $Pause/Layout/Motion.button_pressed = GameManager.motion
 $Pause/Layout/Sound.button_pressed = GameManager.sound
 $Pause/Layout/CRT.button_pressed = GameManager.crt_enabled
 $Pause/Layout/Volume/Slider.value = GameManager.master_volume*100.0
 $Pause/Layout/Volume/Label.text = "Volume: %s%%" % roundi(GameManager.master_volume*100.0)
 $Pause/Layout/CRT.toggled.connect(func(value: bool) -> void: GameManager.crt_enabled=value; crt_layer.visible=value; GameManager.save_preferences())
 $Pause/Layout/Volume/Slider.value_changed.connect(func(value: float) -> void: GameManager.master_volume=value/100.0; $Pause/Layout/Volume/Label.text="Volume: %s%%" % roundi(value); GameManager.save_preferences())
 $Pause/Layout/Motion.toggled.connect(func(value: bool) -> void: GameManager.motion = value; GameManager.save_preferences())
 $Pause/Layout/Sound.toggled.connect(func(value: bool) -> void: GameManager.sound = value; GameManager.save_preferences())
 $Pause/Layout/Music.button_pressed = GameManager.music
 $Pause/Layout/Music.toggled.connect(func(value: bool) -> void: GameManager.music = value; GameManager.save_preferences(); SoundBoard.refresh_volume())
 $Codex/Layout/Close.pressed.connect(close_codex)
 $GameOverScreen.restart_requested.connect(begin_run)
 $GameOverScreen.menu_requested.connect(to_menu)
 GameManager.round_started.connect(round_started)
 GameManager.shop_opened.connect(open_shop)
 GameManager.run_ended.connect(end_run)
 GameManager.toast.connect(show_toast)
 board.special_triggered.connect(on_special)
 $Play/JokerInventory.inspect_requested.connect(inspect_joker)
 $Menu.visible = true
 SoundBoard.play_track("shop")
 $Play.visible = false
 fill_codex()
 run_save=preload("res://scripts/run_save.gd").new()
 run_save.main=self
 add_child(run_save)
 $Menu/Layout/Continue.pressed.connect(continue_run)
 refresh_continue()
 get_tree().auto_accept_quit=false
 if OS.has_feature("web"):
  $Menu/Layout/Quit.hide()
  $Pause/Layout/Abandon.text="Save & Return to Title"
  $Pause/Layout/Quit.hide()
  if not OS.is_userfs_persistent(): show_toast("Browser storage unavailable | progress may not survive closing this tab")
func refresh_continue() -> void:
 $Menu/Layout/Continue.disabled=not run_save.has_save()
 $Menu/Layout/Continue.tooltip_text="Resume your saved run, including after Quit to Title."
func continue_run() -> void:
 if run_save.restore():
  set_paused(false)
  round_started()
  if GameManager.state=="shop": open_shop()
  GameManager.changed.emit()
 else:
  show_toast("Saved run could not be loaded. You can start a New Run.")
  refresh_continue()
func _notification(what: int) -> void:
 if what==NOTIFICATION_WM_CLOSE_REQUEST: quit_game()
func quit_game() -> void:
 if OS.has_feature("web"):
  await to_menu()
  return
 if quitting: return
 quitting=true
 set_paused(false)
 board.paused=false
 if board.busy:
  if board.shaking: await board.shuffle_finished
  else: await board.resolution_finished
 run_save.checkpoint()
 get_tree().quit()
func inspect_joker(item: JokerData) -> void:
 if GameManager.state=="shop":
  $Shop.inspect_owned(item)
  return
 if board.busy or GameManager.state!="playing": return
 board.paused=true
 joker_details=Control.new()
 joker_details.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 joker_details.z_index=190
 add_child(joker_details)
 var shade: TextureRect=TextureRect.new()
 shade.texture=UIStyle.texture("ui_shade")
 shade.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 joker_details.add_child(shade)
 var panel: PanelContainer=PanelContainer.new()
 panel.position=Vector2(216,160)
 panel.size=Vector2(720,400)
 joker_details.add_child(panel)
 var column: VBoxContainer=VBoxContainer.new()
 panel.add_child(column)
 column.add_child(UIStyle.label(GameManager.joker_title(item),32,UIStyle.MINT))
 var description: RichTextLabel=UIStyle.rich_label(GameManager.joker_text(item),24)
 description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 description.custom_minimum_size=Vector2(660,240)
 column.add_child(description)
 var close: Button=Button.new()
 close.name="Close"
 close.text="Back to the round"
 close.custom_minimum_size.y=52
 close.pressed.connect(close_joker_details)
 column.add_child(close)
func close_joker_details() -> void:
 if is_instance_valid(joker_details):
  joker_details.queue_free()
  joker_details=null
 board.paused=false
func open_items() -> void:
 if not board.target_consumable.is_empty():
  board.cancel_consumable_target()
  return
 board.paused=true
 item_panel.open(GameManager.state=="shop")
func close_items() -> void:
 item_panel.hide()
 board.paused=$Pause.visible or $Codex.visible or candy_guide.visible
func use_item(id: String) -> void:
 close_items()
 board.request_consumable(id)
func refresh_consumables() -> void:
 $Play/Hint.text="Hint $%s" % GameManager.hint_cost()
 $Play/Hint.tooltip_text="Show a legal swap for $%s. Each purchase raises the price by $1 for this run. Shortcut: H." % GameManager.hint_cost()
 $Play/Hint.disabled=GameManager.gummies < GameManager.hint_cost()
 $Play/Shaker.text=("Cancel target" if not board.target_consumable.is_empty() else "Items %s / 2" % GameManager.consumables.size())
 $Play/Shaker.disabled=false
 $Play/Shaker.tooltip_text="Open your two-slot consumable inventory. Targeted cards let you choose a candy; Esc cancels."
 refresh_recipe_guide()
func refresh_recipe_guide() -> void:
 # Live recipe table: last scored recipe is marked with ">".
 var lines: PackedStringArray = ["RECIPES"]
 for id: String in RecipeCatalog.ORDER:
  if id == "diagonal" and not GameManager.jokers.has("kaleidoscope") and GameManager.recipe_level(id) <= 1: continue
  var lvl: int = GameManager.recipe_level(id)
  lines.append("%s%s %s  %sx%s" % [">" if id == GameManager.last_recipe else " ",RecipeCatalog.ITEMS[id].short,lvl,RecipeCatalog.candys(id,lvl),RecipeCatalog.mult(id,lvl)])
 $Play/MatchGuide.text = "\n".join(lines)
func show_candy_guide() -> void:
 if board.busy: return
 board.paused=true
 candy_guide.show_candies()
func close_candy_guide() -> void:
 candy_guide.visible=false
 board.paused=$Pause.visible or $Codex.visible
func begin_run() -> void:
 route_new_run=true
 var seed_text: String = $Menu/Layout/Seed.text.strip_edges()
 pending_seed = seed_text.to_int() if seed_text.is_valid_int() and seed_text.to_int() != 0 else int(Time.get_unix_time_from_system())
 route.preview_seed = pending_seed
 route.show_round(0)
func next_route() -> void:
 route.preview_seed = -1
 route_new_run=false
 route.show_round(GameManager.round_index+1)
func enter_route() -> void:
 route.visible=false
 if route_new_run: start()
 else: GameManager.next_round()
func skip_route() -> void:
 # A new run starts first so its opening Small batch can be skipped.
 if route_new_run:
  start()
  route_new_run = false
 var tag: String = GameManager.skip_round()
 if tag.is_empty(): return
 show_toast("Skipped: "+TagCatalog.ITEMS[tag].name)
 route.preview_seed = -1
 route.show_round(GameManager.round_index+1)
func close_route() -> void:
 route.visible=false
func start() -> void:
 set_paused(false)
 $Menu.visible = false
 $GameOverScreen.visible = false
 $Pause.visible = false
 board.paused = false
 var seed_text: String = $Menu/Layout/Seed.text.strip_edges()
 var chosen: int = seed_text.to_int() if seed_text.is_valid_int() else 0
 if chosen == 0: chosen = pending_seed
 pending_seed = 0
 route.preview_seed = -1
 GameManager.start_run(chosen)
func round_started() -> void:
 set_gameplay_visible(true)
 $Menu.visible = false
 $GameOverScreen.visible = false
 $Shop.visible = false
 $Play.visible = true
 $Play/RoundLabel.text = "BATCH %02d   /   %s" % [GameManager.round_index+1,GameManager.round_name(GameManager.round_index).to_upper()]
 $Play/Seed.text = "SEED %s" % GameManager.run_seed
 if GameManager.curse() != "none": show_toast(GameManager.round_name(GameManager.round_index).to_upper()+": "+GameManager.round_description(GameManager.round_index))
func open_shop() -> void:
 close_items()
 $Toast.text = ""
 board.juice.clear_effects()
 $Play.visible = true
 set_gameplay_visible(false)
 $Shop.visible = true
 $Shop.selected = null
 $Shop.refresh()
func end_run(won: bool) -> void:
 close_items()
 board.juice.clear_effects()
 $Play.visible = false
 $GameOverScreen.show_result(won)
func to_menu() -> void:
 close_joker_details()
 run_save.checkpoint()
 close_items()
 set_paused(false)
 if board.busy:
  if board.shaking: await board.shuffle_finished
  else: await board.resolution_finished
 run_save.checkpoint()
 GameManager.state = "menu"
 $Play.visible = false
 $Shop.visible = false
 $GameOverScreen.visible = false
 $Pause.visible = false
 $Menu.visible = true
 SoundBoard.play_track("shop")
 board.paused = false
 refresh_continue()
 if not $Menu/Layout/Continue.disabled:
  $Menu/Layout/Continue.grab_focus()
  show_toast("Run saved")
func toggle_pause() -> void:
 if GameManager.state not in ["playing","shop"]: return
 set_paused(not $Pause.visible)
func set_paused(value: bool) -> void:
 if not value: options_from_menu=false
 $Pause.visible = value
 $PauseShade.visible = value
 SoundBoard.set_ducked(value)
 board.paused = value
 get_tree().paused = value
 show_options(false)
func open_menu_options() -> void:
 set_paused(true)
 options_from_menu=true
 show_options(true)
 $Pause/Layout/CRT.grab_focus()
func close_options() -> void:
 if options_from_menu:
  set_paused(false)
  $Menu/Layout/Options.grab_focus()
 else: show_options(false)
func show_options(value: bool) -> void:
 $Pause/Layout/Title.text = "OPTIONS" if value else "PAUSED"
 for key: String in ["Motion","Sound","Music","CRT","Volume","Back"]: $Pause/Layout.get_node(key).visible = value
 for key: String in ["Resume","Options","Abandon","Quit"]: $Pause/Layout.get_node(key).visible = not value and (key!="Quit" or not OS.has_feature("web"))
func show_codex() -> void:
 if board.busy: return
 $Codex.visible = true
 board.paused = true
func close_codex() -> void:
 $Codex.visible = false
 board.paused = false
func fill_codex() -> void:
 var text: String = "[font_size=27][color=#ffd06a]The confectioner's handbook[/color][/font_size]\n\nClick a candy, then an adjacent candy to swap. Or use arrows + Enter. H buys a hint: $1 at first, then $1 more after each purchase for the rest of the run. Hints do not consume moves. Invalid swaps consume a move and break your streak.\n\n[b]Score = Candys x Mult[/b]\nCandy values: 10 / 14 / 20 / 30 / 45 / 70 Candys. Higher-value types spawn less often. Open Candy Guide to see current spawn odds. Every match is a [b]recipe[/b] that adds its own Candys and Mult: Trio (line of 3) 0 x1, Quad (4) 10 x2, Quint (5+) 30 x3, L/T Shape 20 x3, Diagonal 10 x2. Level recipes up with Recipe Packs (and Cookbook rewards) for more of both. Each cascade wave adds +0.5 Mult, up to +2. Score only beats the quota; it never converts to cash. Start with $4. Small / Big / Boss clears pay $5 / $7 / $10, plus $1 per 3 unused moves (maximum $3), plus interest: $1 for every $5 you hold when the round ends (maximum $5). On the route preview you can skip a Small or Big batch: you give up its cash and its shop, and claim the Tag shown on its card (Piggy, Handout, Cookbook, Reroll, Sweets or Extra Moves). Bosses cannot be skipped. The shop's Packs tab sells two booster packs per shop (rerolls keep them): Joker, Recipe, Candy and Treat packs show a few cards and you keep one (two in some Jumbo packs), and rare Sugar Rush packs hold powerful one-off cards. Rerolls start at $3 and rise by $2 per use; selling returns half price, rounded down.\n\nWin eighteen batches across six antes. Rounds end automatically once your score (after any poison tax) meets the quota. The final-move bonus applies only when starting a move with one left.\n\n[b]Your recipe[/b]\nEquip up to five different Jokers in any combination. Jokers add their score bonuses from left to right, so put +Mult Jokers before xMult Jokers; select an owned Joker in the shop and use < Move / Move > to reorder. Shop Jokers sometimes roll an edition that applies to every match: Foil +50 Candys, Holographic +4 Mult, Polychrome x1.5 Mult (they cost $2 / $3 / $5 more). Scaling Jokers grow for the rest of the run: Sugar Cube, Gumball Jar and Candy Cane. All 4+ Jokers trigger together on matches of 4 or more; all 5+ Jokers join them on matches of 5 or more. Effects run in a fixed order: repaint, attract, hammer, ricochet, revive, gild, nuclear, wild. Buying order does not matter. Sell in the shop for half price. Matches of 4 and 5 no longer blast on their own: special candies come from Jokers. Ribbon Striper turns a line of 4 into a Striped candy (clears its row or column), Candy Wrapper turns an L/T match into a Wrapped candy (3x3 blast) and Bomb Maker turns a line of 5 into a Color Bomb (swap it to clear a candy type). Specials fire when matched or caught in a blast and add Mult: Striped +4, Wrapped +6, Color Bomb +10. Swap two specials (x3 Mult combo) together for a combo: Striped+Striped clears a cross, Striped+Wrapped a 3-wide cross, Wrapped+Wrapped a 5x5 area, Color Bomb+special turns that type into the special and fires them all, and two Color Bombs clear the board. Wild activations clear up to three of each color and do not trigger 4+/5+ effects, even with Labyrinth. Each candy scores once per cascade wave.\n\n[b]Board marks[/b]\nFrames mark blockers; padlocks mark locked colors. Match 3 including the candy inside either to break it. Framed tiles stay in place; align candies around them. Nearby matches also break them. Each broken tile gives its candy value plus 10 / 25 / 50 Candys for matches of 3 / 4 / 5+, before Mult. Gold outline = 80 + type upgrade bonus; caramel underline = 30 + type upgrade bonus; green outline = persistent x4 isotope; diamond overlay = Wild Prism. Blockers anchor gravity. Specials can destroy locked candies. Dead blocker positions remain available to Necromancer until revived.\n\n[b]Bosses[/b]\nEach run draws one boss per ante from nine, never repeating; the route preview shows them. Inspector holds one candy type in place during falls (match 3 including it to break the locks). Heatwave turns candies untouched for four moves into blockers. Chocolatier: chocolate tiles spread onto a neighbor after any move that breaks none; match beside them or blast them. Frost: two-layer frosting blocks the middle; each nearby match or blast removes a layer. Sour Patch: one candy type scores 0 Candys. Tiny Spoon: all Mult is halved. Jelly Mould: half the cells are jelly; a match that clears no jelly scores half. Sugar Tax: every move costs $1 while you have cash. Rush Hour: 3 fewer moves. Obstacles anchor gravity and give the usual breaking bonus. A board with no legal moves reshuffles automatically, free of charge.\n\n"
 text += "[b]Consumables[/b]\nEach shop refresh offers two random consumable cards, each purchasable once. Refresh restocks both Jokers and consumables. Carry any two, separately from Jokers, and open Items during a round to use one. Sugar Shaker ($4) safely rearranges unlocked candies. Extra Serving ($6) adds two moves. Golden Glaze ($7) gilds the selected candy type currently on the board, except Wilds. Candy Hammer ($5) smashes one candy, including its frame, then resolves refill matches. Targeted cards are spent only after choosing a valid candy; Esc cancels. Items cost no moves. Requests during a cascade wait until it ends; if the round ends first, the item is kept. Unused cards carry between rounds and reset on a new run.\n\n"
 text += "[b]Candy upgrades[/b]\nCandy Packs (shop > Packs) raise one type's value for this run; levels stack with no cap. The Candies tab shows current values. Bonuses also add to gold and caramel. Candy Guide shows current values. New runs reset all upgrades.\n\n"
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
 # Brief board flash for special effects.
 if GameManager.motion:
  board.modulate = Color(1.35,1.3,1.35)
  create_tween().tween_property(board,"modulate",Color.WHITE,0.25)
 if not GameManager.motion: return
 if shake: shake.kill()
 board.position = Vector2(452,216)
 shake = create_tween()
 for offset: Vector2 in [Vector2(4,-3),Vector2(-3,2),Vector2(2,-1),Vector2.ZERO]:
  shake.tween_property(board,"position",Vector2(452,216)+offset,0.045)
func _unhandled_key_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):
  if is_instance_valid(joker_details): close_joker_details()
  elif item_panel.visible: close_items()
  elif not board.target_consumable.is_empty(): board.cancel_consumable_target()
  elif collection.visible: collection.closed.emit()
  elif candy_guide.visible: close_candy_guide()
  elif route.visible: close_route()
  elif $Codex.visible: close_codex()
  elif $Pause.visible and $Pause/Layout/Back.visible: close_options()
  else: toggle_pause()
  get_viewport().set_input_as_handled()

func set_gameplay_visible(value: bool) -> void:
 for path: String in ["Shaker","CandyGuideButton","GameBoard","Hint","Rules","MenuButton","Instruction","MatchGuide","Seed"]:
  $Play.get_node(path).visible = value
# v0.24 candy-shop art: colour-coded buttons by what they do.
const BUTTON_ROLES: Dictionary = {
 "go": ["Menu/Layout/Play","Menu/Layout/Continue","Pause/Layout/Resume","GameOverScreen/Layout/Restart","Shop/Actions/Continue"],
 "info": ["Menu/Layout/Collection","Play/Rules","Play/CandyGuideButton","Shop/CandyGuideButton","Play/Shaker"],
 "skip": ["Play/Hint"],
 "danger": ["Menu/Layout/Quit","Pause/Layout/Quit","Pause/Layout/Abandon"],
 "neutral": ["Menu/Layout/Options","Play/MenuButton","Pause/Layout/Options","Pause/Layout/Back","Codex/Layout/Close","GameOverScreen/Layout/Menu","Shop/PauseButton"],
 "buy": ["Shop/Actions/Reroll"],
}
func apply_button_roles() -> void:
 for kind: String in BUTTON_ROLES:
  for path: String in BUTTON_ROLES[kind]:
   var button: Button = get_node_or_null(path) as Button
   if button: UIStyle.role(button,kind)
# Balatro-style swirling candy paint behind everything (v0.25 shader; the painted table stays underneath).
var swirl: ColorRect
var swirl_clock: float = 0.0
func add_backdrop_drift() -> void:
 swirl = ColorRect.new()
 swirl.name = "CandySwirl"
 swirl.mouse_filter = Control.MOUSE_FILTER_IGNORE
 swirl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var material: ShaderMaterial = ShaderMaterial.new()
 material.shader = preload("res://shaders/candy_swirl.gdshader")
 swirl.material = material
 add_child(swirl)
 move_child(swirl,$Background.get_index()+1)
func _process(delta: float) -> void:
 if swirl == null: return
 if GameManager.motion: swirl_clock += delta
 (swirl.material as ShaderMaterial).set_shader_parameter("clock",swirl_clock)
