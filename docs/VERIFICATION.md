# Verification — 7 October 2026

Tested using the user's installed Godot 4.7.2, Windows, GL Compatibility renderer on Intel Iris Xe. Automated audio uses the Dummy driver.

- **51 model/run checks passed:** all 16 Joker mechanics, horizontal/vertical/diagonal/wrapped matches, cyclic deduplication, L/T promotion, anchored gravity, both curses, all content resources, score formulas, poisoned quota evaluation, purchases/sales, duplicate and unaffordable purchase rejection, and nine-round victory progression.
- The model suite includes **100 initial boards** across five geometry builds, checking stable starts and at least one legal move.
- **18 additional effect/UI checks passed:** all eight four/five special effects through the real GameBoard resolver, overlapping blast accounting, animated click swaps, input locking, pause and handbook behavior, the shop footer with five equipped Jokers, and Heatwave aging of newly spawned/falling tiles.
- Headless and rendered test runs completed without script errors. Real viewport screenshots were reviewed, revealing and correcting shop footer clipping and missing Aseprite emblem layers. Modals were raised above particle/score effects and transient effects are cleared on round transitions.
- Aseprite generated 23 layered editable documents and corresponding PNG exports. Its preinstalled PixelLab extension emits an unrelated startup warning in batch mode; the art generation itself completes.

`screenshots/title.png`, `screenshots/gameplay.png`, `screenshots/shop_full.png`, and `screenshots/handbook.png` show the rendered implementation. The full-inventory shop screenshot deliberately uses a forced score to exercise overflow and layout; it is not a claim about natural player performance.

Automated campaign progression forces quota scores to validate transitions; it does not prove difficulty balance, player win rates, or commercial release readiness. Balance values remain available in resources for playtesting.

A separate clean copy also imported successfully with no existing Godot cache. The Aseprite export script was executed against the editable masters.

## Resize/input and art revision

- 31 rendered resize/input checks passed with 0 errors. Physical pointer input correctly selected all 62 non-blocked cells at each of 1152×720, 800×500, 1280×720, 1440×900, 960×720, 720×960, 1600×700 and 640×400: **496 individual cell-selection assertions**.
- A real pointer swap was verified at each size. Resizing during an animated swap/cascade left every sprite on its model coordinate. Resized Options and modal blocking were also tested.
- Input is now routed through the board rectangle, independent of animated sprites. Replaced tweens are cancelled and input remains locked until final gravity completes.
- Render review caught button minimum-height overflow and doubled line spacing caused by physical multiline resource strings. Button padding and string serialization were corrected.
- The first visual revision added original Aseprite art, Pixelify Sans, felt shader, score ticker and chip/mult panels replace the previous presentation. No generated raster images or Balatro assets were used.
- Current reviewed previews: `screenshots/redesigned_gameplay.png` and `screenshots/redesigned_shop.png`.

The final physical-input suite also verified buying the exact shop card under the pointer and continuing into the next round. Final regression totals: 51 model/run + 18 effects/UI + 31 resize/input checks, all passing.

## Readability and shop revision

- Replaced the active font with Daniel Linssen's m6x11, enlarged text and wallet numbers, removed doubled text shadows, and corrected corrupted menu characters and card-title clipping.
- Rebuilt all 16 cards as consistent 70 x 94 layered Aseprite illustrations. The shop shows them at exact 2x scale with all four prices and Buy actions visible together.
- The HUD remains visible in the shop. Available cash mirrors it, projected balances explain purchases and sales, and receipts state transaction amounts. The detail panel explains insufficient cash and conflicting Joker slots.
- 26 new rendered shop checks passed, including cash consistency after purchases, sales and rerolls, projected balances, all offer controls, owned-card selection, unaffordable and conflicting purchases, and Next Round physical clicks at three window sizes.
- Reran all 18 effect/UI checks and all 31 resize/input checks against the final interface, with zero failures. The resize suite includes 496 physical cell selections across eight window sizes and verifies shop Buy and Next Round hitboxes.
- Reviewed current viewport captures: screenshots/v3_title.png, screenshots/v3_gameplay.png, screenshots/v3_shop.png and screenshots/v3_handbook.png. These use deterministic test fixtures, including forced score/cash to exercise shopping. screenshots/v3_card_collection.png shows the final original card art.

## Stacking, pause, and economy revision

- Removed category exclusivity while retaining five slots and unique Joker IDs. Verified all 120 distinct pairs in both purchase orders.
- 20 new synergy/economy/pause checks pass. These cover complete four-match and five-match builds, repaint-to-attraction interaction, deduplicated chips, purchase-order independence, revived/gilded candy, persistent isotopes, bounded round/campaign cash, pause during a live swap, Options, Resume, shop pause, and Quit to Title. Both stacked builds also resolve through the actual animated-board code with refill and cascades.
- Reran 51 model/run, 18 effect/UI, 27 shop/readability, and 31 resize/input checks successfully. Every rewritten Joker description fits the shop detail area. The resize suite includes 496 physical cell selections across eight window sizes.
- The pause screen is captured in screenshots/v4_pause.png. The latest v3_shop.png is an explicit $40 UI fixture; ordinary first-shop cash follows the $4 starting balance plus the bounded round reward.
- Cash balance is now independent of high-scoring combos. The reward schedule and prices are initial playtest tuning; automated checks establish the economic limits and transaction correctness, not long-term player difficulty preferences.

## Round route and Aseprite visual pipeline — 8 October 2026

- Added a pre-round ante map showing Small, Big and Boss stages, cleared/upcoming status, quotas, moves, fixed rewards and boss rules. The start button and shop exit both use it. Back returns without advancing or paying again.
- The HUD previews the boss countdown; Inspector rounds name the locked candy and draw an Aseprite padlock separately from blocker crosses.
- 51 route/art checks passed across all nine rounds and final victory, including every next-round preview, back navigation, boss order, HUD bounds, and asset-source completeness.
- Reran 51 model/run, 18 effect/UI, 20 synergy/economy/pause, 30 shop/readability, and 31 resize/input checks. The shop suite physically enters the route at three window sizes, and resize verification still includes 496 board-cell selections.
- Exported all saved Aseprite masters using the actual Aseprite batch exporter. Every PNG has a corresponding native master, listed in ASSETS.md. No runtime shape drawing or procedural background shader remains in the active game visuals. Text uses the exported bitmap atlas.
- Reviewed screenshots/v5_round_map.png and screenshots/v5_boss_gameplay.png. Render review corrected texture lifetime, panel color selection, and long boss HUD overflow. Boss preview screenshots use progression fixtures; they do not represent organically played wins.

## Candy rarity, clean shop and break rewards — 8 October 2026

- 38 new checks pass for weighted rarity, six Supply cards, normalization and stacking, seed determinism, 3/4/5+ adjacency breaks, per-tile rewards before Mult, preserved graves, open-frame artwork, clean shop state, Candy Guide layout and purchase-to-board behavior.
- 60,000 seeded random draws stayed within 0.8 percentage points of the configured probabilities. Across 80 stabilized boards, frequency remained ordered from common to rare: 1286 / 1186 / 959 / 797 / 523 / 369 candies.
- The live effect suite verifies that overlapping blasts pay each candy and its break bonus once. All 231 different Joker pairs equip in either order.
- Final suites: 51 model/run, 18 effect/UI, 20 synergy/economy/pause, 30 shop/readability, 51 route/art, 31 resize/input and 38 rarity/break/shop checks, all passing (239 total).
- Reviewed screenshots/v6_shop_clean.png, screenshots/v6_gameplay.png and screenshots/v6_candy_guide.png. The shop screenshot uses an explicit $20 test wallet. All 22 card descriptions fit the selected-card panel.
- Added six native Aseprite Supply card masters and replaced the opaque blocker drawing with a transparent open frame. Every exported texture still has an editable Aseprite source.

## Direct lock correction — v0.6.1

The reported behavior was reproduced as a rule mismatch: the previous implementation allowed only adjacent matches and specials to break locks. Matching now includes the trapped candy itself. 46 rendered physical-input checks pass for adjacent and direct breaking, both kinds of lock, lengths 3/4/5, animations on/off, correct move consumption, graves and bonus awards. The model/run (51), live effects (18), and rarity/shop (38) suites also pass after this correction. Window and title-screen version labels distinguish the corrected process from an already-running build.

## Sugar Rush v0.7 — Collection

58 collection/name checks passed: title/HUD/application branding, all 22 artwork/effect bindings, every description fitting its panel, all four pages, navigation boundaries, Back/Escape, and physical clicks after resizing to landscape, portrait and ultrawide windows. Reviewed v7_title.png and v7_collection.png. Existing preferences retain the previous user-data directory across the rename. The collection reuses the existing Aseprite assets; it does not introduce code-drawn art.

## Exact-three Jokers

Godot 4.7.2, Dummy audio, `--test`: ThreeRunner 12, TestRunner 51, EffectsRunner 22, SynergyRunner 21, ShopRunner 30, CollectionRunner 66, LockedSwapRunner 46 and RouteRunner 51 checks passed (299 checks). CollectionRunner also passed all 66 checks with the OpenGL renderer. Visually inspected each new Aseprite export and the rendered final collection page. Coverage includes stacked live-board resolution, clipping the 3x3 blast, unique scoring, gold and lock bonuses, preserving larger-match effects, excluding synthetic wild clears, shop text fit and collection pagination.

## Six-ante campaign

Godot 4.7.2 with Dummy audio: 150 route/art checks, 51 core/gameplay checks and 21 synergy/economy checks passed. The route suite also passed 150 checks with the OpenGL renderer; the final ante preview was visually inspected. Tests walk all 18 rounds, verify boss previews and six-ante counters beyond round nine, preserve shop/back navigation and confirm victory only after round 18. These checks validate progression and scoring rules; the new difficulty curve is an initial balance pass, not a guarantee of equal win rates across Joker builds.

## Run-only candy upgrades

Godot 4.7.2 with Dummy audio: UpgradeRunner 21, ShopRunner 30, RarityRunner 38, ThreeRunner 12 and TestRunner 51 checks passed. UpgradeRunner and RarityRunner ran with the OpenGL renderer; the upgrade shop and Candy Guide were visually inspected. Tests cover repeat purchases, independent types/prices, cash validation, buying with five Jokers, 100 repeat purchases, run reset, upgraded gold/caramel and locked-candy scoring, guide/hover values and physical clicks at three window sizes. UI reuses existing Aseprite candy sprites, font atlas and skins.

## Roulette target visibility

RouletteUIRunner passed 32 checks with the OpenGL renderer: every selected-type candy is marked, including locked/coated tiles; markers follow swaps/refills, remain after matching, reset between rounds and disappear without the Joker. The actual custom tooltip names the target and reports penalty status. HUD bounds checked for all six target types across normal, Inspector and Heatwave rounds. Rendered tooltip/board visually inspected. EffectsRunner passed 22 checks and RouteRunner passed 150 checks, including Aseprite source provenance.

## Readability pass

All 368 checks passed using Godot 4.7.2 OpenGL with Dummy audio: ShopRunner 30, UpgradeRunner 21, RouletteUIRunner 32, CollectionRunner 66, RouteRunner 150, RarityRunner 38 and ResizeRunner 31. Visually inspected the rendered shop, upgrade page, collection and Roulette tooltip. Coverage includes two-line shop descriptions, all collection cards, late-ante panels, boss/roulette HUD text and click alignment across window sizes. Body text uses the new Aseprite-exported Pixelify Sans Medium atlas with expanded word spaces; major headings and scores keep the original font.

## CRT, audio and settings

98 checks passed with the OpenGL renderer and Dummy audio: SettingsRunner 16, ResizeRunner 31, SynergyRunner 21 and ShopRunner 30. Settings coverage includes disk save/reload of all four options, old-file defaults, a physical slider click while paused, zero-volume mute/full-volume restore, pitch bounds/variation and RNG independence. Visually inspected CRT on/off and the options panel. Resize tests cover 496 board hitboxes and physical controls through eight window sizes with CRT enabled. Settings tests use and remove a separate test file; player preferences are preserved.

## Sugar Shaker consumable

252 checks passed: ShakerRunner 20 and ShopRunner 30 rendered, SynergyRunner 21, RouteRunner 150, ResizeRunner 31 rendered. Coverage includes physical purchases/use, two-item capacity independent of five Jokers, unchanged score/moves/streak, object/lock/coating/age preservation, safe-board generation, failure refunds, queued use, cancellation on round end, pause/quit during animation and run reset. Visually inspected shop and gameplay with CRT enabled. The headless resize run waited on its existing screenshot callback; it passed when rerun using its intended renderer.
