# Sugar Rush project instructions

## Automatic Git synchronization

The project owner explicitly requested automatic commits and pushes after every completed project change.

- Canonical repository: https://github.com/AmitShok/sugar-rush-game.git
- Work in this Git checkout. Before editing, inspect the branch, upstream, working tree, and relevant repository instructions.
- After completing a requested change, run the appropriate validation and review the diff. Stage only the intended project changes, create a descriptive commit, and push the current branch to its tracked upstream in this repository. The initial development branch is `main`, tracking `origin/main`.
- Do not ask for routine commit/push confirmation; the owner has already authorized it. Batch a coherent completed change rather than committing intermediate edits that are still broken.
- Preserve unrelated user work. Never discard changes, rewrite published history, or force-push to satisfy this instruction.
- If authentication, permissions, branch protection, or remote divergence prevents pushing, report the concrete blocker and retain the local work. Do not claim a push succeeded until Git confirms it.
- Finish by reporting the commit and whether the push succeeded.

## Existing project preferences

- Create or replace visual artwork in Aseprite and retain editable `.aseprite` masters alongside the runtime exports. Reuse existing Aseprite UI skins where suitable.
- Keep automated Godot runs silent with the Dummy audio driver and `--test` flag.
- Preserve the fixed logical canvas and verify click alignment when changing layouts.
