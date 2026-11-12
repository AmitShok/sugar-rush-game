class_name TagCatalog
extends RefCounted
# Rewards for skipping a Small or Big batch (Balatro-style Tags).
const ORDER: Array[String] = ["piggy","handout","cookbook","reroll","sweets","moves","pack"]
const ITEMS: Dictionary = {
 "piggy": {"name":"Piggy Tag","description":"Double your cash (max +$15)","tint":"f4a3c0"},
 "handout": {"name":"Handout Tag","description":"A free Joker in the next shop","tint":"f4c76b"},
 "cookbook": {"name":"Cookbook Tag","description":"+1 level to 2 random recipes","tint":"75ad70"},
 "reroll": {"name":"Reroll Tag","description":"Next 2 rerolls are free","tint":"68b5ce"},
 "sweets": {"name":"Sweets Tag","description":"A free consumable (or $4)","tint":"aa83bb"},
 "moves": {"name":"Extra Moves Tag","description":"+3 moves next round","tint":"e7584a"},
 "pack": {"name":"Pack Tag","description":"A free Jumbo pack next shop","tint":"f4c76b"},
}
const PIGGY_CAP: int = 15
const SWEETS_FALLBACK_CASH: int = 4
const EXTRA_MOVES: int = 3
const FREE_REROLLS: int = 2
# Deterministic per run seed and round, so the route can show a Tag before the run starts.
static func for_round(run_seed: int, round_index: int) -> String:
 var rng: RandomNumberGenerator = RandomNumberGenerator.new()
 rng.seed = hash([run_seed,round_index,"tag"])
 return ORDER[rng.randi_range(0,ORDER.size()-1)]
static func skippable(round_index: int) -> bool:
 return round_index%3 != 2
