extends SceneTree
# Run: Godot --headless --audio-driver Dummy --path . -s res://tools/balance_sim.gd -- --test [set=4] [trials=16] [cap=2] [addict=1] [lv=3]
# Greedy bot: picks the legal swap with the best first-wave score, then resolves cascades
# like GameBoard.resolve (no animation, no curses). Args after --: step= cap= addict= ouro= set= trials=
var config: RunConfig
var levels: Dictionary = {}
var boss: String = ""
var peaks: Array[int] = [] # Best single-move score of each simulated round.
var move_list: Array[int] = [10, 7]
var jelly_left: Array[int] = [] # Jelly tiles left at the end of each Jelly Mould round.
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
	"P1: paintball": ["paintball"],
	"P3: paintball+lab+addict": ["paintball","labyrinth","addict"],
	"P5: paintball+lab+addict+gravity+tsq": ["paintball","labyrinth","addict","gravity","tsquare"],
	"T5: pop+sweet+scoops+trio+addict": ["pop_rock","sweet_tooth","three_scoops","golden_trio","addict"],
	"R5: ricochet+gravity+lab+addict+cane": ["ricochet","gravity","labyrinth","addict","candy_cane"],
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
		if a.begins_with("moves="): move_list = [int(a.substr(6))]
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
		for moves: int in move_list:
			var scores: Array[int] = []
			peaks.clear()
			jelly_left.clear()
			for trial: int in range(trials):
				scores.append(play_round(jm, moves, 1000+trial*7+moves))
			scores.sort()
			peaks.sort()
			line += " | %dmv p25 %8d med %8d p75 %8d  best-move med %8d max %8d" % [moves, scores[trials/4], scores[trials/2], scores[trials*3/4], peaks[trials/2], peaks[trials-1]]
			if boss == "jelly":
				jelly_left.sort()
				var cleared: int = 0
				for j: int in jelly_left:
					if j == 0: cleared += 1
				line += "  jelly left med %d, fully cleared %d/%d" % [jelly_left[trials/2], cleared, trials]
		print(line)
	quit()
func set_strength(id: String, v: float) -> void:
	for j: JokerData in config.jokers:
		if j.id == id: j.strength = v
func first_wave(model: BoardModel, a: int, b: int, jm: JokerManager, streak: int) -> int:
	# The same exact preview the player sees: the guaranteed part of the hand (v0.34).
	var preview: Dictionary = model.preview_swap(a, b, levels, -1)
	if not bool(preview.valid): return -1
	var hand: MoveHand = preview.hand
	var total: int = int(hand.result(jm, streak+1, false, 64, levels).total)
	# A real player chases jelly on the Jelly Mould; reward the bot for each tile the match covers.
	if boss == "jelly":
		for i: int in preview.cells:
			if i in model.jelly: total += 400
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
	var best_move: int = 0
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
		# Mirrors GameBoard.resolve: every wave feeds one MoveHand, scored once at the end.
		var hand: MoveHand = MoveHand.new()
		var groups: Array[Dictionary] = model.swap_groups(best.x,best.y)
		var cascade: int = 0
		while not groups.is_empty() and cascade < config.cascade_limit:
			var wave: Dictionary = model.score_wave(groups, cascade, hand, levels, -1)
			var wilds: Array[int] = []
			var spawns: Array[Dictionary] = []
			for e: Dictionary in wave.effects:
				if e.wild >= 0: wilds.append(e.wild)
				if not e.spawn.is_empty(): spawns.append(e.spawn)
			model.remove(wave.removed)
			for s: Dictionary in spawns:
				if int(s.index) not in wilds: model.place_spawn(s)
			for i: int in wilds:
				model.cells[i] = CandyState.new(model.roll_color()); model.cells[i].coating = 3
			model.refill()
			groups = model.matches()
			cascade += 1
		var gained: int = int(hand.result(jm, streak, final_move, population, levels).total) if hand.groups > 0 else 0
		score += gained
		best_move = maxi(best_move, gained)
		if boss == "heatwave": model.age_candies([best.x,best.y])
		if boss == "chocolatier": model.spread_chocolate()
		if model.legal_moves().is_empty(): model.reshuffle()
	peaks.append(best_move)
	jelly_left.append(model.jelly.size())
	return score
