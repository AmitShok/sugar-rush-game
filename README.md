# Sugar Rush — v0.7

A playable, local Godot 4 game: tactical match-3, a Candys × Mult scoring engine, 26 rule-changing Jokers, and eighteen batches across six antes. Original pixel art is supplied as layered Aseprite sources.

## Resize and art revision

The game now uses one protected 1152 × 720 logical canvas. The physical window can be resized freely; nonmatching aspect ratios receive letterboxing. Candy hitboxes are computed by the board in the same logical space, and input stays locked until all movement finishes.

The art direction now uses original cream-stock Joker cards, new 24-pixel candy silhouettes displayed at exactly 2×, an Aseprite-painted green felt background, m6x11 pixel lettering by Daniel Linssen, beveled controls, and blue Candys/red Mult counters. All artwork remains editable in Aseprite. Typography licensing is in `assets/fonts/`.

## Collection

Choose **Collection** on the title menu to browse all 26 Jokers. Select a card to see its artwork, effect, category and shop price. Previous/Next switches pages; Back to Menu or Esc closes it. All cards are visible immediately. Browsing does not change a run or spend cash.

## Play

On this computer, double-click **Play.cmd**. Start Run opens the ante map; confirm the highlighted batch to begin. Leaving the shop previews the next batch, including the upcoming boss rule, before you commit. To edit, double-click **Open Editor.cmd**, or import **project.godot** into Godot and press **F5**. No scene wiring, plugins, or paid asset packs are required. Tested with the installed Godot **4.7.2**.

- Click two neighboring candies to swap. Invalid swaps spend a move.
- Arrows + Enter also work. **H** shows a free hint; **Esc** pauses.
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

The run now has six antes (18 rounds). Antes 1–3 retain their original targets and moves. Later antes require stronger Joker combinations; cash rewards still use the same fixed payouts.

| Ante | Small / Big / Boss targets | Small / Big / Boss moves | Boss |
| --- | --- | --- | --- |
| 4 | 12,000 / 16,000 / 21,000 | 9 / 9 / 11 | Heatwave |
| 5 | 28,000 / 37,000 / 48,000 | 8 / 8 / 10 | Inspector |
| 6 | 62,000 / 80,000 / 105,000 | 7 / 7 / 9 | Heatwave |

Victory follows the sixth boss. Shops remain available between rounds, including after the first five bosses.

### Candy upgrades (this run only)

In the shop, switch from **Jokers** to **Candy Upgrades**. All six types are always available. Each row shows the current value, next value and buy price; hovering shows its level and the cash remaining after purchase. A purchase receipt confirms the new level. Your cash stays visible in the sidebar.

Upgrades have no slot or purchase-count limit. Each purchase adds half that type's original value, rounded up: +5 / +7 / +10 / +15 / +23 / +35 Candys. Prices start at $4 per type and rise by $2 for each purchase of that type. Different types have independent prices. Bonuses also add to gold and caramel coating values and apply to locked candies when broken, before Mult. Upgrades do not change spawn odds.

Values persist through shops, rerolls and rounds, then reset with a new run. The Candy Guide and board hover text show the current values. No permanent resource data or preferences are changed.

Roulette Licorice marks all candies of its chosen type with a small roulette wheel. Hover the owned Joker to see this round's type and whether its penalty has been avoided. The sidebar repeats the target and status. Markers remain after matching because x2 Mult stays active for the round.

### CRT and audio options

Pause → Options includes a Heavy CRT toggle and a 0–100% volume slider. The CRT treatment is enabled by default, with scanlines, RGB phosphor mask, color fringing, glow and vignette; it preserves input geometry. Motion, sound, CRT and volume save immediately to `user://preferences.cfg` and reload at startup. Existing settings files retain their previous choices; CRT defaults on and volume defaults to 80%. Pop sounds vary by ±10% pitch around the cascade pitch, using an independent random generator so seeded gameplay remains reproducible.

### Sugar Shaker consumable

Buy a Sugar Shaker for $4 in the shop and carry up to two, separately from Joker slots. The in-round **Shake** button consumes one to rearrange unlocked candies, spending no move and changing neither score nor streak. It preserves all candy objects, coatings, ages, upgrades and fixed locks; the new arrangement has no immediate matches and at least one legal move. Requests during a move queue once; if that move finishes the round, the item is kept. If no safe rearrangement can be found, nothing is consumed. Unused items carry across rounds and shops, and new runs start empty.
