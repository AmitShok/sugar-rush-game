class_name RunConfig
extends Resource
@export var starting_gummies: int = 4
@export var joker_slots: int = 5
@export var clear_reward: int = 5
@export var big_reward: int = 7
@export var boss_reward: int = 10
@export var move_bonus_cap: int = 3
@export var moves_per_bonus: int = 3
@export var base_reroll_cost: int = 3
@export var reroll_increment: int = 2
@export var gold_chips: int = 80
@export var caramel_chips: int = 30
@export var heatwave_turns: int = 4
@export var cascade_limit: int = 40
@export var rounds: Array[RoundData] = []
@export var candies: Array[CandyData] = []
@export var jokers: Array[JokerData] = []
