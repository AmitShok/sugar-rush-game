# Rules and implementation decisions

The supplied brief leaves several timing and conflict cases open. These are the explicit rules used here.

## Matches and scores

Each connected match group produces an award. Candies within an overlapping L/T group are counted once. Separate groups in a cascade wave score separately, and a tile hit by multiple blasts contributes Candys only to its first award.

The normal group multiplier is `1 + max(0, effective line length - 3) + 0.5 × cascade index`. Diagonal groups receive Kaleidoscope's ×1.5 Candys factor. Labyrinth triples the multiplier. Addict's +3 per streak turn is then added. Isotope, poison, and final-move factors multiply afterward. The result is rounded to the nearest integer.

Thus an ordinary three-candy match starts at ×1, four at ×2, and five at ×3. The HUD shows the most recent group's operands. The running batch score accumulates every group and cascade.

Broken Scale swaps the two displayed operands. Multiplication is commutative, so the supplied `Candys × Mult` versus `Mult × Candys` specification has no numeric effect. The game and handbook say this explicitly; no unrelated bonus has been invented.

Wrapping applies to matching, not swapping. Only orthogonal neighboring cells can be swapped. Diagonal matches do not require diagonal swaps. L/T intersections are merged before Labyrinth validation, allowing T-Square to promote an intersecting shape to an effective five-match.

## Move and round timing

A failed adjacent swap returns the candies, spends one move, and resets Addict. A successful move adds one to the streak before its first award; cascades never increment the streak. Clicking a blocker or a nonadjacent selection does not spend a move.

Ouroboros applies when a move starts with exactly one move remaining. It uses the count of non-blocker candies at that moment, including locked-color candies, and applies to every cascade belonging to that final move.

After all cascades, Heatwave ages surviving candies. Swapped, newly spawned, and falling candies reset their age. Untouched candies become blockers when they reach the configured threshold. This makes board movement useful against the curse.

A round settles as soon as its adjusted score reaches the quota, or when moves run out. If Roulette's selected color was never matched, half the score is deducted before checking the quota. Clearing that color in an actual match group satisfies the requirement; merely hitting it as collateral does not.

Score never converts to cash. Start with $4; Small / Big / Boss batches pay $5 / $7 / $10. Add $1 per three unused moves, capped at $3. Across eighteen wins the maximum income is $186 plus starting cash, regardless of score. Every shop offers four distinct unequipped Jokers when available. Prices range from $1 to $13. Selling pays half the purchase price, rounded down. Rerolls cost $3, then $5, $7, etc. within that shop.

## Effects and board state

- A build has five slots and accepts any distinct Joker combination. All Four effects trigger at length 4 or greater; all Five effects also trigger at length 5 or greater. Geometry and Chaos stack with them. Duplicate copies of the same Joker remain disallowed.
- If no equipped effect triggers, four clears the matching row or column and five clears its color. A diagonal line blast uses its origin row. Triggered effects resolve in fixed order regardless of purchase order: Paintball, Gravity, Sledgehammer, Ricochet, Necromancer, Midas, Nuclear, Prism. Paintball feeds Gravity/Midas, and revived Gold can contribute to later blasts. Clear targets are deduplicated.
- Gravity chooses the four nearest same-color non-blocker candies to the group's origin, using grid distance. It removes them as scored collateral.
- Paintball repaints orthogonally adjacent, unremoved, non-blocker candies. Those colors feed attraction/gilding in the same group and subsequent cascades.
- Sledgehammer destroys the highest-strength blocker. With no blockers, it adds 30 Candys.
- Ricochet returns only additional non-blocker candies caught in the line blast, as caramel refill pieces. The original matched candies are consumed.
- Nuclear clears the origin's clipped 3 × 3 neighborhood and marks that grid position as an isotope. The creation match receives no isotope bonus from that newly created mark. Multiple isotope squares in a group give ×4 once, rather than exponential stacking.
- Midas gilds every currently present, non-blocker candy of the matched color, including the matched group.
- Prism leaves a wildcard at the group's origin before gravity. Swapping it collects up to three candies of each present color into simultaneous mini-matches; the wildcard and its swap partner are consumed. These mini-matches bypass Labyrinth and do not trigger 4+/5+ effects.
- Necromancer turns remaining blockers and all recorded destroyed-blocker positions into golden playable candies, then clears the grave list. Grave positions are board coordinates; revival replaces any refill candy occupying that position.
- Blockers and Inspector-locked colors anchor gravity. Specials can destroy both; both framed and Inspector-locked candies participate in ordinary matching. Frames prevent swapping; Inspector candies can be swapped but stay anchored during falls.
- When no legal move remains, the bowl reshuffles without spending a move. For a pathological nearly blocked board, recovery clears blockers and regenerates colors until a playable stable arrangement is found, with bounded attempts.
- Cascades are capped at 40 waves to prevent an infinite interaction. Reaching the cap settles the board and displays a message.

## Scope

Runs are local single-player sessions. A run is not saved across app exits. Sound/motion preferences are saved in Godot's user-data directory. No network services, account system, telemetry, paid assets, or external runtime dependencies are used.

## Rarity and breaking bonuses

Base candy values are 10, 14, 20, 30, 45 and 70 Candys. Their weights are 30, 24, 18, 13, 9 and 6. Each Supply Joker multiplies one weight by two; probabilities are normalized over the complete weighted pool. All random candy creation uses the same seeded sampler. Recycled caramel retains its original type instead of drawing another candy. Stabilizing starting boards conditions their composition to avoid automatic matches, so the guide explicitly describes per-draw odds.

After special-effect expansion, a match of at least three original cells also targets orthogonally adjacent blockers and Inspector-locked candies. No recursive propagation occurs. Each target contributes its candy value plus 10/25/50 Candys according to effective match length 3/4/5+. This enters the base Candys operand before Mult. Per-cell contributions, including bonuses, are deduplicated across the cascade wave. Destroyed blocker coordinates still feed Necromancer. Inspector's color remains locked for the rest of the round, so future candies of that color also need breaking.

The interface says Candys throughout. Internal `chips` field names remain for compatibility with the existing model/resource schema.

## Direct locked matches (v0.6.1)

Matching and movement now use separate predicates. A framed candy cannot move but its color participates in three-, four- and five-candy lines. Inspector-marked candies also match directly and may be swapped; their gravity anchoring remains the boss constraint. Existing adjacency breaking is retained. The per-tile reward logic applies identically to direct and collateral clears.
