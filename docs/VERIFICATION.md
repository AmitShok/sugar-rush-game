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


## Sweet consumables (v0.15)

272 checks passed: ConsumableRunner 20, ShakerRunner 20, ShopRunner 30, SynergyRunner 21, RouteRunner 150 and ResizeRunner 31. Consumable, Shaker, shop and resize suites ran with the renderer and Dummy audio. New coverage includes mixed two-slot inventory, exact prices, duplicate cards, discards, extra moves, targeted input at a portrait window size, cancellation and no-op preservation, type-specific gilding with Wild preservation, direct Hammer scoring and frame destruction, Roulette exclusion, queued use and round-end preservation. Existing suites cover all eighteen rounds, Joker synergies, pause/quit, eight window sizes, and Aseprite masters for every exported raster. Visually inspected the four-card shop browser with CRT enabled and aligned purchase controls.


## Random stock and saved runs (v0.16)

143 checks passed: SaveRunner 18, SaveBootRunner 3 across separate write/quit and read/continue processes, ShopRunner 30, ConsumableRunner 20, ShakerRunner 20, SynergyRunner 21, ResizeRunner 31. Saves round-trip all serialized gameplay/board fields and RNG continuation, reject malformed files, preserve purchased shop slots, refuse partial-cascade checkpoints, replace on New Run, and clear on run end. Physical UI checks cover Continue, buying/removing stock and shared paid refresh. Visually inspected title menu and two-card shop; existing Aseprite skins/art are reused without new raster assets. All game tests use isolated save paths, Dummy audio and --test.


## Quit to Title continuation

42 checks passed across rendered SaveRunner (21) and ShakerRunner (21). Physical pause-menu Quit to Title followed by Continue preserves the complete round and shop snapshots. Continuing after quitting during a paused Shaker animation restores the completed action and remaining inventory. Corrected the obsolete tooltip claiming Quit to Title ends the run; title now focuses Continue and confirms the saved run.


## Continue disabled after refill � fix

Root cause: BoardModel.refill sets new candy ages to -1, but run-save validation rejected every negative field in candy rows. The loader now permits age -1 while retaining nonnegative color/coating/blocker constraints and rejecting ages below -1. Reproduced failure before the fix using a read-only copy of the player's existing save; after the fix all serialized fields round-trip unchanged. SaveRefillRunner passes 7 checks (including the optional external fixture), with real-match refill followed by physical Quit to Title/Continue. SaveRunner passes 21 checks. The player's original save was not modified.


## Player-facing text review

Reviewed menu/HUD/shop/collection/consumable text, tooltips, handbook, candy/Joker/round resources and card-art lettering sources. Preserved the requested score term Candys and intentional names/abbreviations. Corrected singular round/move labels and the results screen total (now derived from the configured 18 rounds rather than hard-coded 9). Existing RouteRunner 150 and rendered ShopRunner 30 checks pass, including progression, HUD layout and Joker-description fit.


## Repository cleanup

Audited tracked runtime resources, dynamic texture references, scenes, scripts, tests and art/export tools. Removed 33 obsolete files: 24 documentation-image import sidecars (including three orphan sidecars), the unused felt shader and UID, two unused texture/master/import sets (old background and white tile), and stale VERSION.txt. Removed the disconnected tile click signal/handler, obsolete direct Shaker purchase handler and unused SHAKER_PRICE constant. Art generators no longer recreate removed assets. Documentation has .gdignore so screenshots remain useful records without becoming game resources. Active Aseprite masters, font source/licensing, test suites and art tools remain.

Godot editor import completed successfully and static runtime resource paths have no missing targets. 256 checks passed: core TestRunner 51, RouteRunner 150, rendered ResizeRunner 31, SaveRefillRunner 4 and ConsumableRunner 20. Pre-existing unrelated project settings and generated metadata were left unstaged.


## Clearer interface typography

Replaced runtime Pixelify Sans/m6x11 typography with Chakra Petch SemiBold across body text, controls, headings and score/cash numbers. Glyphs were drawn into a native 1536 x 576 Aseprite atlas and exported through Aseprite with BMFont metrics; source font and OFL attribution are included. Existing card illustration lettering remains intact. Visually inspected title, gameplay and shop with CRT enabled. 147 rendered checks passed: ShopRunner 30, ResizeRunner 31 (eight window sizes), CollectionRunner 66 (all 26 descriptions), ConsumableRunner 20. Import completed without errors.


## Windows / web exports (v0.17)

Built Windows x86-64 and single-threaded WebGL 2 release exports with Godot 4.7.2 and matching templates. Both export logs are free of script/export errors; ZIP integrity and bundled font/engine notices checked. Source art, tests, tools and documentation are excluded from the game pack. Actual Windows EXE input test passes new run, swap, save, Quit to Title/Continue, another swap and clean close. Actual web release passes the same flow plus IndexedDB persistence across reload in Chrome and Edge at 1152x720 desktop, 844x390 touch landscape, 768x1024 touch tablet and 390x844 touch portrait. Browser contexts are isolated and report no console/page errors.

238 Godot checks pass: TouchRunner 17, SaveRunner 21, ResizeRunner 31, RouteRunner 150, SettingsRunner 19. Touch input includes real ScreenTouch events with mouse emulation, exact move counts, live Roulette inspection, modal close, pause/resume, volume and consumable purchase. Visually inspected web gameplay, pause, title and phone/tablet captures; corrected touch instructions to avoid Items overlap. Physical Android/iOS hardware, Safari and audible audio quality/latency remain untested. Full build/hosting/test instructions are in EXPORTING.md.


## iPhone dark-screen investigation (2026-10-19)

User reports Chrome on iPhone goes dark after New Run. Windows-hosted Playwright WebKit displays the route screen and completes desktop new-run/swap/save/title/continue/reload checks, but its strict smoke test fails on repeated glBlitFramebuffer errors (read/write attachments are the same image). These persist without the original CRT and with canvas-item scaling, so they do not establish the cause on the phone. Retained original viewport scaling. Hosted URL, physical iPhone reproduction and CRT-off comparison are pending; this is not a confirmed iPhone fix.

Web CRT now uses a blended overlay without screen-texture copies or multi-sample glow as a compatibility mitigation. Native CRT is unchanged. Added visible runtime/context-loss errors with reload/dismiss and optional WebKit testing. Rebuilt web release. Chrome passes all four viewport flows, including 3x DPR touch, exact moves, persisted Continue and injected graphics-loss message display/dismiss. Native SettingsRunner passes 19 checks. Player saves untouched.


## Hosted iPhone investigation and export packaging (2026-10-19)

Inspected https://amitshok.itch.io/sugar-rush and its public html-classic.itch.zone/html/19818933 export. Hosted HTML predates the runtime error overlay. Hosted pack is 7,233,092 bytes; pack directory comparison found imported test-capture images accounting for most of the excess. Hosted round-map and GameManager bytecode match local versions. The actual hosted game reaches the route screen and board in Windows WebKit at 844x390, DPR 3 with touch. This is not physical iPhone validation. User reports iPhone 14/latest iOS and CRT-off does not help; root cause remains unconfirmed.

Both presets now exclude builds/*; export tooling and capture tests create builds/.gdignore before import. Rebuilt Windows and web packs are 361,788 bytes each, with 328 entries; inspected directories contain no builds/tests/tools/docs/source-art entries or imported capture images. Both ZIPs pass integrity checks. Windows release start/swap/save/title/Continue/exit passes.
Chrome web smoke passes all four desktop/touch profiles, save/reload/Continue and visible error controls with no browser errors.


## Escalating paid hints (2026-10-19)

Hints cost $1 initially and increase by $1 after each successful purchase across the entire run. Button and H share the same charge, display, affordability and save path. Busy/paused/targeting/no-legal-move attempts do not charge; key repeats do not buy hints. Fixed keyboard hints being overwritten by the cursor highlight. Cash and hint count persist across rounds and Continue; old saves default to zero purchases. New Run resets the price. Updated button, tooltip, handbook and README. No artwork changes.

55 rendered checks pass: HintRunner 15, SaveRunner 21, SettingsRunner 19. An initial headless SaveRunner timed out at its existing screenshot wait; rerunning with rendering passed. Windows and web exports rebuilt successfully.


## Explicit round-preview layout (2026-10-20)

User clarified New Run leaves the menu dimly visible with no error. Reworked RoundMap to place panel/cards/labels/buttons in fixed logical rectangles and give its content an explicit z offset above the shade. Removed nested container layout from this modal. Reapply label rectangles after deferred text shaping, since tests exposed initial zero-width wrapping inflating label heights. Existing Aseprite skins and icons reused. The route and round-confirmation flow is unchanged.

Rendered RouteRunner passes 168 checks including first-frame panel geometry, content layering, all card bounds across the six antes and round navigation. Visually inspected first route preview; rebuilt Windows and web exports. Physical iPhone resolution remains unconfirmed.
Chrome actual web release passes desktop and three DPR-3 touch profiles: New Run, round confirmation, swaps, save/title/Continue, reload/Continue and error controls, with no browser errors. Inspected phone-landscape route capture.


## Confirmed RTL-locale off-screen panels (2026-10-20)

The user screenshot revealed right-aligned English title/seed text. Setting the locale to he reproduced the exact dim-menu symptom: RoundMap content appeared at x=1298 outside the 1152-wide viewport, while the shade remained visible. User also reported Collection off-screen to the right. Root LTR alone was insufficient because dynamically created, unattached Controls use the application locale before inheriting their parent. MainGame now selects English in _enter_tree before child UI construction and explicitly declares LTR layout. The game currently ships English text only; this does not change device/browser settings.

LocaleRunner failed before the fix and now passes 24 checks across Hebrew, Arabic and English system locales, including route bounds, visible Collection cards/details, physical Back/Play clicks and entering gameplay. Inspected Hebrew Collection and route captures. Added Hebrew/Arabic browser contexts to the actual exported web smoke test. Rebuilt both releases.
Actual Chrome web export passes all six profiles (English desktop/phone/tablet, Hebrew phone, Arabic phone), including New Run, swaps, saves, title/Continue, reload/Continue and no browser errors.


## Difficulty rebalance and Recipes (v0.18, 2026-11-11)

Balance: `tools/balance_sim.gd` (greedy bot over the real BoardModel/ScoreEngine, no curses) measured no-Joker play at ~4,000 per 10-move round and 4-5 Joker engines at 350k-520k after capping cascade Mult (+2), Addict (+1/streak) and Ouroboros (x1 per 10 candies). Quotas were rescaled to 1,500 → 350,000. Recipes at level 1 raise baseline scoring ~10%; all recipes at level 3 roughly double Joker-build scores. These are bot measurements, not player playtests.

Godot 4.7.2, rendered, Dummy audio, `--test`: all 22 suites pass (707 checks), including the new RecipeRunner (24: classification, level scoring, physical shop purchases, price steps, tab switching, sidebar table/last-recipe marker, save/Continue, run reset). Updated expectations: Diagonal/Quad recipe values in TestRunner and EffectsRunner, rarity break scoring, and ResizeRunner's forced score now uses the round quota. Visually inspected the Recipes shop tab and the in-round recipe sidebar.


## Special candies (v0.19, 2026-11-12)

New SpecialRunner (36 checks): Striper/Wrapper/Bomb Maker creation rules and placement at the swapped cell, Striped fallback for lines of 5, no specials from synthetic clears, row/column/3x3 detonation, chains, Color Bomb non-matching and legal swaps, all six swap combos, Bomb+Striped conversion, combos skipping 4+/5+ Jokers, special Mult (+4/+6/+10) and combo multipliers (x3, x6), save round-trip with older four-field rows, bomb/wrapped tiles and the live resolver announcing a new Striped candy. Art generated with Aseprite (`tools/create_special_art.lua`) and inspected on a contact sheet and the rendered board.

Removing the free 4/5 blasts changed fixtures: ThreeRunner, RarityRunner (Match 4 = 180) and EffectsRunner (overlap now made by a Striped candy) were updated; TouchRunner now plays in round 16 so its swaps do not clear the lower ante 1 quota. All 23 suites pass (749 checks). ShakerRunner failed once while sharing CPU with other runs and passed 3/3 alone; it uses real animation timing.

Balance (greedy bot, 12 trials): no Jokers ~2.5k per 10 moves (ante 1 quotas lowered to 1,200 / 2,000 / 3,000); Striper alone ~6k; three special Jokers ~11k; five special-synergy Jokers ~30k. The bot never sets up combos deliberately, so these understate specials. Kaleidoscope/Mobius/Labyrinth builds lost the most from removing free blasts (4-Joker Geometry ~55k, was ~370k); the 4+/5+ pile (~318k) is now the strongest measured build.


## Interest and skip Tags (v0.20, 2026-11-12)

New TagRunner (39 checks): interest ($1 per $5 before payout, $5 cap, shown in the summary), deterministic per-seed Tags with all six reachable, Small/Big-only skipping from the shop and from an untouched opening round, no skip after a move, closed shop refusing Joker/consumable/recipe/candy purchases and rerolls, the following round reopening a normal shop, every Tag effect (Piggy cap, Handout free offer bought with $0 and selling for $0, Cookbook two distinct non-Diagonal levels, Sweets item or $4, two free rerolls without raising the price, Extra Moves for one round and carried over when that round is skipped), save/Continue of all Tag state, and the physical route flow: new-run Tag preview from the seed box, Skip on Small then Big, no Skip on the Boss, closed shop UI, then Boss play. Visually inspected the route with Tags and the closed shop.

SynergyRunner's income bound now allows interest on top of the $186 score-independent round income. All 24 suites pass (788 checks). ShakerRunner failed twice while sharing CPU with other runs and passed every time alone (real animation timing).

Not simulated: the balance bot does not model shopping, so the extra cash from interest and the Skip/Tag trade-off are untested against the quota curve. Expect players to afford Jokers and recipe levels a little earlier than before.


## Joker editions, order and scaling Jokers (v0.21, 2026-11-12)

New EditionRunner (27 checks): edition roll rates over 20,000 seeded rolls (8% / 5% / 3% within 1 point) and determinism, Foil/Holo/Polychrome scoring, left-to-right order (Addict before Labyrinth vs after; editions following their Joker), bounded moves, edition removal on sale, Sugar Cube / Candy Cane / Gumball Jar growth and their ordered scoring, live growth text, edition prices and overlays on shop and owned cards, buying keeps the edition, sell value includes it, physical < Move / Move > reordering with bound states, reordering only in the shop, save/Continue of order + editions + growth, and new-run reset. Art from `tools/create_edition_art.lua` was inspected on a contact sheet and in the rendered shop.

ShopRunner now names any Joker whose description overflows; it caught the shop showing Roulette's live (three-line) text, so the shop detail panel keeps base descriptions while tooltips and the in-round popup show live details. All 25 suites pass (821 checks).

Balance: with Addict placed before Labyrinth, the Kaleidoscope/Mobius/Addict/Labyrinth build rises from ~55k to ~97k per 10 moves (five-Joker version ~152k). Editions are shop-only, so the bot does not measure them.


## Bosses and obstacles (v0.22, 2026-11-12)

New BossRunner (50 checks): nine-boss pool, six distinct seeded draws per run with all nine reachable across 60 seeds, chocolate placement/blocking/breaking/bonus/gravity anchoring and spreading only after moves that break none, two-layer frosting losing one layer per hit, Sour Patch zero Candys, Tiny Spoon half Mult, Jelly Mould checkerboard with half score when no jelly is cleared, Rush Hour moves, Sugar Tax never going below $0, HUD rule text and bounds plus route icon and a playable starting board for every boss, the route preview naming the drawn boss, and save/Continue of obstacles, jelly and the sour type (older five-field rows load without obstacles). RouteRunner now uses a seeded run and checks that the previewed bosses are the ones played and never repeat. Art from `tools/create_boss_art.lua` was inspected in rendered boss boards (Frost, Jelly, Chocolatier, Sour); the jelly frame was brightened after review, and the tile marks were renamed `ui_mark_*` after the first export collided with the boss icon names.

All 26 suites pass (873 checks).

Balance (bot with a three-Joker Pop Rock/Sweet Tooth/Three Scoops build, 10 trials, median per 10 moves; no boss = 36k): Inspector 42k, Sugar Tax 36k (costs cash only), Heatwave 32k, Rush Hour 29k (it removes moves), Sour 28k, Chocolatier 26k, Frost 22k after trimming it from 12 to 8 frosted cells (was 14k), Jelly 20k, Tiny Spoon 18k. Boss rounds keep 12 moves, which offsets part of the halving bosses.


## Booster packs (v0.23, 2026-11-12)

New PackRunner (37 checks): pack odds over 5,000 seeded rolls (Joker ~30%, Sugar Rush ~10%, never Jumbo), determinism and prices, two packs per shop that survive rerolls, opening (pay, slot used), every pack kind (Recipe including Diagonal only with Kaleidoscope, Jumbo two picks, Candy, Joker with editions, Treat), blocked takes with full Joker slots or items, skipping, all five rare cards (Glitter, Cookbook Blast, Big Spoon with the 6-slot cap, Meltdown, Golden Batch halving interest) and hiding cards that could not work, the Pack Tag's free Jumbo, the physical Packs tab and pack modal (Take, closing on the last pick, Skip), and save/Continue of an open pack, Joker slots, Golden Batch and pending Pack Tags, plus new-run reset. RecipeRunner now checks the view-only Recipes tab; TagRunner checks that a skipped shop has no packs.

All 27 suites pass (907 checks). Visually inspected the Packs tab and the pack modal (cards centered and shop text shortened after review). Not visually inspected: the Joker bar with a sixth slot from Big Spoon. Pack prices and odds are untested against the quota curve because the balance bot does not shop.


## Candy-shop art and UI (v0.24, 2026-11-12)

Generated with Aseprite by `tools/create_v2_art.lua` (previous PNGs backed up before overwriting) and reviewed on contact sheets and rendered screens: title, gameplay, shop with editions, route preview, Frost boss board and the pack modal. Review changes: softened the drifting backdrop stripes. A light-looking Reroll label was confirmed dark at full zoom (CRT fringing). Root cause of the all-red buttons: `UIStyle.box()` mapped most colours, including purple, to the red skin; buttons now use explicit role skins via `UIStyle.role()`.

All 27 suites pass (907 checks), including ResizeRunner's 496 cell hitboxes and RouteRunner's art-source checks (the Background node keeps no material; the drifting layer is a separate Aseprite tile). Removal, fall and popup animations keep their previous wait durations so input locking is unchanged; the idle sparkle is the only user of the global random generator. Not verified: real-time feel of the new animations at full frame rate and the drifting backdrop in motion (screenshots are still frames).


## Balatro-style HD art (v0.25, 2026-11-12)

Generated with `tools/create_hd_art.lua` and reviewed on contact sheets and rendered screens (gameplay, shop with editions, route preview). Review fixes: candies first rendered black (colour ramp returned hex strings, not colours); then washed out (lighting mapped most pixels to the lightest tones; contrast curve added); cards rendered dark because the tilt shader multiplied by `COLOR`, which in Godot 4 already contains the texture (now multiplies by the vertex tint only).

All 27 suites pass (907 checks) apart from ShakerRunner's known timing-sensitive pair of checks, which failed once in the full sequential run and then passed 3/3 alone and on 10 fixed seeds. ShakerRunner now uses a fixed seed (override with `SUGAR_TEST_SEED`); the remaining flake comes from real-time animation waits in its motion-enabled section. RouteRunner now checks that the painted table stays shader-free and that the swirl is its own shader layer. Not verified: the swirl and card tilt in motion and on web/mobile GPUs (still screenshots only).


## Native HD Joker cards (v0.26, 2026-11-12)

All 32 cards reviewed on contact sheets and in the Collection, shop, Joker bar and title screen. Review fixes: the Cube card's background filled with outline ink (its shape returned a small "outside" distance everywhere; replaced with a hexagon distance and face edges), and the Bomb was enlarged with chunkier sprinkles. Collection (78) and shop (30) suites pass with the new art; full results below the commit.
All 27 suites pass (907 checks).
