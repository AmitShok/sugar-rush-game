# Sugar Rush — v0.7

A playable, local Godot 4 game: tactical match-3, a Candys × Mult scoring engine, 22 rule-changing Jokers, and nine batches across three antes. Original pixel art is supplied as layered Aseprite sources.

## Resize and art revision

The game now uses one protected 1152 × 720 logical canvas. The physical window can be resized freely; nonmatching aspect ratios receive letterboxing. Candy hitboxes are computed by the board in the same logical space, and input stays locked until all movement finishes.

The art direction now uses original cream-stock Joker cards, new 24-pixel candy silhouettes displayed at exactly 2×, an Aseprite-painted green felt background, m6x11 pixel lettering by Daniel Linssen, beveled controls, and blue Candys/red Mult counters. All artwork remains editable in Aseprite. Typography licensing is in `assets/fonts/`.

## Collection

Choose **Collection** on the title menu to browse all 22 Jokers. Select a card to see its artwork, effect, category and shop price. Previous/Next switches pages; Back to Menu or Esc closes it. All cards are visible immediately. Browsing does not change a run or spend cash.

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

- The original 16 Jokers plus six Supply Jokers, with resource definitions, unique Aseprite cards, and executable effects.
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
