# Sugar Rush roadmap (agreed 2026-11-11)

Each step is re-balanced with `tools/balance_sim.gd` before moving on.

## Done: difficulty rebalance

- Bot simulation showed no-Joker play scoring ~10x the ante 1 quota and Geometry builds beating ante 6 every time.
- Cascade Mult bonus capped at +2 (`cascade_mult_step` / `cascade_mult_cap` in RunConfig).
- Sugar Addict +3 → +1 Mult per streak; Ouroboros xPopulation → x1 per 10 candies.
- Quotas now grow ~2.2x per ante: 1,200 (ante 1 Small) → 350,000 (ante 6 Boss).

## Done: 1. Recipe levels (Balatro hand types)

Trio, Quad, Quint, L/T Shape and Diagonal each add their own Candys + Mult (see README "Recipes").
Levelled through Recipe Packs, the Cookbook Tag and Cookbook Blast (v0.23). Live table in the in-round sidebar.

## Done: 2. Special candies as Jokers (Candy Crush specials)

Special candies only exist when you own the Joker that makes them, e.g.:
- Striper: match 4 leaves a Striped candy (clears its row/column when matched).
- Wrapper: L/T match leaves a Wrapped candy (3x3 blast; a second delayed blast could come later).
- Bomb Maker: match 5 leaves a Color Bomb (swap to clear a color).
- Swapping two specials together triggers a combo (cross, giant blast, board clear).
The free default 4/5 blasts are removed, so specials are earned through the build.

## Done: 3. Economy: interest + skip tags

- $1 interest per $5 held at round end, cap $5.
- Skip a Small/Big batch to claim a Tag: Piggy, Handout, Cookbook, Reroll, Sweets, Extra Moves (see README).

## Done: 4. Joker editions + scaling Jokers

- Foil (+Candys), Holo (+Mult), Polychrome (x1.5 Mult) editions.
- Joker order matters (left to right).
- Scaling Jokers that grow over the run.

## Done: 5. Bosses + obstacles

- 8-10 boss rules instead of two alternating.
- New obstacles for bosses: spreading chocolate, two-layer frosting and jelly. (Licorice locks already exist as framed blockers.)

## Done: 6. Booster packs

Joker, Recipe, Candy, Treat and rare Sugar Rush packs on a Packs tab; recipe levels now come from packs (see README).

## Done (first pass): 7. Polished pixel art and UI overhaul

Kept in Aseprite. Done last so the UI can fit the recipe table, tags, editions and packs.
- Bigger, glossier candies with highlights and idle animation; special-candy art.
- Candy-shop palette, color-coded buttons, clearer hierarchy, compact Joker bar.
- Juicier match/cascade effects and an animated background.
