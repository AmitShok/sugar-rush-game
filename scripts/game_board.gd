class_name GameBoard
extends Control
signal matches_resolved(result: Dictionary, color: int)
signal move_made(valid: bool)
signal special_triggered(effect: String, origin: Vector2)
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
var selection: int = -1
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
 GameManager.round_started.connect(start_round)
func start_round() -> void:
 juice.clear_effects()
 busy = false
 selection = -1
 model.width = columns
 model.height = rows
 model.setup(GameManager.config,GameManager.jokers,GameManager.run_seed+GameManager.round_index*7919)
 model.locked_color = model.rng.randi_range(0,GameManager.config.candies.size()-1) if GameManager.current_round().curse == "inspector" else -1
 model.candy_bonuses = GameManager.candy_bonuses
 model.fill_fresh()
 # Persistent obstacles give destruction/revival builds targets in every round.
 for i: int in starting_blockers:
  if i >= 0 and i < model.cells.size(): model.cells[i].blocker = 2
 if model.legal_moves().is_empty(): model.reshuffle()
 sync_tiles(false)
func sync_tiles(falling: bool) -> void:
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
  tile.configure(i,state,GameManager.config,i in model.isotopes,state.color==model.locked_color,model.candy_bonus(state.color),GameManager.jokers.has("roulette") and state.color==GameManager.poison)
  tile.selected = i == selection
  tile.hinted = false
  tile.scale = Vector2.ONE
  tile.modulate = Color.WHITE
  var target: Vector2 = Vector2(model.xy(i))*cell_size
  if falling and GameManager.motion:
   var movement: Tween = tile.create_tween()
   movement.tween_property(tile,"position",target,fall_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
   movement_tweens.append(movement)
  else: tile.position = target
  tiles.append(tile)
 for tile: SugarTile in old.values(): tile.queue_free()
func choose(i: int) -> void:
 if busy or paused or GameManager.state != "playing": return
 if not model.playable(i):
  GameManager.toast.emit("Frame: line up 3 including this candy, or match beside it.")
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
 selection = -1
 final_move = GameManager.moves == 1
 population = 0
 for cell: CandyState in model.cells:
  if cell.blocker == 0: population += 1
 var wild: bool = model.cells[a].coating == 3 or model.cells[b].coating == 3
 await animate_swap(a,b)
 model.swap(a,b)
 var groups: Array[Dictionary] = model.wild_groups(a,b) if wild else model.matches()
 move_made.emit(not groups.is_empty())
 if groups.is_empty():
  model.swap(a,b)
  sync_tiles(true)
  juice.popup("No match",Vector2(model.xy(b))*cell_size,UIStyle.PINK)
  GameManager.toast.emit("No match | move spent | streak reset")
  if GameManager.motion: await get_tree().create_timer(fall_duration,false).timeout
 else:
  model.cells[a].age = -1
  model.cells[b].age = -1
  sync_tiles(false)
  await resolve(groups)
 if GameManager.current_round().curse == "heatwave": model.age_candies([a,b])
 if model.legal_moves().is_empty():
  model.reshuffle()
  GameManager.toast.emit("No legal moves | the bowl was reshuffled for free")
 sync_tiles(true)
 if GameManager.motion: await get_tree().create_timer(fall_duration,false).timeout
 busy = false
 resolution_finished.emit()
func resolve(initial: Array[Dictionary]) -> void:
 var groups: Array[Dictionary] = initial
 var cascade: int = 0
 while not groups.is_empty() and cascade < GameManager.config.cascade_limit:
  var removed: Array[int] = []
  var wilds: Array[int] = []
  for group: Dictionary in groups:
   var effect: Dictionary = model.expand(group)
   # Effects may overlap. Award each candy at most once in this cascade wave.
   var chips: int = int(effect.chips)
   var fresh_breaks: int = 0
   for i: int in effect.cells:
    if i not in removed and i in effect.broken: fresh_breaks += 1
    if i in removed and model.cells[i] != null: chips -= int(effect.contributions[i])
    elif i not in removed: removed.append(i)
   var result: Dictionary = ScoreEngine.calculate(maxi(0,chips),group,effect.isotope,GameManager.jokers,GameManager.streak,group.color==GameManager.poison,final_move,population,cascade)
   matches_resolved.emit(result,group.color)
   if fresh_breaks > 0:
    juice.popup("BREAK +%s" % (fresh_breaks*effect.break_bonus),Vector2(model.xy(effect.origin))*cell_size+Vector2(0,40),UIStyle.MINT)
   var point: Vector2 = Vector2(model.xy(effect.origin))*cell_size+Vector2.ONE*28
   juice.popup("+%s" % result.total,point,GameManager.config.candies[group.color].tint)
   juice.burst(point,GameManager.config.candies[group.color].tint)
   if effect.wild >= 0: wilds.append(effect.wild)
   if "gravity" in effect.effects and GameManager.motion:
    for i: int in effect.cells:
     if i not in group.cells:
      create_tween().tween_property(tiles[i],"position",point-Vector2.ONE*28,0.15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
   if group.length >= 4 or not effect.effects.is_empty():
    special_triggered.emit(effect.effect if not effect.effect.is_empty() else "sugar blast",point)
   if GameManager.sound and not "--test" in OS.get_cmdline_user_args():
    audio.pitch_scale = GameManager.next_sound_pitch(cascade)
    audio.play()
  if GameManager.motion:
   var tween: Tween = create_tween().set_parallel()
   for i: int in removed:
    tiles[i].pivot_offset = Vector2.ONE*28
    tween.tween_property(tiles[i],"scale",Vector2.ONE*0.15,0.15)
    tween.tween_property(tiles[i],"modulate:a",0.0,0.15)
   await tween.finished
  model.remove(removed)
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
func hint() -> void:
 if busy or paused or GameManager.state != "playing": return
 var legal: Array[Vector2i] = model.legal_moves()
 if legal.is_empty(): return
 for tile: SugarTile in tiles:
  tile.hinted = tile.cell_index in [legal[0].x,legal[0].y]
  tile.queue_redraw()
func _unhandled_key_input(event: InputEvent) -> void:
 if not event.is_pressed() or busy or paused or GameManager.state != "playing": return
 if event.is_action_pressed("ui_left"): cursor = maxi(0,cursor-1)
 elif event.is_action_pressed("ui_right"): cursor = mini(model.cells.size()-1,cursor+1)
 elif event.is_action_pressed("ui_up"): cursor = maxi(0,cursor-columns)
 elif event.is_action_pressed("ui_down"): cursor = mini(model.cells.size()-1,cursor+columns)
 elif event.is_action_pressed("ui_accept"): choose(cursor)
 elif event is InputEventKey and event.keycode == KEY_H: hint()
 else: return
 for tile: SugarTile in tiles:
  tile.hinted = tile.cell_index == cursor
  tile.queue_redraw()
 get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion:
  var over: Vector2i = Vector2i((event.position / cell_size).floor())
  for tile: SugarTile in tiles:
   tile.hovered = not busy and model.xy(tile.cell_index) == over
   tile.queue_redraw()
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
  var cell: Vector2i = Vector2i((event.position / cell_size).floor())
  if model.inside(cell): choose(model.index(cell))
  accept_event()
func _get_tooltip(at_position: Vector2) -> String:
 var cell: Vector2i = Vector2i((at_position / cell_size).floor())
 if not model.inside(cell) or model.cells.is_empty(): return ""
 var i: int = model.index(cell)
 var candy: CandyState = model.cells[i]
 var value: int = candy.value(GameManager.config,model.candy_bonus(candy.color))
 return "%s | %s Candys%s" % [GameManager.config.candies[candy.color].display_name,value,(" | Include this candy in a match of 3 to break the lock" if model.is_locked_tile(i) else "")+(" | Roulette: x2 Mult on matches" if GameManager.jokers.has("roulette") and candy.color==GameManager.poison else "")]
