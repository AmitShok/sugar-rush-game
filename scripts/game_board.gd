class_name GameBoard
extends Control
signal matches_resolved(result: Dictionary, color: int)
signal move_made(valid: bool)
signal special_triggered(effect: String, origin: Vector2)
signal shuffle_finished
signal resolution_finished
@export var columns: int = 8
@export var rows: int = 8
@export var starting_blockers: Array[int] = [18,45]
@export var cell_size: float = 56.0
@export var swap_duration: float = 0.16
@export var fall_duration: float = 0.22
@export var tile_scene: PackedScene = preload("res://scenes/Tile.tscn")
var model: BoardModel = BoardModel.new()
var tiles: Array[SugarTile] = []
var movement_tweens: Array[Tween] = []
var busy: bool = false
var paused: bool = false
var shake_queued: bool = false
var shaking: bool = false
var queued_consumable: String = ""
var target_consumable: String = ""
var selection: int = -1
# Drag-to-swap (mouse and touch): the cell pressed and where the press started.
var drag_from: int = -1
var drag_start: Vector2 = Vector2.ZERO
var drag_target: int = -1 # Neighbour the drag currently points at (released = swap).
var preview_pair: Vector2i = Vector2i(-1,-1)
const DRAG_THRESHOLD: float = 0.4 # Fraction of a cell the pointer must travel to aim at a neighbour.
var cursor: int = 0
var final_move: bool = false
var population: int = 0
@onready var juice: SugarJuice = $Juice
@onready var audio: AudioStreamPlayer = $Audio
func _ready() -> void:
 $Frame.add_theme_stylebox_override("panel",UIStyle.skin("ui_inset"))
 matches_resolved.connect(GameManager.award)
 move_made.connect(GameManager.begin_move)
 resolution_finished.connect(GameManager.finish_move)
 resolution_finished.connect(flush_shake_request)
 shuffle_finished.connect(flush_shake_request)
 GameManager.round_started.connect(start_round)
func start_round() -> void:
 juice.clear_effects()
 shake_queued=false
 queued_consumable=""
 target_consumable=""
 shaking=false
 $Tiles.position=Vector2.ZERO
 busy = false
 selection = -1
 model.width = columns
 model.height = rows
 model.setup(GameManager.config,GameManager.jokers,GameManager.run_seed+GameManager.round_index*7919)
 model.locked_color = model.rng.randi_range(0,GameManager.config.candies.size()-1) if GameManager.curse() == "inspector" else -1
 model.candy_bonuses = GameManager.candy_bonuses
 model.fill_fresh()
 # Persistent obstacles give destruction/revival builds targets in every round.
 for i: int in starting_blockers:
  if i >= 0 and i < model.cells.size(): model.cells[i].blocker = 2
 model.jelly_count = BossCatalog.jelly_count(GameManager.round_index/3)
 model.setup_boss(GameManager.curse())
 if model.legal_moves().is_empty(): model.reshuffle()
 sync_tiles(false)
func sync_tiles(falling: bool) -> void:
 # The Jelly Mould round is only won once every jelly tile is cleared.
 GameManager.jelly_left = model.jelly.size()
 for tween: Tween in movement_tweens:
  if tween and tween.is_valid(): tween.kill()
 movement_tweens.clear()
 var old: Dictionary = {}
 for tile: SugarTile in tiles:
  if is_instance_valid(tile): old[tile.data] = tile
 tiles.clear()
 for i: int in range(model.cells.size()):
  var state: CandyState = model.cells[i]
  var tile: SugarTile
  if old.has(state):
   tile = old[state]
   old.erase(state)
  else:
   tile = tile_scene.instantiate() as SugarTile
   $Tiles.add_child(tile)
   tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
   tile.position = Vector2(model.xy(i))*cell_size-Vector2(0,cell_size*2)
  tile.configure(i,state,GameManager.config,i in model.isotopes,state.color==model.locked_color,model.candy_bonus(state.color),GameManager.jokers.has("roulette") and state.color==GameManager.poison and not state.obstacle())
  tile.jelly = i in model.jelly
  tile.sour = state.color == model.sour_color
  if tile.jelly: tile.tooltip_text += " | Jelly: clear every jelly tile to win"
  if tile.sour and not state.obstacle(): tile.tooltip_text += " | SOUR: scores 0 Candys"
  tile.selected = i == selection
  tile.hinted = false
  tile.scale = Vector2.ONE
  tile.modulate = Color.WHITE
  var target: Vector2 = Vector2(model.xy(i))*cell_size
  if falling and GameManager.motion:
   var movement: Tween = tile.create_tween()
   # Falling candies land with a small bounce.
   movement.tween_property(tile,"position",target,fall_duration).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
   movement_tweens.append(movement)
  else: tile.position = target
  tiles.append(tile)
 for tile: SugarTile in old.values(): tile.queue_free()
func cancel_consumable_target() -> void:
 target_consumable=""
 sync_tiles(false)
 GameManager.changed.emit()
func request_consumable(id: String) -> void:
 if paused or GameManager.state!="playing" or id not in GameManager.consumables: return
 if id=="sugar_shaker":
  request_shake()
  return
 if busy:
  if queued_consumable.is_empty() and not shake_queued:
   queued_consumable=id
   GameManager.toast.emit("Item queued after this move")
  return
 target_consumable=""
 selection=-1
 if id=="extra_serving":
  GameManager.moves+=2
  GameManager.consume_item(id)
  GameManager.toast.emit("Extra Serving | +2 moves this round")
 else:
  target_consumable=id
  GameManager.toast.emit("%s: choose a candy | Esc cancels" % ConsumableCatalog.ITEMS[id].name)
  for tile: SugarTile in tiles:
   tile.selected=false
   tile.hinted=true
   tile.queue_redraw()
  GameManager.changed.emit()
func use_targeted_consumable(i: int) -> void:
 var id: String=target_consumable
 if busy or paused or GameManager.state!="playing" or id not in GameManager.consumables: return
 if i<0 or i>=model.cells.size() or model.cells[i]==null: return
 var color: int=model.cells[i].color
 if id=="golden_glaze":
  var count: int=0
  for cell: CandyState in model.cells:
   if cell!=null and cell.color==color and cell.coating!=2 and cell.coating!=3:
    cell.coating=2
    count+=1
  if count==0:
   GameManager.toast.emit("No candies to gild | item kept; choose another type")
   return
  target_consumable=""
  GameManager.consume_item(id)
  sync_tiles(false)
  GameManager.toast.emit("Gilded %s %s candies" % [count,GameManager.config.candies[color].display_name])
 elif id=="candy_hammer":
  target_consumable=""
  busy=true
  final_move=false
  population=0
  GameManager.consume_item(id)
  var groups: Array[Dictionary]=[{"cells":[i],"color":color,"length":1,"axis":Vector2i.RIGHT,"shape":false,"diagonal":false,"synthetic":true,"direct":true}]
  await resolve(groups)
  if model.legal_moves().is_empty(): model.reshuffle()
  sync_tiles(false)
  busy=false
  resolution_finished.emit()
func request_shake() -> void:
 if paused or shaking or GameManager.state != "playing" or GameManager.shakers<=0: return
 if busy:
  if not queued_consumable.is_empty(): return
  shake_queued=true
  GameManager.toast.emit("Sugar Shaker queued after this move")
  return
 use_shaker()
func flush_shake_request() -> void:
 if not queued_consumable.is_empty():
  var id: String=queued_consumable
  queued_consumable=""
  if GameManager.state=="playing": call_deferred("request_consumable",id)
  else: GameManager.toast.emit("Round finished | item kept")
 if not shake_queued: return
 shake_queued=false
 if GameManager.state=="playing": call_deferred("request_shake")
 else: GameManager.toast.emit("Round finished | Sugar Shaker kept")
func use_shaker() -> void:
 if busy or paused or GameManager.state != "playing" or GameManager.shakers<=0: return
 busy=true
 shaking=true
 selection=-1
 if not model.shake_candies():
  busy=false
  shaking=false
  GameManager.toast.emit("No safe rearrangement | Sugar Shaker kept")
  return
 GameManager.consume_item("sugar_shaker")
 if GameManager.sound and not "--test" in OS.get_cmdline_user_args():
  audio.pitch_scale=GameManager.next_sound_pitch(0)*0.9
  audio.play()
 if GameManager.motion:
  var tween: Tween=create_tween()
  for offset: Vector2 in [Vector2(-5,0),Vector2(5,0),Vector2(-3,0),Vector2(3,0),Vector2.ZERO]:
   tween.tween_property($Tiles,"position",offset,0.045)
  await tween.finished
 sync_tiles(true)
 if GameManager.motion: await get_tree().create_timer(fall_duration,false).timeout
 busy=false
 shaking=false
 GameManager.toast.emit("Shuffled!")
 shuffle_finished.emit()
func choose(i: int) -> void:
 clear_preview()
 if not target_consumable.is_empty():
  use_targeted_consumable(i)
  return
 if busy or paused or GameManager.state != "playing": return
 if not model.playable(i):
  GameManager.toast.emit("Framed: match it or next to it")
  return
 if selection == i:
  selection = -1
 elif selection >= 0 and model.adjacent(selection,i):
  var first: int = selection
  selection = -1
  attempt_swap(first,i)
  return
 else: selection = i
 for tile: SugarTile in tiles:
  tile.selected = tile.cell_index == selection
  tile.hinted = false
  tile.queue_redraw()
func animate_swap(a: int,b: int) -> void:
 if not GameManager.motion: return
 var tween: Tween = create_tween().set_parallel()
 tween.tween_property(tiles[a],"position",Vector2(model.xy(b))*cell_size,swap_duration)
 tween.tween_property(tiles[b],"position",Vector2(model.xy(a))*cell_size,swap_duration)
 await tween.finished
func attempt_swap(a: int,b: int) -> void:
 if busy or paused or GameManager.state != "playing" or not model.adjacent(a,b) or not model.playable(a) or not model.playable(b): return
 busy = true
 clear_preview()
 selection = -1
 final_move = GameManager.moves == 1
 population = 0
 for cell: CandyState in model.cells:
  if cell.blocker == 0: population += 1
 model.chocolate_broken = 0
 SoundBoard.play("swap")
 await animate_swap(a,b)
 model.swap(a,b)
 var groups: Array[Dictionary] = model.swap_groups(a,b)
 move_made.emit(not groups.is_empty())
 if groups.is_empty():
  model.swap(a,b)
  sync_tiles(true)
  juice.popup("No match",Vector2(model.xy(b))*cell_size,UIStyle.PINK)
  SoundBoard.play("invalid")
  GameManager.toast.emit("No match: -1 move")
  if GameManager.motion: await get_tree().create_timer(fall_duration,false).timeout
 else:
  model.cells[a].age = -1
  model.cells[b].age = -1
  sync_tiles(false)
  await resolve(groups)
 if GameManager.curse() == "heatwave": model.age_candies([a,b])
 if GameManager.curse() == "chocolatier" and GameManager.state == "playing":
  var spread: int = model.spread_chocolate()
  if spread >= 0:
   GameManager.toast.emit("The chocolate spreads!")
   SoundBoard.play("chocolate")
 if model.legal_moves().is_empty():
  model.reshuffle()
  GameManager.toast.emit("No moves left: reshuffled")
 sync_tiles(true)
 if GameManager.motion: await get_tree().create_timer(fall_duration,false).timeout
 busy = false
 resolution_finished.emit()
func resolve(initial: Array[Dictionary]) -> void:
 # One move = one hand (v0.34). Every wave feeds the same MoveHand; the HUD counts the hand up
 # live and the score is awarded once, when the board settles.
 var hand: MoveHand = MoveHand.new()
 var groups: Array[Dictionary] = initial
 var cascade: int = 0
 while not groups.is_empty() and cascade < GameManager.config.cascade_limit:
  var wilds: Array[int] = []
  var spawns: Array[Dictionary] = []
  var wave: Dictionary = model.score_wave(groups,cascade,hand,GameManager.recipe_levels,GameManager.poison)
  var removed: Array[int] = wave.removed
  for n: int in range(groups.size()):
   var group: Dictionary = groups[n]
   var effect: Dictionary = wave.effects[n]
   var fresh_breaks: int = effect.broken.size()
   if fresh_breaks > 0:
    juice.popup("BREAK +%s" % (fresh_breaks*effect.break_bonus),Vector2(model.xy(effect.origin))*cell_size+Vector2(0,40),UIStyle.MINT)
   var point: Vector2 = Vector2(model.xy(effect.origin))*cell_size+Vector2.ONE*28
   var tint: Color = GameManager.config.candies[group.color].tint if int(group.get("color",-1)) >= 0 else UIStyle.CREAM
   # Each group shows the Candys it adds to the hand; the hand total lands once at the end.
   juice.popup("+%s" % int(wave.chips[n]),point,tint)
   juice.burst(point,tint)
   if effect.wild >= 0: wilds.append(effect.wild)
   if not effect.spawn.is_empty(): spawns.append(effect.spawn)
   if group.get("special_swap",false) or not effect.fired.is_empty():
    special_triggered.emit("special combo" if group.get("special_swap",false) else "special candy",point)
   if "gravity" in effect.effects and GameManager.motion:
    for i: int in effect.cells:
     if i not in group.cells:
      create_tween().tween_property(tiles[i],"position",point-Vector2.ONE*28,0.15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
   if not effect.effects.is_empty():
    special_triggered.emit(effect.effect if not effect.effect.is_empty() else "sugar blast",point)
   if GameManager.sound and not "--test" in OS.get_cmdline_user_args():
    audio.pitch_scale = GameManager.next_sound_pitch(cascade)
    audio.play()
   # Reactive layers on top of the pop (v0.31): bigger matches, broken obstacles, specials, combos.
   if group.get("special_swap",false): SoundBoard.play("combo")
   elif not effect.fired.is_empty(): SoundBoard.play("special_fire",1.0+0.08*cascade)
   elif group.length >= 4 or not effect.effects.is_empty(): SoundBoard.play("match_big",1.0+0.06*cascade)
   if fresh_breaks > 0: SoundBoard.play("crack",1.0+0.05*cascade)
  # Live hand: the Candys x Mult boxes climb as each wave lands.
  GameManager.show_hand(hand_result(hand))
  if GameManager.motion:
   # Cleared candies swell with a bright flash, then pop away.
   var tween: Tween = create_tween().set_parallel()
   for i: int in removed:
    tiles[i].pivot_offset = Vector2.ONE*28
    tween.tween_property(tiles[i],"scale",Vector2.ONE*1.22,0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(tiles[i],"modulate",Color(1.7,1.7,1.7,1.0),0.06)
   tween.chain()
   for i: int in removed:
    tween.tween_property(tiles[i],"scale",Vector2.ONE*0.1,0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
    tween.tween_property(tiles[i],"modulate",Color(1.7,1.7,1.7,0.0),0.12)
   await tween.finished
  model.remove(removed)
  for spawn: Dictionary in spawns:
   if int(spawn.index) in wilds: continue
   model.place_spawn(spawn)
   juice.popup(CandyState.special_name(int(spawn.special)).get_slice(" (",0).to_upper()+"!",Vector2(model.xy(int(spawn.index)))*cell_size,UIStyle.CREAM)
   SoundBoard.play("special_make")
  for i: int in wilds:
   model.cells[i] = CandyState.new(model.roll_color())
   model.cells[i].coating = 3
  model.refill()
  sync_tiles(true)
  await get_tree().create_timer(fall_duration if GameManager.motion else 0.01,false).timeout
  groups = model.matches()
  cascade += 1
 if cascade >= GameManager.config.cascade_limit:
  model.stabilize()
  GameManager.toast.emit("Cascade safety limit reached | board settled")
 if hand.groups == 0: return
 # The whole move scores once, Balatro-style.
 var result: Dictionary = hand_result(hand)
 matches_resolved.emit(result,GameManager.poison if bool(result.get("poisoned",false)) else int(result.get("color",-1)))
 var label: String = (RecipeCatalog.ITEMS[result.recipe].short.to_upper()+"  ") if String(result.get("recipe","")) != "" else ""
 juice.popup(label+"+%s" % int(result.total),Vector2(4,3.4)*cell_size,UIStyle.MINT)
func hand_result(hand: MoveHand) -> Dictionary:
 return hand.result(GameManager.jokers,GameManager.streak,final_move,population,GameManager.recipe_levels)
func hint() -> void:
 if busy or paused or not target_consumable.is_empty() or GameManager.state != "playing": return
 var cost: int = GameManager.hint_cost()
 if GameManager.gummies < cost:
  GameManager.toast.emit("A hint costs $%s" % cost)
  return
 var legal: Array[Vector2i] = model.legal_moves()
 if legal.is_empty(): return
 GameManager.gummies -= cost
 GameManager.hints_used += 1
 for tile: SugarTile in tiles:
  tile.hinted = tile.cell_index in [legal[0].x,legal[0].y]
  tile.queue_redraw()
 GameManager.changed.emit()
func _unhandled_key_input(event: InputEvent) -> void:
 if not event.is_pressed() or busy or paused or GameManager.state != "playing": return
 if event.is_action_pressed("ui_left"): cursor = maxi(0,cursor-1)
 elif event.is_action_pressed("ui_right"): cursor = mini(model.cells.size()-1,cursor+1)
 elif event.is_action_pressed("ui_up"): cursor = maxi(0,cursor-columns)
 elif event.is_action_pressed("ui_down"): cursor = mini(model.cells.size()-1,cursor+columns)
 elif event.is_action_pressed("ui_accept"): choose(cursor)
 elif event is InputEventKey and event.keycode == KEY_H:
  if not event.echo: hint()
  get_viewport().set_input_as_handled()
  return
 else: return
 for tile: SugarTile in tiles:
  tile.hinted = tile.cell_index == cursor
  tile.queue_redraw()
 if selection >= 0 and model.adjacent(selection,cursor): show_preview(selection,cursor)
 else: clear_preview()
 get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion:
  var over: Vector2i = Vector2i((event.position / cell_size).floor())
  for tile: SugarTile in tiles:
   tile.hovered = not busy and model.xy(tile.cell_index) == over
   tile.queue_redraw()
  if drag_from >= 0 and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0: drag_to(event.position)
  elif drag_from < 0:
   # Selected a candy? Hovering a neighbour previews that swap (click it to confirm).
   if selection >= 0 and model.inside(over) and model.adjacent(selection,model.index(over)): show_preview(selection,model.index(over))
   else: clear_preview()
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
  if event.pressed:
   var cell: Vector2i = Vector2i((event.position / cell_size).floor())
   if model.inside(cell):
    # A press still selects (tap one candy, then a neighbour); a drag previews, release swaps.
    choose(model.index(cell))
    var can_drag: bool = not busy and not paused and target_consumable.is_empty() and GameManager.state == "playing" and model.playable(model.index(cell))
    drag_from = model.index(cell) if can_drag else -1
    drag_target = -1
    drag_start = event.position
  else: release_drag()
  accept_event()

# Mouse and touch drags (touch arrives as emulated mouse input). Past DRAG_THRESHOLD of a cell the
# candy leans fully toward the neighbour in the dominant direction and the HUD previews that swap.
# Releasing there confirms it; sliding back under the threshold cancels (v0.34).
func drag_to(point: Vector2) -> void:
 if busy or paused or drag_from < 0:
  end_drag()
  return
 var delta: Vector2 = point-drag_start
 var axis: Vector2i = Vector2i(signi(int(delta.x)),0) if absf(delta.x) >= absf(delta.y) else Vector2i(0,signi(int(delta.y)))
 var distance: float = maxf(absf(delta.x),absf(delta.y))
 var target: Vector2i = model.xy(drag_from)+axis
 var ready: bool = distance >= cell_size*DRAG_THRESHOLD and model.inside(target)
 if GameManager.motion and drag_from < tiles.size():
  tiles[drag_from].position = Vector2(model.xy(drag_from))*cell_size+Vector2(axis)*minf(distance,cell_size*DRAG_THRESHOLD)*(0.6 if ready else 0.5)
 if not ready:
  drag_target = -1
  clear_preview()
  return
 drag_target = model.index(target)
 show_preview(drag_from,drag_target)

func release_drag() -> void:
 var from: int = drag_from
 var to: int = drag_target
 end_drag()
 if from < 0 or to < 0: return
 if not model.playable(to):
  GameManager.toast.emit("Framed: match it or next to it")
  return
 selection = -1
 for tile: SugarTile in tiles:
  tile.selected = false
  tile.queue_redraw()
 attempt_swap(from,to)

func end_drag() -> void:
 if drag_from >= 0 and drag_from < tiles.size() and not busy:
  tiles[drag_from].position = Vector2(model.xy(drag_from))*cell_size
 drag_from = -1
 drag_target = -1

# --- Move preview (v0.34): the exact, guaranteed part of a swap's hand, Balatro-style ---
func show_preview(a: int, b: int) -> void:
 if busy or paused or GameManager.state != "playing" or not target_consumable.is_empty():
  clear_preview()
  return
 if preview_pair == Vector2i(a,b): return
 preview_pair = Vector2i(a,b)
 var info: Dictionary = preview_info(a,b)
 for tile: SugarTile in tiles:
  tile.previewed = tile.cell_index in info.get("cells",[])
  tile.queue_redraw()
 GameManager.set_preview(info)

# What swapping a and b would score before any cascade: {"valid","chips","mult","total","recipe","level","cells"}.
func preview_info(a: int, b: int) -> Dictionary:
 if not model.adjacent(a,b) or not model.playable(a) or not model.playable(b): return {"valid":false,"cells":[]}
 var preview: Dictionary = model.preview_swap(a,b,GameManager.recipe_levels,GameManager.poison)
 if not bool(preview.valid): return {"valid":false,"cells":[]}
 var people: int = 0
 for cell: CandyState in model.cells:
  if cell.blocker == 0: people += 1
 var hand: MoveHand = preview.hand
 var result: Dictionary = hand.result(GameManager.jokers,GameManager.streak+1,GameManager.moves == 1,people,GameManager.recipe_levels)
 return {"valid":true,"chips":float(result.chips),"mult":float(result.mult),"total":int(result.total),"recipe":String(result.get("recipe","")),"level":int(result.get("level",1)),"cells":preview.cells}

func clear_preview() -> void:
 if preview_pair == Vector2i(-1,-1) and GameManager.preview.is_empty(): return
 preview_pair = Vector2i(-1,-1)
 for tile: SugarTile in tiles:
  if tile.previewed:
   tile.previewed = false
   tile.queue_redraw()
 GameManager.set_preview({})
func _get_tooltip(at_position: Vector2) -> String:
 var cell: Vector2i = Vector2i((at_position / cell_size).floor())
 if not model.inside(cell) or model.cells.is_empty(): return ""
 var i: int = model.index(cell)
 var candy: CandyState = model.cells[i]
 var value: int = candy.value(GameManager.config,model.candy_bonus(candy.color))
 return "%s | %s Candys%s" % [GameManager.config.candies[candy.color].display_name,value,(" | Include this candy in a match of 3 to break the lock" if model.is_locked_tile(i) else "")+(" | Roulette: x2 Mult on matches" if GameManager.jokers.has("roulette") and candy.color==GameManager.poison else "")]
