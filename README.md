# Sugar Rush

A playable, local Godot 4 game: tactical match-3, a Candys × Mult scoring engine, 26 rule-changing Jokers, and eighteen batches across six antes. Original pixel art is supplied as layered Aseprite sources.

## Resize and art revision

The game now uses one protected 1152 × 720 logical canvas. The physical window can be resized freely; nonmatching aspect ratios receive letterboxing. Candy hitboxes are computed by the board in the same logical space, and input stays locked until all movement finishes.

The art direction now uses original cream-stock Joker cards, new 24-pixel candy silhouettes displayed at exactly 2×, an Aseprite-painted green felt background, Chakra Petch SemiBold interface lettering and original pixel card titles, beveled controls, and blue Candys/red Mult counters. All artwork remains editable in Aseprite. Typography licensing is in `assets/fonts/`.

## Collection

Choose **Collection** on the title menu to browse all 26 Jokers. Select a card to see its artwork, effect, category and shop price. Previous/Next switches pages; Back to Menu or Esc closes it. All cards are visible immediately. Browsing does not change a run or spend cash.

## Play

On this computer, double-click **Play.cmd**. Start Run opens the ante map; confirm the highlighted batch to begin. Leaving the shop previews the next batch, including the upcoming boss rule, before you commit. To edit, double-click **Open Editor.cmd**, or import **project.godot** into Godot and press **F5**. No scene wiring, plugins, or paid asset packs are required. Tested with the installed Godot **4.7.2**.

- Drag a candy onto a neighbour to swap (mouse or finger), or tap one candy and then a neighbour. Invalid swaps spend a move. Phones and tablets work through the web build.
- Arrows + Enter also work. **H** buys a hint ($1 initially, rising by $1 per purchase for the run); **Esc** pauses.
- Reach the quota, then spend your round cash reward in the shop. Score does not convert to cash. The CASH counter shows your spendable balance in dollars. The finished-round scoreboard is hidden while shopping. All four offers, prices, Reroll, and Next Round stay visible. Select a shop card to reveal its effect, or an owned Joker to sell it; the detail panel shows the resulting balance before a transaction.
- The handbook explains every Joker, board mark, and boss rule.
- Pause works during moves and in the shop. It includes Resume, Options (sound and reduced motion), Quit to Title, and Quit to Desktop. Options persist locally.
- Enter a numeric seed on the title screen to reproduce board generation and shop draws for the same actions.

## Builds and cash

All different Jokers can be combined within five slots. Every equipped 4+ effect fires on a match of four or more; a match of five or more also fires every equipped 5+ effect. Repainting happens before attraction, so those two directly feed one another. Overlapping clears count each candy once.

Start with $4. Small, Big, and Boss batches pay $5, $7, and $10. Each three unused moves adds $1, capped at $3. Joker prices are $1–$13. Rerolls cost $3, then $5, $7, etc., resetting each shop. Sales refund half price rounded down. A huge score cannot increase the cash reward.

## Candy rarity and tile breaking

| Candy | Candys | Base spawn chance |
| --- | ---: | ---: |
| Berry Bonbon | 10 | 30% |
| Lemon Drop | 14 | 24% |
| Mint Gummy | 20 | 18% |
| Blue Peppermint | 30 | 13% |
| Plum Jellybean | 45 | 9% |
| Caramel Square | 70 | 6% |

The **Candy Guide** shows current odds, including equipped Supply Jokers. Each of the six Supply Jokers doubles its candy's weight; all weights are normalized together. These are per-draw probabilities, not a fixed board composition.

Match three candies in a line that includes the candy inside a blocked or Inspector-locked tile to break it. Framed tiles remain fixed, so move matching candies into line around them. Inspector candies can be swapped but remain anchored during falls. Matching beside a locked tile also still breaks it. Receive its candy value plus **10 / 25 / 50 Candys** for matches of **3 / 4 / 5+**, before Mult. Specials can also break tiles. Open blocker frames keep the underlying candy visible. Breaking does not spread through a chain of adjacent locked tiles.

## Included

- The original 16 Jokers, six Supply Jokers and four exact-three Jokers, with resource definitions, unique Aseprite cards, and executable effects.
- Diagonal and wrapping matches; Labyrinth minimum-length rules; merged L/T shapes.
- Stacking 4+ and 5+ match effects in any combination; five total Joker slots; purchase, sale, and reroll economy.
- Inspector color locks and Heatwave aging; blocker destruction, revival, coated candy, Wild Prisms, and persistent isotope squares.
- Swapping and gravity tweens, attraction animation, screen shake, particles, floating scores, candy audio, and animated title cards.
- Dedicated editable scenes, typed gameplay classes, deterministic board RNG, hints, dead-board recovery, and a complete title → rounds → shops → victory/defeat loop.
- Layered `.aseprite` documents for every visual texture, their PNG exports, and regeneration/export scripts.
- Automated model and real-scene integration tests, including 100 seeded geometry boards.

## Editing

See [the visual asset inventory](docs/ASSETS.md) for the Aseprite source of every image and the export workflow. See [the editor and Aseprite guide](docs/EDITING.md) for scene responsibilities, inspector tuning, asset export, and instructions for adding content. See [design decisions](docs/DESIGN.md) for precise scoring and edge-case rules, and [verification](docs/VERIFICATION.md) for checks performed.

This is a complete first playable implementation of the supplied brief. Balance and difficulty are initial tuning values, not the result of a player study. Active runs are session-only; only sound/motion preferences persist. Windows release binaries are not included; the project and local launcher use your installed Godot editor.

The title screen and game window show **Sugar Rush | v0.7 — Joker Collection**. An already-open older game must be closed or replaced by this new window to load the corrected scripts.

### Exact-three builds

Four new Jokers trigger on a connected match of exactly three candies, including cascades, diagonal matches and wrapped matches. They all stack within the usual five slots:

- **Pop Rock ($9):** clears a 3x3 area centered on the middle candy; board edges clip the blast. Destroyed locks award their normal breaking bonus.
- **Sweet Tooth ($7):** clears up to two additional candies of the matched color, choosing the nearest remaining candidates after the blast.
- **Golden Trio ($11):** coats the three matched candies in gold before scoring, making each worth 80 Candys.
- **Three Scoops ($5):** adds 30 Candys before Mult.

Gold applies before destruction. Each cleared candy scores once, even where effects overlap. These effects do not fire on larger matches, merged L/T shapes or synthetic wild-swap clears. Labyrinth still requires matches of four or more, so it prevents exact-three triggers. Cash rewards remain independent of score.

### Extended campaign

The run has six antes (18 rounds). Quotas grow about 2.2x per ante (rebalanced 2026-11-11 from bot simulations: no-Joker play clears ante 1 only; ante 6 needs a five-Joker engine). Cash rewards still use the same fixed payouts.

| Ante | Small / Big / Boss targets | Small / Big / Boss moves | Boss |
| --- | --- | --- | --- |
| 1 | 1,200 / 2,000 / 3,000 | 10 / 10 / 12 | Drawn per run |
| 2 | 6,000 / 9,000 / 13,000 | 10 / 10 / 12 | Drawn per run |
| 3 | 18,000 / 25,000 / 33,000 | 10 / 10 / 12 | Drawn per run |
| 4 | 40,000 / 55,000 / 70,000 | 9 / 9 / 11 | Drawn per run |
| 5 | 90,000 / 120,000 / 160,000 | 8 / 8 / 10 | Drawn per run |
| 6 | 200,000 / 260,000 / 350,000 | 7 / 7 / 9 | Drawn per run |

Victory follows the sixth boss. Shops remain available between rounds, including after the first five bosses.

### Candy upgrades (this run only)

Since v0.28, candy upgrades come only from **Candy Packs** on the Packs tab. The shop's **Candies** tab lists every type with its level and current > next value, but has no buy buttons.

Each Candy Pack card adds half that type's original value, rounded up: +5 / +7 / +10 / +15 / +23 / +35 Candys, with no level cap. Bonuses also add to gold and caramel coating values and apply to locked candies when broken, before Mult. Upgrades do not change spawn odds.

Values persist through shops, rerolls and rounds, then reset with a new run. The Candy Guide and board hover text show the current values. No permanent resource data or preferences are changed.

Roulette Licorice marks all candies of its chosen type with a small roulette wheel. Hover the owned Joker to see this round's type and whether its penalty has been avoided. The sidebar repeats the target and status. Markers remain after matching because x2 Mult stays active for the round.

### CRT and audio options

Pause → Options includes a Heavy CRT toggle and a 0–100% volume slider. The CRT treatment is enabled by default, with scanlines, RGB phosphor mask, color fringing, glow and vignette; it preserves input geometry. Motion, sound, CRT and volume save immediately to `user://preferences.cfg` and reload at startup. Existing settings files retain their previous choices; CRT defaults on and volume defaults to 80%. Pop sounds vary by ±10% pitch around the cascade pitch, using an independent random generator so seeded gameplay remains reproducible.

### Sugar Shaker consumable

Buy a Sugar Shaker for $4 in the shop and carry up to two, separately from Joker slots. The in-round **Items** button opens your inventory; using Sugar Shaker consumes one to rearrange unlocked candies, spending no move and changing neither score nor streak. It preserves all candy objects, coatings, ages, upgrades and fixed locks; the new arrangement has no immediate matches and at least one legal move. Requests during a move queue once; if that move finishes the round, the item is kept. If no safe rearrangement can be found, nothing is consumed. Unused items carry across rounds and shops, and new runs start empty.


### Sweet consumables (v0.15)

The shop's **Consumables** browser offers four cards with prices, effects, held count, and your current cash. Any combination of two cards can be held, including duplicates, independently of Joker slots. Cards carry between rounds and reset on a new run. A held card can be discarded in the shop without a refund.

- **Sugar Shaker � $4:** rearrange unlocked candies, preserving locks and coatings.
- **Extra Serving � $6:** add two moves to the current round.
- **Golden Glaze � $7:** select a candy to gild every candy of its type currently on the board, except Wilds. Gold is worth 80 Candys plus that type's run upgrades.
- **Candy Hammer � $5:** select one candy to smash for its value, plus 10 if locked. The direct hit does not trigger match Jokers or count as a Roulette match; refill cascades resolve normally.

Open **Items** during a round and choose Use. Glaze and Hammer then let you click a board candy; Esc or Cancel target keeps the card. All cards cost no moves. A Glaze that would change nothing is kept. Busy-board requests wait for resolution, and are kept if the round ends first.


### Shop stock and saved runs (v0.16)

Each shop stocks two random, distinct consumable cards. Each offer can be bought once, even if you discard the purchased card. The shared paid **Refresh shop** action replaces both Joker offers and consumable offers; its price increases as before. Your two-item inventory limit still applies. New shops restock automatically.

Runs autosave after completed actions and shop transactions to `user://run_save.cfg`. **Continue** on the title screen restores your board, current round, cash, score, moves, Jokers, upgrades, inventory, shop stock and random sequences. Quit to Title also preserves the run. Normal desktop/window quitting finishes any active resolution before saving; an abrupt termination restores the last completed checkpoint. Winning or losing clears the saved run. **New Run** replaces it when you confirm the first batch; backing out of the preview keeps the old save. Settings remain separate.

Saves use a versioned, validated ConfigFile with temporary-file replacement. Automated tests use separate save files and never overwrite the player's run.


## Windows and web exports (v0.17)

Run **Export Builds.cmd** with `GODOT_EXE` set, or use `tools/export.ps1 -GodotExe "C:/path/to/Godot.exe"`. Portable Windows and upload-ready web ZIPs are generated in `builds/`. Both support mouse and touch; owned Jokers can be tapped for details. See [export and testing instructions](docs/EXPORTING.md) for hosting, local saves and device coverage.


### Recipes (v0.18)

Every scored match is a **recipe**, Sugar Rush's version of a poker hand. Its Candys are added before Mult and its Mult is the starting multiplier:

| Recipe | Match | Level 1 | Per level |
| --- | --- | --- | --- |
| Trio | Line of 3 | 0 x1 | +10 Candys, +1 Mult |
| Quad | Line of 4 | 10 x2 | +15, +1 |
| Quint | Line of 5+ (+1 Mult per extra candy) | 30 x3 | +20, +2 |
| L / T Shape | Two lines joined | 20 x3 | +20, +2 |
| Diagonal | Diagonal line (Kaleidoscope) | 10 x2 | +15, +1 |

Since v0.23, level recipes with Recipe Packs (Packs tab), the Cookbook Tag or the Cookbook Blast rare card; the Recipes tab shows your levels. Levels last for the run and are saved with it. The in-round sidebar lists your recipe levels and marks the last recipe scored; score popups name the recipe.


### Special candies (v0.19)

Matches of 4 and 5 no longer blast for free. Special candies come from three Special Jokers:

- **Ribbon Striper ($6):** a line of 4 (or 5 without Bomb Maker) leaves a **Striped** candy where you swapped. Matched or blasted, it clears its row or column.
- **Candy Wrapper ($7):** an L/T match leaves a **Wrapped** candy that blasts a 3x3 area.
- **Bomb Maker ($9):** a line of 5 leaves a **Color Bomb**. Swap it with any candy to clear that type.

Each special that fires adds Mult to its match: Striped +4, Wrapped +6, Color Bomb +10. Specials chain: a blast that hits another special fires it too. Swapping two specials is always legal and makes a combo: Striped+Striped clears a cross, Striped+Wrapped three rows and three columns, Wrapped+Wrapped a 5x5 area, Color Bomb+Striped/Wrapped turns that type into the special and fires them all, and two Color Bombs clear the board. Combos score as a Quint recipe with x3 Mult (x6 for two Color Bombs) and do not trigger 4+/5+ Jokers. Specials are saved with the run.


### Interest and skip Tags (v0.20)

**Interest:** when you clear a round you earn $1 for every $5 you were holding (before the payout), up to $5. The shop receipt shows it.

**Skipping:** the route preview shows a Tag on every Small and Big batch. Press **Skip** to give up that batch's cash and its shop and claim the Tag instead; Bosses cannot be skipped. A new run can skip its opening batch too. Tags are fixed by the run seed.

| Tag | Effect |
| --- | --- |
| Piggy | Double your cash (max +$15) |
| Handout | One Joker in the next shop is free until you reroll (it sells for $0) |
| Cookbook | +1 level to two random recipes (not Diagonal) |
| Reroll | Your next two rerolls are free |
| Sweets | A random consumable, or $4 if your items are full |
| Extra Moves | +3 moves in your next round (kept if that round is skipped) |

After a skip the shop is closed; press Next to pick your next batch. Tag effects and interest are saved with the run.


### Joker editions, order and scaling Jokers (v0.21)

**Order matters.** Jokers add their score bonuses from left to right, so a +Mult Joker placed before a xMult Joker gets multiplied. In the shop, select an owned Joker and use **< Move / Move >** to rearrange them.

**Editions.** Each shop Joker can roll an edition, shown as an overlay on the card. It applies to every match you score, in that Joker's position:

| Edition | Effect | Extra price | Chance |
| --- | --- | --- | --- |
| Foil | +50 Candys | +$2 | 8% |
| Holographic | +4 Mult | +$3 | 5% |
| Polychrome | x1.5 Mult | +$5 | 3% |

Selling refunds half of the full price, including the edition.

**Scaling Jokers** grow for the rest of the run. Their current bonus is shown on the card and in the shop:

- **Sugar Cube ($7):** +1 Mult for every Quint or L/T Shape you score.
- **Gumball Jar ($6):** +8 Candys for every round you clear.
- **Candy Cane ($8):** x0.1 Mult for every special candy fired (starts at x1).

Selling a scaling Joker loses its growth. Order, editions and growth are saved with the run.


### Bosses and obstacles (v0.22)

Each run draws one boss per ante from nine, never repeating, fixed by the run seed. The route preview shows the upcoming boss with its icon and rule; the sidebar shows the live rule during the round.

| Boss | Rule |
| --- | --- |
| The Inspector | One candy type stays put in falls. Match 3 with it to break it. |
| The Heatwave | Candies untouched for 4 moves become sticky blockers. |
| The Chocolatier | Chocolate tiles spread onto a neighbor after any move that breaks none. |
| The Frost | Two-layer frosting blocks the middle; each nearby match or blast removes a layer. |
| The Sour Patch | One candy type is sour and scores 0 Candys. |
| The Tiny Spoon | All Mult is halved. |
| The Jelly Mould | Half the cells are jelly; a match that clears no jelly scores half. |
| The Sugar Tax | Every move costs $1 while you have cash. |
| The Rush Hour | 3 fewer moves. |

Chocolate and frosting fill a cell: they cannot be swapped or matched, anchor gravity, and break from adjacent matches or any blast (specials, line clears, Pop Rock, Nuclear) for the usual breaking bonus. Color Bombs and Joker attraction/gilding ignore them. Jelly stays on its cell while candies fall over it. Obstacles, jelly and the sour type are saved with the run.


### Booster packs (v0.23)

The shop's **Packs** tab sells two packs per shop; rerolls do not replace them. Opening a pack shows its cards; keep the number shown or skip the rest. Jumbo packs show more cards.

| Pack | Price (Jumbo) | Cards (Jumbo) | Keep (Jumbo) | Odds |
| --- | --- | --- | --- | --- |
| Joker | $4 ($6) | 2 (4), editions can roll | 1 (1) | 28% |
| Recipe | $4 ($6) | 3 (5) recipes, +1 level | 1 (2) | 27% |
| Candy | $3 ($5) | 3 (5) candy types, +1 upgrade (the only source of candy upgrades) | 1 (2) | 25% |
| Treat | $4 ($6) | 3 (4) consumables | 1 (1) | 10% |
| Sugar Rush | $6 | 2 rare cards | 1 | 10% |

A quarter of packs are Jumbo (never Sugar Rush). Rare cards: **Glitter** (random owned Joker gets an edition), **Cookbook Blast** (+1 level to every recipe), **Big Spoon** (+1 Joker slot up to 6, lose $10), **Meltdown** (destroy a random Joker, another turns Polychrome), **Golden Batch** (+$20, interest cap halved for the run). Cards that could not work are not offered.

**Recipe levels now come from packs.** The Recipes tab shows your levels but no longer sells them; level recipes with Recipe Packs, the Cookbook Tag and Cookbook Blast. A new **Pack Tag** skip reward makes the next shop's first pack a free Jumbo. Packs, an open pack, extra Joker slots and Golden Batch are saved with the run.


### Candy-shop art and UI (v0.24)

- **Palette:** berry-chocolate backdrop with a slowly drifting stripe-and-sprinkle layer, plum panels with pink edges, and mid-plum board tiles so candies stand out.
- **Candies:** the six candies and the Color Bomb are redrawn with outlines, four-tone shading, a white glint and a soft drop shadow (same shapes, still 24 x 24 at 2x).
- **Colour-coded buttons:** green = go/play/next, blue = info (guide, run info, items, collection), gold = buy/open/reroll, purple = skip/hint, red = quit, plum = neutral (back, pause, tabs). Code uses `UIStyle.role(button, "go")` etc.
- **Juice:** outlined score popups with a punch, cleared candies swell with a flash before popping, falling candies land with a small bounce, the board flashes on special effects, and resting candies sparkle now and then. All motion respects the Reduced motion option; the sparkle uses its own randomness and never affects seeded gameplay.


### Less text, Balatro style (v0.29)

Persistent screens show numbers and short labels only; rules appear on hover, in short trigger-and-effect form, with Balatro-style keyword colours: Mult red, Candys blue, money gold (write numbers as "+4 Mult", "X1.5 Mult", "+30 Candys", "$10"; `UIStyle.rich()` colours them). Removed: the board's controls reminder, the normal-round quota sentence and round-start pop-up, the shop tabs' explainer boxes, the route's how-to-play footer and filler, and the second title tagline. Full rules stay in Run info.

### Music and reactive sounds (v0.31)

Three looping tracks crossfade by context: a laid-back jazzy track on the title screen and in the shop, an upbeat track during normal rounds and a driving minor-key track on boss rounds. Music ducks while paused and has its own **Music** toggle in Options (sound effects keep theirs). Sound effects react to play: swaps, failed swaps, big matches (4+), new special candies, specials firing, special combos, cracked obstacles, chocolate spreading, a rising tick while the score counts up, card hovers, every button press, coins on buying, selling, rerolling, pack opening and taking a card, using items, boss reveals, round wins, skips, victory and defeat. All audio is synthesised by `tools/generate_audio.gd` (no third-party files); `autoload/sound_board.gd` plays it.

### Joker rarity and the new title screen (v0.33)

Every Joker has a rarity. Each shop or Joker-pack roll first picks a tier, then a Joker within it: **Common 62%**, **Uncommon 27%**, **Rare 9%**, **Legendary 2%**. Rarity shows as a coloured pill (blue, green, red, purple) in the shop details, tooltips, pack cards, owned-Joker details and the Collection. Tiers come from measured solo power (`tools/balance_sim.gd -- --test solo=1`) plus judgement for scaling and 5-match Jokers:

- **Legendary:** Paintball Splatter (~94x a Jokerless round), Kaleidoscope Prism (~7.7x), Sugar Addict (~4.3x)
- **Rare:** Pop Rock, Sweet Tooth, Labyrinth Wire, Ribbon Striper, Golden Trio, Midas Touch, Nuclear Core
- **Uncommon:** Ricochet Pop, Candy Wrapper, Mobius Strip, Gravity Well, Ouroboros Worm, Prism Shard, Candy Cane, Sugar Cube, Bomb Maker, Necromancer's Skull, T-Square
- **Common:** Three Scoops, Gumball Jar, Roulette Licorice, Broken Scale, Sledgehammer Mint and the six candy Supply Jokers

Legendaries now cost $14-15 and Rares $9-13.

The title screen no longer sits in a panel. The SUGAR RUSH logo waves and shimmers (tap a letter to make it jump and play a note), candies drift down behind everything (tap to pop them; quick pops build a streak), six Joker cards fan out on both sides (hover to tilt, tap to flip to a new Joker rolled with the shop's rarity odds and see its rarity), and the buttons cascade in and swell on hover. The scene leans gently away from the pointer. Reduced motion turns the animation off.

### One move = one hand, move preview, one-row shop and Jelly Mould (v0.34)

**Scoring.** Each move now scores once, like a Balatro hand. Your own match (the first wave) is the hand: its best group sets the recipe, every extra group in that first wave adds +1 Mult, and specials it fires add their Mult. Cascades feed the same hand: their candies add Candys and each wave adds +0.5 Mult (up to +2); specials fired by cascades add their cleared Candys, not Mult (v0.35). Jokers, editions and boss rules then apply **once** to the final Candys x Mult. The HUD counts the hand up live while the board cascades; the score lands when the board settles.

**Preview.** Before you commit, the HUD shows exactly what your own match will score ("TRIO LV1 = 145+") and outlines the candies it clears. The "+" means cascades can only add to that number, never take away. Mouse: select a candy, hover a neighbour, click to confirm. Touch: drag toward a neighbour to preview, release to swap, slide back to cancel. Keyboard: select, then arrow next to it. An invalid swap previews "NO MATCH -1 MOVE".

**Paintball Splatter** keeps its chain reactions but now splatters on your match and at most 3 cascade waves after it.

**Shop.** One row, Balatro-style: two Jokers and two booster packs, each with its own Buy/Open button. Reroll replaces the Jokers; packs stay until opened. Recipe and candy levels moved to the **Levels** pop-up.

**The Jelly Mould** no longer halves scores. Instead, 24 jelly tiles cover the board (every other tile, skipping the top and bottom rows) and you must clear **all** of them and reach the score to win; reaching the score early does not end the round while jelly remains.

### Full-run tuning (v0.35)

`tools/run_sim.gd` (scene `tools/RunSim.tscn`) plays complete runs with the real GameManager: shop rolls, rarity odds, prices, packs, editions, interest, rewards, bosses and the Jelly objective. The bot plays the best previewed move and shops sensibly, but never skips for Tags or uses items, so its win rate is a floor for a careful player.

```
Godot --headless --audio-driver Dummy --path . res://tools/RunSim.tscn -- --test runs=20 seed=1000
```

Tuned from 3 x 60 simulated runs:
- **Quotas:** 1.2k / 1.8k / 2.4k, 4k / 6k / 8k, 13k / 19k / 26k, 36k / 54k / 72k, 100k / 150k / 200k, 250k / 375k / 500k.
- **Jelly Mould** lays 12 / 15 / 18 / 20 / 22 / 24 jelly tiles by ante, centre first.
- **Mult comes from your own match.** Cascade specials add Candys only, which stopped special-chain builds multiplying a growing Candys pile by a growing Mult pile (the worst late move fell from 420x to 27x the quota).

Result: the bot wins about 20% of runs. 95% reach ante 2, 78% ante 4, 63% ante 5, 40% ante 6 and 27% the final boss; most late rounds finish at about 1.2x the quota, and only rare Legendary + Polychrome builds overshoot by 10x or more.
