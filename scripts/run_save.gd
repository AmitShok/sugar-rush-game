extends Node
# Stable checkpoints never serialize a partly resolved swap/cascade.
# Tag and interest state (v0.20); missing in older saves, which load with these defaults.
const ECONOMY: Dictionary={"last_interest":0,"free_jokers":0,"free_offer_id":"","free_rerolls":0,"bonus_moves":0,"bonus_moves_used":0,"shop_closed":false,"free_owned":[],"tags_claimed":[],"pack_offers":[],"opened_pack":{},"free_packs":0,"interest_halved":false}
const FIELDS: Array[String]=["run_seed","round_index","score","moves","gummies","streak","poison","poison_cleared","state","last_chips","last_mult","last_award","last_summary","reroll_cost","hints_used"]
var main: Control
var path: String="user://run_save.cfg"
var restoring: bool=false
func _ready() -> void:
 if "--test" in OS.get_cmdline_user_args(): path="user://test_run_%s.cfg" % OS.get_process_id()
 GameManager.changed.connect(schedule)
 main.board.resolution_finished.connect(schedule)
 main.board.shuffle_finished.connect(schedule)
func schedule() -> void:
 if not restoring: call_deferred("checkpoint")
func pack_cells(cells: Array[CandyState]) -> Array:
 var result: Array=[]
 for cell: CandyState in cells:
  result.append([cell.color,cell.coating,cell.blocker,cell.age,cell.special,1 if cell.chocolate else 0,cell.frosting])
 return result
func unpack_cells(rows: Array) -> Array[CandyState]:
 var cells: Array[CandyState]=[]
 for row: Array in rows:
  var cell: CandyState=CandyState.new(row[0])
  cell.coating=row[1]
  cell.blocker=row[2]
  cell.age=row[3]
  if row.size()>4: cell.special=row[4]
  if row.size()>6:
   cell.chocolate=row[5]==1
   cell.frosting=row[6]
  cells.append(cell)
 return cells
func snapshot() -> Dictionary:
 var data: Dictionary={"version":1}
 for key: String in FIELDS: data[key]=GameManager.get(key)
 for key: String in ["consumables","consumable_offers","candy_levels","candy_bonuses"]: data[key]=GameManager.get(key).duplicate()
 data["jokers"]=[]
 data["offers"]=[]
 for item: JokerData in GameManager.jokers.equipped: data.jokers.append(item.id)
 for item: JokerData in GameManager.offers: data.offers.append(item.id)
 data["recipes"]=GameManager.recipe_levels.duplicate()
 var economy: Dictionary={}
 for key: String in ECONOMY: economy[key]=GameManager.get(key).duplicate() if GameManager.get(key) is Array else GameManager.get(key)
 data["economy"]=economy
 data["jokers_extra"]={"capacity":GameManager.jokers.capacity,"editions":GameManager.jokers.editions.duplicate(),"counters":GameManager.jokers.counters.duplicate(),"offer_editions":GameManager.offer_editions.duplicate(),"offer_rolls":GameManager.offer_rolls}
 data["rng"]=GameManager.rng.state
 var model: BoardModel=main.board.model
 data["board"]={"cells":pack_cells(model.cells),"recycled":pack_cells(model.recycled),"isotopes":model.isotopes.duplicate(),"graves":model.graves.duplicate(),"locked_color":model.locked_color,"rng":model.rng.state,"boss":model.boss,"jelly":model.jelly.duplicate(),"sour_color":model.sour_color}
 return data
func checkpoint() -> void:
 if restoring: return
 if GameManager.state=="over":
  if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
  return
 if GameManager.state not in ["playing","shop"] or main.board.busy or main.board.model.cells.size()!=64: return
 var file: ConfigFile=ConfigFile.new()
 file.set_value("run","data",snapshot())
 var error: Error=file.save(path+".tmp")
 if error==OK: error=DirAccess.rename_absolute(path+".tmp",path)
 if error!=OK: GameManager.toast.emit("Run could not be saved: "+error_string(error))
func read_save() -> Dictionary:
 var file: ConfigFile=ConfigFile.new()
 if file.load(path)!=OK: return {}
 var value: Variant=file.get_value("run","data",{})
 if not value is Dictionary: return {}
 var data: Dictionary=value
 if data.get("version")!=1: return {}
 # Earlier runs had free hints, so they begin with the new $1 price.
 if not data.has("hints_used"): data["hints_used"]=0
 # Saves from before recipes start every recipe at level 1.
 if not data.has("recipes"): data["recipes"]=RecipeCatalog.default_levels()
 # Joker editions and scaling counters (v0.21); older saves have none.
 if not data.has("jokers_extra"): data["jokers_extra"]={"editions":{},"counters":{},"offer_editions":{},"offer_rolls":0}
 var extra: Variant=data.jokers_extra
 if not extra is Dictionary or not extra.get("editions") is Dictionary or not extra.get("counters") is Dictionary or not extra.get("offer_editions") is Dictionary or not extra.get("offer_rolls") is int: return {}
 for key: String in ["editions","offer_editions"]:
  for id: Variant in extra[key]:
   if not EditionCatalog.ITEMS.has(extra[key][id]): return {}
 for id: Variant in extra.counters:
  if not (extra.counters[id] is float or extra.counters[id] is int) or extra.counters[id]<0: return {}
 if not data.has("economy"): data["economy"]=ECONOMY.duplicate(true)
 if not data.economy is Dictionary: return {}
 for key: String in ECONOMY:
  if not data.economy.has(key): data.economy[key]=ECONOMY[key]
  if typeof(data.economy[key])!=typeof(ECONOMY[key]): return {}
 # Booster packs (v0.23): known kinds only, and an open pack needs picks left.
 for pack: Variant in data.economy.pack_offers:
  if not pack is Dictionary or not PackCatalog.ITEMS.has(pack.get("kind","")): return {}
 if not data.economy.opened_pack.is_empty():
  var open: Dictionary=data.economy.opened_pack
  if not PackCatalog.ITEMS.has(open.get("kind","")) or not open.get("choices") is Array or not open.get("picks") is int or open.picks<1: return {}
 var capacity: Variant=data.jokers_extra.get("capacity",GameManager.config.joker_slots)
 if not capacity is int or capacity<GameManager.config.joker_slots or capacity>PackCatalog.MAX_JOKER_SLOTS: return {}
 if data.get("jokers") is Array and data.jokers.size()>capacity: return {}
 for key: String in ["free_jokers","free_rerolls","bonus_moves","bonus_moves_used","last_interest","free_packs"]:
  if data.economy[key]<0: return {}
 if not data.recipes is Dictionary: return {}
 for id: Variant in data.recipes:
  if not RecipeCatalog.ITEMS.has(id) or not data.recipes[id] is int or data.recipes[id]<1: return {}
 for key: String in FIELDS:
  if not data.has(key) or typeof(data[key])!=typeof(GameManager.get(key)): return {}
 if data.state not in ["playing","shop"] or data.round_index<0 or data.round_index>=GameManager.config.rounds.size(): return {}
 if data.hints_used<0 or data.hints_used>=9223372036854775807: return {}
 for key: String in ["consumables","consumable_offers","jokers","offers","candy_levels","candy_bonuses"]:
  if not data.get(key) is Array: return {}
 if data.consumables.size()>2 or data.consumable_offers.size()>2 or data.jokers.size()>PackCatalog.MAX_JOKER_SLOTS: return {}
 for key: String in ["consumables","consumable_offers"]:
  for id: Variant in data[key]:
   if not ConsumableCatalog.ITEMS.has(id): return {}
 var known: Array=[]
 for item: JokerData in GameManager.config.jokers: known.append(item.id)
 for key: String in ["jokers","offers"]:
  for id: Variant in data[key]:
   if id not in known: return {}
 for key: String in ["candy_levels","candy_bonuses"]:
  if data[key].size()!=6: return {}
  for number: Variant in data[key]:
   if not number is int or number<0: return {}
 if not data.get("rng") is int or not data.get("board") is Dictionary: return {}
 var board: Dictionary=data.board
 if not board.get("rng") is int or not board.get("locked_color") is int: return {}
 if board.locked_color < -1 or board.locked_color>5: return {}
 if not board.has("jelly"): board["jelly"]=[]
 if not board.get("sour_color",-1) is int or board.get("sour_color",-1)<-1 or board.get("sour_color",-1)>5: return {}
 if not board.get("boss",GameManager.curse()) is String: return {}
 for key: String in ["cells","recycled","isotopes","graves","jelly"]:
  if not board.get(key) is Array: return {}
 if board.cells.size()!=64: return {}
 for key: String in ["cells","recycled"]:
  for row: Variant in board[key]:
   # Five fields since special candies (v0.19); older four-field rows load as plain candies.
   if not row is Array or row.size()<4 or row.size()>7 or row.size()==6: return {}
   for number: Variant in row:
    if not number is int: return {}
   # Refill uses -1 so newly spawned candies are age zero after Heatwave ticks.
   if row[0]<0 or row[0]>5 or row[1]<0 or row[1]>3 or row[2]<0 or row[3]<-1: return {}
   if row.size()>4 and (row[4]<CandyState.NONE or row[4]>CandyState.BOMB): return {}
   if row.size()>6 and (row[5]<0 or row[5]>1 or row[6]<0 or row[6]>BossCatalog.FROST_LAYERS): return {}
 for key: String in ["isotopes","graves","jelly"]:
  for index: Variant in board[key]:
   if not index is int or index<0 or index>=64: return {}
 return data
func has_save() -> bool:
 return not read_save().is_empty()
func restore() -> bool:
 var data: Dictionary=read_save()
 if data.is_empty(): return false
 restoring=true
 for key: String in FIELDS: GameManager.set(key,data[key])
 for key: String in ["consumables","consumable_offers","candy_levels","candy_bonuses"]: GameManager.get(key).assign(data[key])
 GameManager.jokers.equipped.clear()
 GameManager.offers.clear()
 for id: String in data.jokers:
  for item: JokerData in GameManager.config.jokers:
   if item.id==id: GameManager.jokers.equipped.append(item)
 for id: String in data.offers:
  for item: JokerData in GameManager.config.jokers:
   if item.id==id: GameManager.offers.append(item)
 GameManager.recipe_levels=RecipeCatalog.default_levels()
 GameManager.recipe_levels.merge(data.recipes,true)
 for key: String in ECONOMY:
  if ECONOMY[key] is Array: GameManager.get(key).assign(data.economy[key])
  else: GameManager.set(key,data.economy[key])
 GameManager.jokers.capacity=int(data.jokers_extra.get("capacity",GameManager.config.joker_slots))
 GameManager.jokers.editions=data.jokers_extra.editions.duplicate()
 GameManager.jokers.counters=data.jokers_extra.counters.duplicate()
 GameManager.offer_editions=data.jokers_extra.offer_editions.duplicate()
 GameManager.offer_rolls=data.jokers_extra.offer_rolls
 GameManager.rng.state=data.rng
 var board: GameBoard=main.board
 board.start_round()
 board.model.cells=unpack_cells(data.board.cells)
 board.model.recycled=unpack_cells(data.board.recycled)
 board.model.isotopes.assign(data.board.isotopes)
 board.model.graves.assign(data.board.graves)
 board.model.locked_color=data.board.locked_color
 # Boss board state (v0.22); older saves had none.
 board.model.boss=String(data.board.get("boss",GameManager.curse()))
 board.model.jelly.assign(data.board.get("jelly",[]))
 board.model.sour_color=int(data.board.get("sour_color",-1))
 board.model.rng.state=data.board.rng
 board.sync_tiles(false)
 restoring=false
 return true
