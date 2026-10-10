extends Node
# Stable checkpoints never serialize a partly resolved swap/cascade.
const FIELDS: Array[String]=["run_seed","round_index","score","moves","gummies","streak","poison","poison_cleared","state","last_chips","last_mult","last_award","last_summary","reroll_cost"]
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
  result.append([cell.color,cell.coating,cell.blocker,cell.age])
 return result
func unpack_cells(rows: Array) -> Array[CandyState]:
 var cells: Array[CandyState]=[]
 for row: Array in rows:
  var cell: CandyState=CandyState.new(row[0])
  cell.coating=row[1]
  cell.blocker=row[2]
  cell.age=row[3]
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
 data["rng"]=GameManager.rng.state
 var model: BoardModel=main.board.model
 data["board"]={"cells":pack_cells(model.cells),"recycled":pack_cells(model.recycled),"isotopes":model.isotopes.duplicate(),"graves":model.graves.duplicate(),"locked_color":model.locked_color,"rng":model.rng.state}
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
 for key: String in FIELDS:
  if not data.has(key) or typeof(data[key])!=typeof(GameManager.get(key)): return {}
 if data.state not in ["playing","shop"] or data.round_index<0 or data.round_index>=GameManager.config.rounds.size(): return {}
 for key: String in ["consumables","consumable_offers","jokers","offers","candy_levels","candy_bonuses"]:
  if not data.get(key) is Array: return {}
 if data.consumables.size()>2 or data.consumable_offers.size()>2 or data.jokers.size()>5: return {}
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
 for key: String in ["cells","recycled","isotopes","graves"]:
  if not board.get(key) is Array: return {}
 if board.cells.size()!=64: return {}
 for key: String in ["cells","recycled"]:
  for row: Variant in board[key]:
   if not row is Array or row.size()!=4: return {}
   for number: Variant in row:
    if not number is int or number<0: return {}
   if row[0]>5 or row[1]>3: return {}
 for key: String in ["isotopes","graves"]:
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
 GameManager.rng.state=data.rng
 var board: GameBoard=main.board
 board.start_round()
 board.model.cells=unpack_cells(data.board.cells)
 board.model.recycled=unpack_cells(data.board.recycled)
 board.model.isotopes.assign(data.board.isotopes)
 board.model.graves.assign(data.board.graves)
 board.model.locked_color=data.board.locked_color
 board.model.rng.state=data.board.rng
 board.sync_tiles(false)
 restoring=false
 return true
