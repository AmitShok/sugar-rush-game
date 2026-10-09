# Visual asset sources

Every exported visual texture has a matching editable Aseprite document. New replacement artwork was created with Aseprite's Lua drawing API and saved as native `.aseprite` masters before export. The game loads these PNGs directly, including the UI, table, board marks, particles and bitmap font atlas.

Sources: `assets/source/aseprite/`. Runtime exports: `assets/exported/`.

## Editing and export

1. Open a master in Aseprite, edit its layers, and save it.
2. Run **Export Art.cmd**. This opens each saved master in Aseprite and exports the matching PNG without regenerating the artwork.
3. Godot reimports the changed textures. Keep dimensions unchanged, especially the UI corner regions and font glyph cells.

`tools/create_art.lua` reconstructs the original candy and card drawings. `tools/create_ui_art.lua` reconstructs the new UI and table drawings, badges, and glyph atlas. These are regeneration tools and overwrite manual edits; normal editing uses Export Art.cmd.

UI panels use nine-slice texture borders. The gold progress fill has a separate `ui_progress_gold.aseprite` master from the candy's `ui_gold.aseprite` overlay. Lock badges and blocker crosses are deliberately distinct.

`font_atlas.aseprite` contains rasterized m6x11 glyphs by Daniel Linssen; attribution and permission remain in `assets/fonts/`. `ui_font.fnt` provides character spacing and atlas coordinates so dynamic scores and descriptions remain real text. The font shapes are credited to their original designer.

Godot still performs layout, hit testing, text composition and animation; these are runtime behavior, not image assets. Audio remains WAV because Aseprite edits images. The earlier felt shader and TTF files are retained as unused reference sources, and are not the active visual render path.

## Complete image inventory

| Aseprite master | PNG export | Pixels |
| --- | --- | --- |
| `background.aseprite` | `background.png` | 576 x 360 |
| `candy_0.aseprite` | `candy_0.png` | 24 x 24 |
| `candy_1.aseprite` | `candy_1.png` | 24 x 24 |
| `candy_2.aseprite` | `candy_2.png` | 24 x 24 |
| `candy_3.aseprite` | `candy_3.png` | 24 x 24 |
| `candy_4.aseprite` | `candy_4.png` | 24 x 24 |
| `candy_5.aseprite` | `candy_5.png` | 24 x 24 |
| `font_atlas.aseprite` | `font_atlas.png` | 256 x 128 |
| `joker_0.aseprite` | `joker_0.png` | 70 x 94 |
| `joker_1.aseprite` | `joker_1.png` | 70 x 94 |
| `joker_10.aseprite` | `joker_10.png` | 70 x 94 |
| `joker_11.aseprite` | `joker_11.png` | 70 x 94 |
| `joker_12.aseprite` | `joker_12.png` | 70 x 94 |
| `joker_13.aseprite` | `joker_13.png` | 70 x 94 |
| `joker_14.aseprite` | `joker_14.png` | 70 x 94 |
| `joker_15.aseprite` | `joker_15.png` | 70 x 94 |
| `joker_2.aseprite` | `joker_2.png` | 70 x 94 |
| `joker_3.aseprite` | `joker_3.png` | 70 x 94 |
| `joker_4.aseprite` | `joker_4.png` | 70 x 94 |
| `joker_5.aseprite` | `joker_5.png` | 70 x 94 |
| `joker_6.aseprite` | `joker_6.png` | 70 x 94 |
| `joker_7.aseprite` | `joker_7.png` | 70 x 94 |
| `joker_8.aseprite` | `joker_8.png` | 70 x 94 |
| `joker_9.aseprite` | `joker_9.png` | 70 x 94 |
| `supply_berry.aseprite` | `supply_berry.png` | 70 x 94 |
| `supply_caramel.aseprite` | `supply_caramel.png` | 70 x 94 |
| `supply_lemon.aseprite` | `supply_lemon.png` | 70 x 94 |
| `supply_mint.aseprite` | `supply_mint.png` | 70 x 94 |
| `supply_peppermint.aseprite` | `supply_peppermint.png` | 70 x 94 |
| `supply_plum.aseprite` | `supply_plum.png` | 70 x 94 |
| `table_felt.aseprite` | `table_felt.png` | 576 x 360 |
| `ui_arrow.aseprite` | `ui_arrow.png` | 32 x 32 |
| `ui_big.aseprite` | `ui_big.png` | 32 x 32 |
| `ui_blocker.aseprite` | `ui_blocker.png` | 56 x 56 |
| `ui_blue.aseprite` | `ui_blue.png` | 24 x 24 |
| `ui_boss.aseprite` | `ui_boss.png` | 24 x 24 |
| `ui_button.aseprite` | `ui_button.png` | 24 x 24 |
| `ui_button_hover.aseprite` | `ui_button_hover.png` | 24 x 24 |
| `ui_button_pressed.aseprite` | `ui_button_pressed.png` | 24 x 24 |
| `ui_caramel.aseprite` | `ui_caramel.png` | 56 x 56 |
| `ui_disabled.aseprite` | `ui_disabled.png` | 24 x 24 |
| `ui_done.aseprite` | `ui_done.png` | 32 x 32 |
| `ui_focus.aseprite` | `ui_focus.png` | 56 x 56 |
| `ui_gold.aseprite` | `ui_gold.png` | 56 x 56 |
| `ui_green.aseprite` | `ui_green.png` | 24 x 24 |
| `ui_heatwave.aseprite` | `ui_heatwave.png` | 32 x 32 |
| `ui_hint.aseprite` | `ui_hint.png` | 56 x 56 |
| `ui_hover.aseprite` | `ui_hover.png` | 56 x 56 |
| `ui_inset.aseprite` | `ui_inset.png` | 24 x 24 |
| `ui_inspector.aseprite` | `ui_inspector.png` | 32 x 32 |
| `ui_isotope.aseprite` | `ui_isotope.png` | 56 x 56 |
| `ui_lock.aseprite` | `ui_lock.png` | 56 x 56 |
| `ui_panel.aseprite` | `ui_panel.png` | 24 x 24 |
| `ui_particle.aseprite` | `ui_particle.png` | 32 x 32 |
| `ui_progress_gold.aseprite` | `ui_progress_gold.png` | 24 x 24 |
| `ui_selected.aseprite` | `ui_selected.png` | 56 x 56 |
| `ui_shade.aseprite` | `ui_shade.png` | 32 x 32 |
| `ui_small.aseprite` | `ui_small.png` | 32 x 32 |
| `ui_tile_a.aseprite` | `ui_tile_a.png` | 56 x 56 |
| `ui_tile_b.aseprite` | `ui_tile_b.png` | 56 x 56 |
| `ui_toggle_off.aseprite` | `ui_toggle_off.png` | 32 x 32 |
| `ui_toggle_on.aseprite` | `ui_toggle_on.png` | 32 x 32 |
| `ui_white.aseprite` | `ui_white.png` | 32 x 32 |
| `ui_wild.aseprite` | `ui_wild.png` | 56 x 56 |

Six new Supply card illustrations and the transparent-center blocker frame were created in Aseprite with `tools/create_supply_art.lua`.

Four exact-three Joker cards are drawn and exported by `tools/create_three_art.lua` using Aseprite. Each 70 x 94 card retains separate stock, illustration and lettering layers:

- `assets/source/aseprite/pop_rock.aseprite` → `assets/exported/pop_rock.png`
- `assets/source/aseprite/sweet_tooth.aseprite` → `assets/exported/sweet_tooth.png`
- `assets/source/aseprite/golden_trio.aseprite` → `assets/exported/golden_trio.png`
- `assets/source/aseprite/three_scoops.aseprite` → `assets/exported/three_scoops.png`

`ui_roulette.aseprite` → `ui_roulette.png`: transparent 56 x 56 tile overlay with a small roulette wheel in the upper-right corner. Created and exported in Aseprite by `tools/create_roulette_art.lua`; separate rim, pockets and hub layers.
