extends "res://tests/upgrade_runner.gd"
# Recipe (match type) levels: classification, scoring, shop purchases, sidebar, saves and run reset.
func g(length: int, shape: bool = false, diagonal: bool = false) -> Dictionary:
 var ids: Array[int]=[]
 for i: int in range(length): ids.append(i)
 return {"cells":ids,"color":0,"length":length,"shape":shape,"diagonal":diagonal,"axis":Vector2i.RIGHT}
func run_tests() -> void:
 main=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 var rules: JokerManager=JokerManager.new()
 check(RecipeCatalog.classify(g(3))=="trio" and RecipeCatalog.classify(g(4))=="quad" and RecipeCatalog.classify(g(6))=="quint","Lines classify as Trio / Quad / Quint")
 check(RecipeCatalog.classify(g(5,true))=="shape" and RecipeCatalog.classify(g(4,false,true))=="diagonal","Shapes and diagonals take priority over length")
 check(ScoreEngine.calculate(30,g(3),false,rules,0,false,false,64,0).total==30,"Level 1 Trio keeps plain 30 x1")
 check(ScoreEngine.calculate(40,g(4),false,rules,0,false,false,64,0).total==100,"Level 1 Quad: (40+10) x2")
 check(ScoreEngine.calculate(60,g(6),false,rules,0,false,false,64,0).total==360,"Quint 6: (60+30) x(3+1 extra)")
 check(ScoreEngine.calculate(50,g(5,true),false,rules,0,false,false,64,0).total==210,"Shape: (50+20) x3")
 var levelled: Dictionary={"trio":3}
 var result: Dictionary=ScoreEngine.calculate(30,g(3),false,rules,0,false,false,64,0,levelled)
 check(result.total==(30+20)*3 and result.recipe=="trio" and result.level==3,"Trio level 3: +20 Candys, +2 Mult")
 GameManager.start_run(512)
 GameManager.motion=false
 check(GameManager.recipe_level("quad")==1,"Runs start every recipe at level 1")
 GameManager.score=GameManager.current_round().quota
 GameManager.settle_round()
 shop=main.get_node("Shop")
 GameManager.gummies=30
 GameManager.changed.emit()
 await frames()
 await click(shop.levels_button)
 check(shop.levels_open and shop.recipe_rows.size()==5,"Levels pop-up lists five recipes")
 # Since v0.23 recipe levels come from Recipe Packs; the tab only shows levels.
 GameManager.level_recipe("trio")
 GameManager.level_recipe("trio")
 GameManager.changed.emit()
 await frames()
 check(GameManager.recipe_level("trio")==3 and GameManager.gummies==30 and GameManager.recipe_level("quad")==1,"Levels stack per recipe only and cost nothing by themselves")
 check(shop.recipe_rows["trio"].get_child(0).text.contains("Lv 3") and shop.recipe_rows["trio"].get_child(1).text=="20x3 > 30x4","Recipe row shows level and next-level values")
 check(shop.recipe_rows["trio"].get_child(2).text=="From packs","Recipe rows point to packs instead of a buy button")
 check(shop.levels_panel.get_global_rect().end.x<=1152 and shop.levels_panel.get_global_rect().end.y<=720 and shop.levels_panel.get_global_rect().position.y>=0,"Levels pop-up fits the canvas")
 await capture("recipes_shop")
 GameManager.level_recipe("poker")
 check(not GameManager.recipe_levels.has("poker"),"Unknown recipes are ignored")
 check(shop.candy_rows.size()==6,"Levels pop-up also lists six candy types")
 await click(shop.levels_close)
 check(not shop.levels_open and shop.get_node("Offers").visible,"Back to shop closes the pop-up")
 var saver: Node=main.run_save
 saver.checkpoint()
 GameManager.recipe_levels["trio"]=1
 check(saver.restore() and GameManager.recipe_level("trio")==3,"Recipe levels survive save and Continue")
 GameManager.next_round()
 await frames()
 var guide: String=main.get_node("Play/MatchGuide").text
 check(guide.contains("Trio 3  20x3") and guide.contains("Quad 1  10x2") and not guide.contains("Diag"),"Sidebar shows live recipe levels; Diagonal hidden without Kaleidoscope")
 GameManager.award({"chips":50,"mult":3,"total":150,"recipe":"trio","level":3},0)
 await frames()
 check(main.get_node("Play/MatchGuide").text.contains(">Trio"),"Sidebar marks the last scored recipe")
 check(main.get_node("Play/MatchGuide").get_global_rect().end.y<=main.get_node("Play/Instruction").get_global_rect().position.y+2,"Recipe table does not overlap instructions")
 await capture("recipes_gameplay")
 GameManager.start_run(513)
 check(GameManager.recipe_level("trio")==1 and GameManager.last_recipe=="","New run resets recipe levels")
 print("RESULT: %s recipe checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
