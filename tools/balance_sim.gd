extends SceneTree
# Run: Godot --headless --audio-driver Dummy --path . -s res://tools/balance_sim.gd -- --test [set=4] [trials=16] [cap=2] [addict=1] [lv=3]
# Greedy bot: picks the legal swap with the best first-wave score, then resolves cascades
# like GameBoard.resolve (no animation, no curses). Args after --: step= cap= addict= ouro= set= trials=
var config: RunConfig
var levels: Dictionary = {}
var boss: String = ""
var all_builds: Dictionary = {
	"none": [],
	"2a: labyrinth+addict": ["labyrinth","addict"],
	"2b: kaleido+scoops": ["kaleidoscope","three_scoops"],
	"3a: pop+sweet+scoops": ["pop_rock","sweet_tooth","three_scoops"],
	"3b: ouro+addict+scoops": ["ouroboros","addict","three_scoops"],
	"4a: three-pile+trio": ["pop_rock","sweet_tooth","three_scoops","golden_trio"],
	"4b: kaleido+mobius+addict+lab": ["kaleidoscope","mobius","addict","labyrinth"],
	"5a: 4/5 pile": ["tsquare","gravity","paintball","midas","nuclear"],
	"5b: kaleido+mobius+addict+lab+ouro": ["kaleidoscope","mobius","addict","labyrinth","ouroboros"],
	"1s: striper": ["striper"],
	"3s: striper+wrapper+bomb": ["striper","wrapper","bomb_maker"],
	"5s: specials+tsquare+gravity": ["striper","wrapper","bomb_maker","tsquare","gravity"],
}
func _init() -> void:
	config = load("res://resources/default_run.tres")
	var trials: int = 16
	var filter: String = ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("step="): config.cascade_mult_step = float(a.substr(5))
		if a.begins_with("cap="): config.cascade_mult_cap = float(a.substr(4))
		if a.begins_with("addict="): set_strength("addict", float(a.substr(7)))
		if a.begins_with("ouro="): set_strength("ouroboros", float(a.substr(5)))
		if a.begins_with("lab="): set_strength("labyrinth", float(a.substr(4)))
		if a.begins_with("kal="): set_strength("kaleidoscope", float(a.substr(4)))
		if a.begins_with("set="): filter = a.substr(4)
		if a.begins_with("trials="): trials = int(a.substr(7))
		if a.begins_with("lv="): for id: String in RecipeCatalog.ORDER: levels[id] = int(a.substr(3))
		if a.begins_with("boss="): boss = a.substr(5)
	ScoreEngine.configure(config)
	# solo=1: score every Joker on its own (plus a Three Scoops partner, since most builds have one),
	# so rarity tiers can be set from measured power.
	if "solo=1" in OS.get_cmdline_user_args():
		all_builds = {"none": []}
		for j: JokerData in config.jokers: all_builds["solo " + j.id] = [j.id]
	for build_name: String in all_builds:
		if not filter.is_empty() and not build_name.begins_with(filter): continue
		var jm: JokerManager = JokerManager.new()
		for id: String in all_builds[build_name]:
			for j: JokerData in config.jokers:
				if j.id == id: jm.equipped.append(j)
		var line: String = "%-36s" % build_name
		for moves: int in [10, 7]:
			var scores: Array[int] = []
			for trial: int in range(trials):
				scores.append(play_round(jm, moves, 1000+trial*7+moves))
			scores.sort()
			line += " | %dmv p25 %7d med %7d p75 %7d" % [moves, scores[trials/4], scores[trials/2], scores[trials*3/4]]
		print(line)
	quit()
func set_strength(id: String, v: float) -> void:
	for j: JokerData in config.jokers:
		if j.id == id: j.strength = v
func swap_groups(model: BoardModel, a: int, b: int) -> Array[Dictionary]:
	# Mirrors GameBoard.attempt_swap after model.swap(a,b).
	if model.is_special_swap(a,b): return model.special_swap_groups(a,b)
	if model.cells[a].coating == 3 or model.cells[b].coating == 3: return model.wild_groups(a,b)
	var groups: Array[Dictionary] = model.matches()
	for g: Dictionary in groups:
		if b in g.cells: g["pivot"] = b
		elif a in g.cells: g["pivot"] = a
	return groups
func first_wave(model: BoardModel, a: int, b: int, jm: JokerManager, streak: int) -> int:
	var snap: Array[CandyState] = []
	for c: CandyState in model.cells:
		var n: CandyState = CandyState.new(c.color); n.coating = c.coating; n.blocker = c.blocker; n.age = c.age; n.special = c.special; n.chocolate = c.chocolate; n.frosting = c.frosting
		snap.append(n)
	var rng_state: int = model.rng.state
	var iso: Array[int] = model.isotopes.duplicate()
	var graves: Array[int] = model.graves.duplicate()
	var jelly: Array[int] = model.jelly.duplicate()
	var choc: int = model.chocolate_broken
	var rec: int = model.recycled.size()
	model.swap(a,b)
	var total: int = 0
	for g: Dictionary in swap_groups(model,a,b):
		var e: Dictionary = model.expand(g)
		total += int(ScoreEngine.calculate(e.chips, g, e.isotope, jm, streak+1, false, false, 64, 0, levels).total)
		# Making a special is worth something later; a simple nudge keeps the bot from ignoring them.
		if not e.spawn.is_empty(): total += 150
	model.cells.assign(snap)
	model.rng.state = rng_state
	model.isotopes.assign(iso)
	model.graves.assign(graves)
	model.jelly.assign(jelly)
	model.chocolate_broken = choc
	model.recycled.resize(rec)
	return total
func play_round(jm: JokerManager, moves: int, seed_value: int) -> int:
	var model: BoardModel = BoardModel.new()
	model.setup(config, jm, seed_value)
	model.candy_bonuses.resize(config.candies.size()); model.candy_bonuses.fill(0)
	model.fill_fresh()
	if not boss.is_empty():
		if boss == "inspector": model.locked_color = model.rng.randi_range(0,5)
		model.setup_boss(boss)
		if boss == "hurry": moves = maxi(1,moves-BossCatalog.HURRY_MOVES)
	if model.legal_moves().is_empty(): model.reshuffle()
	var score: int = 0
	var streak: int = 0
	for m: int in range(moves):
		var best: Vector2i = Vector2i(-1,-1)
		var best_v: int = -1
		for mv: Vector2i in model.legal_moves():
			var v: int = first_wave(model, mv.x, mv.y, jm, streak)
			if v > best_v: best_v = v; best = mv
		if best.x < 0: break
		streak += 1
		var final_move: bool = m == moves-1
		var population: int = 0
		for c: CandyState in model.cells: if c.blocker == 0: population += 1
		model.chocolate_broken = 0
		model.swap(best.x,best.y)
		var groups: Array[Dictionary] = swap_groups(model,best.x,best.y)
		var cascade: int = 0
		while not groups.is_empty() and cascade < config.cascade_limit:
			var removed: Array[int] = []
			var wilds: Array[int] = []
			var spawns: Array[Dictionary] = []
			for g: Dictionary in groups:
				var e: Dictionary = model.expand(g)
				var chips: int = int(e.chips)
				for i: int in e.cells:
					if i in removed and model.cells[i] != null: chips -= int(e.contributions[i])
					elif i not in removed: removed.append(i)
				score += int(ScoreEngine.calculate(maxi(0,chips), g, e.isotope, jm, streak, false, final_move, population, cascade, levels).total)
				if e.wild >= 0: wilds.append(e.wild)
				if not e.spawn.is_empty(): spawns.append(e.spawn)
			model.remove(removed)
			for s: Dictionary in spawns:
				if int(s.index) not in wilds: model.place_spawn(s)
			for i: int in wilds:
				model.cells[i] = CandyState.new(model.roll_color()); model.cells[i].coating = 3
			model.refill()
			groups = model.matches()
			cascade += 1
		if boss == "heatwave": model.age_candies([best.x,best.y])
		if boss == "chocolatier": model.spread_chocolate()
		if model.legal_moves().is_empty(): model.reshuffle()
	return score
