# Visual asset sources

Every exported visual texture has a matching editable Aseprite document. New replacement artwork was created with Aseprite's Lua drawing API and saved as native `.aseprite` masters before export. The game loads these PNGs directly, including the UI, table, board marks, particles and bitmap font atlas.

Sources: `assets/source/aseprite/`. Runtime exports: `assets/exported/`.

## Editing and export

1. Open a master in Aseprite, edit its layers, and save it.
2. Run **Export Art.cmd**. This opens each saved master in Aseprite and exports the matching PNG without regenerating the artwork.
3. Godot reimports the changed textures. Keep dimensions unchanged, especially the UI corner regions and font glyph cells.

`tools/create_art.lua` reconstructs the original candy and card drawings. `tools/create_ui_art.lua` reconstructs the new UI and table drawings, badges, and glyph atlas. These are regeneration tools and overwrite manual edits; normal editing uses Export Art.cmd.

UI panels use nine-slice texture borders. The gold progress fill has a separate `ui_progress_gold.aseprite` master from the candy's `ui_gold.aseprite` overlay. Lock badges and blocker crosses are deliberately distinct.

`font_atlas.aseprite` contains rasterized m6x11 glyphs by Daniel Linssen; attribution and permission remain in `assets/fonts/`. This atlas remains in the card-art tools; dynamic UI text now uses `readable_font.fnt`. The font shapes are credited to their original designer.

Godot still performs layout, hit testing, text composition and animation; these are runtime behavior, not image assets. Audio remains WAV because Aseprite edits images. The original TTF files and licenses remain available for editing and regenerating typography; runtime text uses the exported bitmap fonts.

## Complete image inventory

| Aseprite master | PNG export | Pixels |
| --- | --- | --- |
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
| `ui_wild.aseprite` | `ui_wild.png` | 56 x 56 |

Six new Supply card illustrations and the transparent-center blocker frame were created in Aseprite with `tools/create_supply_art.lua`.

Four exact-three Joker cards are drawn and exported by `tools/create_three_art.lua` using Aseprite. Each 70 x 94 card retains separate stock, illustration and lettering layers:

- `assets/source/aseprite/pop_rock.aseprite` → `assets/exported/pop_rock.png`
- `assets/source/aseprite/sweet_tooth.aseprite` → `assets/exported/sweet_tooth.png`
- `assets/source/aseprite/golden_trio.aseprite` → `assets/exported/golden_trio.png`
- `assets/source/aseprite/three_scoops.aseprite` → `assets/exported/three_scoops.png`

`ui_roulette.aseprite` → `ui_roulette.png`: transparent 56 x 56 tile overlay with a small roulette wheel in the upper-right corner. Created and exported in Aseprite by `tools/create_roulette_art.lua`; separate rim, pockets and hub layers.

`readable_font_atlas.aseprite` exports `readable_font_atlas.png`: a 1536 x 576 interface glyph atlas based on Chakra Petch SemiBold. `tools/create_readable_font.lua` creates the native master and exports PNG and BMFont metrics. All UI headings, body text and score numbers use this font. Card illustration lettering keeps its original artwork. See `assets/fonts/CREDITS.md`.

`ui_volume_knob.aseprite` → `ui_volume_knob.png`: 16 x 24 slider grip created/exported in Aseprite by `tools/create_volume_art.lua`. Slider tracks reuse existing Aseprite skins. `shaders/crt.gdshader` provides the runtime screen treatment without changing the underlying art or pointer geometry.

`sugar_shaker.aseprite` → `sugar_shaker.png`: 32 x 40 consumable icon, drawn/exported in Aseprite by `tools/create_shaker_art.lua`, with separate glass, sugar-crystal and lid layers.


### Consumable cards (v0.15)

`tools/create_consumable_art.lua` draws and exports four layered 70 x 94 cards in Aseprite: `sugar_shaker_card`, `extra_serving`, `golden_glaze`, and `candy_hammer`. Editable masters are in `assets/source/aseprite/`; runtime PNGs are in `assets/exported/`. They share a cream card frame, pixel lettering and the existing game palette; the Shaker card incorporates the original Aseprite jar artwork.

## Special candies (v0.19)

`tools/create_special_art.lua` draws these with Aseprite (layered masters kept):

- `assets/source/aseprite/ui_striped_h.aseprite` → `assets/exported/ui_striped_h.png` (56 x 56 row-stripe overlay)
- `assets/source/aseprite/ui_striped_v.aseprite` → `assets/exported/ui_striped_v.png` (56 x 56 column-stripe overlay)
- `assets/source/aseprite/ui_wrapped.aseprite` → `assets/exported/ui_wrapped.png` (56 x 56 wrapper overlay)
- `assets/source/aseprite/candy_bomb.aseprite` → `assets/exported/candy_bomb.png` (24 x 24 Color Bomb, shown at 2x)
- `assets/source/aseprite/striper.aseprite` → `assets/exported/striper.png` (70 x 94 card)
- `assets/source/aseprite/wrapper.aseprite` → `assets/exported/wrapper.png` (70 x 94 card)
- `assets/source/aseprite/bomb_maker.aseprite` → `assets/exported/bomb_maker.png` (70 x 94 card)

## Joker editions and scaling Jokers (v0.21)

`tools/create_edition_art.lua` draws these with Aseprite (layered masters kept):

- `assets/source/aseprite/edition_foil.aseprite` → `assets/exported/edition_foil.png` (70 x 94 overlay)
- `assets/source/aseprite/edition_holo.aseprite` → `assets/exported/edition_holo.png` (70 x 94 overlay)
- `assets/source/aseprite/edition_poly.aseprite` → `assets/exported/edition_poly.png` (70 x 94 overlay)
- `assets/source/aseprite/sugar_cube.aseprite` → `assets/exported/sugar_cube.png` (70 x 94 card)
- `assets/source/aseprite/gumball_jar.aseprite` → `assets/exported/gumball_jar.png` (70 x 94 card)
- `assets/source/aseprite/candy_cane.aseprite` → `assets/exported/candy_cane.png` (70 x 94 card)

## Bosses and obstacles (v0.22)

`tools/create_boss_art.lua` draws these with Aseprite (layered masters kept):

- Boss icons (32 x 32): `ui_chocolatier`, `ui_frost`, `ui_sour`, `ui_spoon`, `ui_jelly`, `ui_tax`, `ui_hurry` (`assets/source/aseprite/<name>.aseprite` → `assets/exported/<name>.png`)
- Tile overlays (56 x 56): `ui_chocolate`, `ui_frost_1`, `ui_frost_2`, `ui_mark_jelly`, `ui_mark_sour`

## Booster packs (v0.23)

`tools/create_pack_art.lua` draws these with Aseprite (layered masters kept), 70 x 94 each:
`pack_joker`, `pack_recipe`, `pack_candy`, `pack_treat`, `pack_rush`, and the `pack_jumbo` banner overlay (`assets/source/aseprite/<name>.aseprite` → `assets/exported/<name>.png`).

## Candy-shop revision (v0.24)

`tools/create_v2_art.lua` (Aseprite, layered masters kept) **supersedes** the candy drawings in `create_art.lua` and the panels, board tiles, particle and table in `create_ui_art.lua`. If you regenerate everything, run it after those two scripts. It writes:

- Candies `candy_0`–`candy_5` and `candy_bomb` (24 x 24): soft shadow, body/shading and glint layers.
- Board tiles `ui_tile_a`, `ui_tile_b` (56 x 56) and the idle `ui_glint` (16 x 16); sparkle `ui_particle` (32 x 32).
- Nine-slice skins (24 x 24): `ui_panel`, `ui_inset`, `ui_disabled`, `ui_boss`, `ui_progress_gold`, `ui_green`, `ui_blue`, `ui_button` (+ `_hover`, `_pressed`) and role buttons `ui_btn_{go,info,buy,skip,danger,neutral}` (+ `_hover`, `_pressed`).
- Backdrop: `table_felt` (576 x 360 painted base with vignette) and `backdrop_tile` (96 x 96 seamless stripe-and-sprinkle layer that drifts at runtime).

## Balatro-style HD pass (v0.25)

`tools/create_hd_art.lua` runs **after every other art script** and writes layered Aseprite masters plus PNGs:

- Rounded 32 x 32 nine-slice skins with a raised lip for all panels and buttons (`ui_panel`, `ui_inset`, `ui_disabled`, `ui_boss`, `ui_progress_gold`, `ui_green`, `ui_blue`, `ui_button*`, `ui_btn_*`). `UIStyle.skin()` uses 10 px margins.
- Native 48 x 48 candies `candy_0`–`candy_5` and `candy_bomb`, shaded per pixel from signed-distance shapes (lighting, 4x4 Bayer-dithered colour ramps, coloured outlines, glints, soft shadow), and rounded 56 x 56 `ui_tile_a`/`ui_tile_b`.
- HD cards: every 70 x 94 card, pack and edition PNG is upscaled with Scale2x to 140 x 188, given rounded corners and paper grain, and re-saved as a layered master. Already-HD images are skipped, so the script is safe to re-run.

Shaders (owner-approved): `shaders/candy_swirl.gdshader` (pixelated, posterised swirling background on the `CandySwirl` layer above the painted `table_felt`) and `shaders/card_tilt.gdshader` with `scripts/ui/card_tilt.gd` (cards tilt toward the pointer, lift and shine on hover, sway at rest). Both pause with Reduced motion.

## Native HD Joker cards (v0.26)

`tools/create_joker_hd.lua` redraws all 32 Joker cards natively at 140 x 188 (run it after `create_hd_art.lua`; pass `--script-param only=<card>` to redraw one). Each master has three layers: card stock and frame (rounded cream stock, ink outline, art window, category gem), illustration (per-pixel shaded shapes over a category-tinted patterned background, with drop shadows, glints and sparkles; Supply cards stamp the HD candies), and lettering (m6x11 at 2x, proportional). Category tints: Geometry blue, 4+ green, 5+ purple, Chaos red, Supply caramel, Three pink, Special teal, Scaling gold.

Regeneration order for all art: the original `create_*.lua` scripts, then `create_hd_art.lua`, then `create_joker_hd.lua`.

## The rest of the art in HD (v0.27)

`tools/create_joker_hd.lua` now also draws, with the same shading library (run the extras alone with `--script-param only=extras`):

- Consumable cards `sugar_shaker_card`, `extra_serving`, `golden_glaze`, `candy_hammer` (140 x 188, orange "Treat" frame).
- Booster packs `pack_joker`, `pack_recipe`, `pack_candy`, `pack_treat`, `pack_rush` (crimped foil bags with label and emblem) and the `pack_jumbo` ribbon.
- Edition overlays `edition_foil`, `edition_holo`, `edition_poly` matching the 10 px card corners.
- Route and boss icons at 48 x 48: `ui_small`, `ui_big`, `ui_done` and all nine bosses.
- 56 x 56 tile overlays: striped (h/v), wrapped, chocolate, frosting (1/2), jelly, sour, blocker, lock, gold, caramel, wild, and rounded selection frames (selected, hint, hover, focus, isotope).

## Audio (v0.31)

Music (`assets/audio/music_*.wav`) and effects (`assets/audio/sfx_*.wav`) are synthesised from code, so there are no third-party audio licences. To regenerate after editing `tools/generate_audio.gd`:

```
Godot --headless --audio-driver Dummy --path . -s res://tools/generate_audio.gd
```
