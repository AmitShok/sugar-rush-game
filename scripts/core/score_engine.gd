class_name ScoreEngine
extends RefCounted
static func calculate(chips: int, group: Dictionary, isotope: bool, jokers: JokerManager, streak: int, poisoned: bool, final_move: bool, population: int, cascade: int) -> Dictionary:
 var base: float = chips
 var mult: float = 1.0 + maxi(0,int(group.length)-3) + cascade*0.5
 if group.diagonal: base *= jokers.power("kaleidoscope",1.5)
 if jokers.has("labyrinth"): mult *= jokers.power("labyrinth",3)
 if jokers.has("addict"): mult += streak*jokers.power("addict",3)
 if isotope: mult *= jokers.power("nuclear",4)
 if poisoned: mult *= jokers.power("roulette",2)
 if final_move and jokers.has("ouroboros"): mult *= population
 var value: int = roundi(base*mult)
 if jokers.has("broken"): return {"chips":mult,"mult":base,"total":value}
 return {"chips":base,"mult":mult,"total":value}
