# Editing Sugar Roguelite

## Open and run

1. Open Godot 4.7.2 and import the project's `project.godot`, or use `Open Editor.cmd` on this machine.
2. Let the asset scan complete. `MainGame.tscn` is already the main scene.
3. Press F5 to run the full game. F6 can preview an individual UI scene, but gameplay requires the main scene and its GameManager autoload.
4. All singleton registration, resource references, signal connections, and scene instances are already provided. There is no manual wiring step.

## Scene map

| Scene | Responsibility / editable nodes |
| --- | --- |
| `scenes/MainGame.tscn` | Root layout, title, Play screen, pause and handbook panels; references the other major scenes |
| `scenes/GameBoard.tscn` | Frame, tile layer, particle/score layer, audio; board swap/fall speeds and starting blocker positions |
| `scenes/Tile.tscn` | Candy icon, click target, selection, coating and lock marks |
| `scenes/JokerManager.tscn` | Equipped Joker list, capacity and stacking category queries; instantiated by the autoload |
| `scenes/UI_Hud.tscn` | Quota, score, Candys × Mult, moves, wallet and curse description |
| `scenes/JokerInventory.tscn` | Five ingredient slots and hover descriptions |
| `scenes/Shop.tscn` | Four visible offers, explicit wallet and prices, left Reroll/Next Round actions, bottom purchase/sale details |
| `scenes/GameOverScreen.tscn` | Defeat/victory messages, new run and title buttons |
| `scenes/MenuBackdrop.tscn` | Four original card sprites with optional whole-pixel drift |

`autoload/game_manager.gd` owns the run state, wallet, round transition signals and resource configuration. The board emits `move_made`, `matches_resolved`, `special_triggered` and `resolution_finished`. UI scenes subscribe to the manager's signals; they do not modify the board model.

`scripts/core/board_model.gd` contains pure grid rules and special-effect expansion. `score_engine.gd` calculates score independently of animation. `candy_state.gd` holds per-tile runtime data, while `CandyData` is the immutable authoring resource.

## Inspector tuning

Select `resources/default_run.tres` in the FileSystem dock. You can change starting money, total recipe slots, Small/Big/Boss rewards, unused-move bonus cap, reroll prices, gold/caramel Candys values, Heatwave age threshold, cascade safety limit, and the ordered candy, Joker and round resource arrays.

Round files are under `resources/rounds/`. Change `quota`, `moves`, `curse`, and the player-facing explanation. The default sequence is Small Batch, Big Batch, Boss, repeated three times. Bosses alternate Inspector, Heatwave, Inspector.

Candy files are under `resources/candies/`. Change base Candys, tint, texture, and display name. Different silhouettes accompany different colors. Set `spawn_weight` and `rarity` as well. All newly randomized candies use weighted draws, including initial fill, stabilization, recovery, refill, revival and Wild replacements.

Joker files are under `resources/jokers/`. Change price, title, description, icon, category, and supported strength. Supply cards use `spawn_color` and `spawn_multiplier` (default 2). The gameplay key is `id`; renaming the resource filename does not rename its effect. Strength is used by Kaleidoscope, Labyrinth, Gravity, Sledgehammer, Nuclear, Addict, and Roulette. Update descriptions when adjusting their numbers.

The `GameBoard` node exposes row/column counts, cell size, animation durations, tile scene, and starting blocker positions. The shipped layout and art are designed for 8 × 8 with 56-pixel cells. Changing board dimensions also requires resizing the frame and arranging the MainGame layout; UI geometry is deliberately visible in the editor.

## Add content

1. In the FileSystem dock, create a new Resource and select `CandyData`, `JokerData`, or `RoundData`.
2. Fill in its fields and save it under the corresponding resource folder.
3. Add it to the relevant array in `default_run.tres`.
4. A new candy or round uses the existing systems. A new Joker behavior also needs an ID handler in the rule/effect/scoring module. Geometry hooks belong in `BoardModel.matches`, four/five effects in `BoardModel.expand`, score modifiers in `ScoreEngine.calculate`, and round-bound effects in GameManager.
5. Add a deterministic fixture to the tests for a new mechanic. Existing tests show both isolated rules and animated live-scene integration.

For a custom fixed board, modify `GameBoard.start_round` after `fill_fresh`, assigning CandyState values and blocker strengths. Keep the stable/playable validation at the end.

## Aseprite workflow

Editable masters are in `assets/source/aseprite/`. Open them directly in Aseprite. Candy documents are 24 × 24; Joker cards are 70 × 94; the background is 576 × 360. Nine-slice UI skins are 24 × 24, tile overlays 56 × 56, and badges 32 × 32.

- Candy layers: ink silhouette and pixel finish.
- Card layers: Card stock and ink, Illustration, Title and edition marks.
- Background: `table_felt.aseprite` paints the runtime table. The old shader is unused. UI skins, tile marks, route badges, particles, overlay and the bitmap glyph atlas have separate editable Aseprite masters; see ASSETS.md.

After editing, save the `.aseprite` document and export a PNG with the same basename into `assets/exported/`. Godot reimports that texture automatically. Keep canvas dimensions and transparency intact.

**Export Art.cmd** exports all current masters without replacing their layers or drawings. `tools/export_art.lua` performs the batch export with the local Aseprite CLI. The project uses nearest filtering, exact 2× candy sprites, and aspect-preserving viewport scaling. Arbitrary window sizes use fractional final scaling; the logical scene and input transform remain aligned.

`tools/create_art.lua` is the reproducible original drawing source. It recreates both masters and PNGs and will overwrite hand edits if run again. It is not the normal export command. `tools/create_ui_art.lua` similarly recreates the UI, round badges, table and font atlas; it overwrites edits to those masters. Use Export Art.cmd for normal editing instead.

The original sound is `assets/audio/pop.wav`, a short synthesized candy pop. Replace it with another short sound or adjust the Audio node's volume. Test runners always use the Dummy audio driver and the `--test` flag, so development runs remain silent.

## Test commands

Run with a Godot executable from the project directory:

```text
godot --headless --audio-driver Dummy --path . --editor --import --quit
godot --headless --audio-driver Dummy --path . res://tests/TestRunner.tscn -- --test
godot --audio-driver Dummy --path . res://tests/EffectsRunner.tscn -- --test
godot --audio-driver Dummy --path . res://tests/ShopRunner.tscn -- --test
godot --audio-driver Dummy --path . res://tests/SynergyRunner.tscn -- --test
godot --audio-driver Dummy --path . res://tests/RouteRunner.tscn -- --test
godot --audio-driver Dummy --path . res://tests/RarityRunner.tscn -- --test
```

For screenshots, set `SUGAR_CAPTURE_DIR` to an existing absolute output directory before running a suite without `--headless`. Screenshots are captured from Godot's own viewport. Automated tests do not save sound/motion preferences or touch active player runs.

## Window sizing after the visual revision

Change the physical window size or the window width/height override to suit your screen. `MainGame` pins the **logical** design canvas to 1152 × 720 on startup, so changing project viewport defaults cannot shift gameplay hitboxes. The game uses Godot's native aspect-preserving viewport transform with letterboxing, and supports physical windows from 640 × 400 upward.

To redesign the logical layout itself, change `DESIGN_SIZE` in `main_game.gd` and update the scene positions together. The board owns mouse hit testing; individual animated sprites and effects ignore pointer input. Tile movement tweens are tracked and cancelled before replacement, and input is released only after gravity has settled.

The layout regression suite injects physical client-coordinate mouse events through the Window GUI pipeline, rather than calling `choose()` directly:

```text
godot --audio-driver Dummy --path . res://tests/ResizeRunner.tscn -- --test
```

`tools/create_supply_art.lua` recreates the six Supply cards and the open blocker frame in Aseprite. Normal hand edits should use Export Art.cmd, which preserves the artwork.

## Collection

`scripts/ui/collection.gd` builds the menu collection from `GameManager.config.jokers`, six per page. It uses the existing Aseprite card art, UI skins and bitmap font. Adding a Joker resource to the run configuration includes it automatically. The source project folder keeps its prior name so existing editor shortcuts continue working; the application and distribution are Sugar Rush.

Run `godot --audio-driver Dummy --path . res://tests/CollectionRunner.tscn -- --test` to check collection navigation, card bindings, layout and resize input.
