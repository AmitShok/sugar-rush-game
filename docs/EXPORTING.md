# Windows and web releases

## Build

Use Godot 4.7.2 with its matching official export templates. Set `GODOT_EXE` to your Godot executable, then run **Export Builds.cmd**. Alternatively:

```powershell
./tools/export.ps1 -GodotExe "C:/path/to/Godot.exe"
./tools/export.ps1 -Target Web -GodotExe "C:/path/to/Godot.exe"
./tools/export.ps1 -Target Windows -GodotExe "C:/path/to/Godot.exe"
```

The script imports resources, checks export failures, creates release builds and packages them. `export_presets.cfg` also exposes both targets in Godot's Export dialog. Logs and generated output are under `builds/`, ignored by Git. Source art, font source files, documentation and test suites are excluded from the game pack. Font and engine notices are included alongside both releases.

## Windows

Distribute `builds/SugarRush-Windows.zip`. Extract it and launch `SugarRush.exe`; keep `SugarRush.pck` beside it. This is an unsigned portable x86-64 build, not an installer. A Windows computer with a compatible OpenGL graphics driver is required. Mouse, keyboard and Windows touchscreen input use the same logical canvas and controls.

## Web

Distribute `builds/SugarRush-Web.zip`. Upload its contents together to a static HTTPS host, or an HTML-game host such as itch.io, with `index.html` at the root. Keep all exported filenames unchanged. Do not open `index.html` through `file://`.

For local testing:

```powershell
python -m http.server 8765 --bind 127.0.0.1 --directory builds/web
```

Open `http://127.0.0.1:8765`. The single-threaded Compatibility build uses WebGL 2 and WebAssembly without requiring cross-origin isolation headers. The start screen provides Play and optional fullscreen, which depends on browser support. On narrow portrait touchscreens it recommends landscape and allows continuing in portrait. The game letterboxes rather than stretching its hitboxes. Landscape/fullscreen is recommended for phone readability; the interface has not been redesigned as a portrait-first phone app.

Tap a candy, then its neighbor to swap. Tap owned Jokers to read their current effect, including Roulette's chosen type. Shop cards, consumables, pause and settings are touch accessible. The web pause menu uses Save & Return to Title; it does not exit the engine and leave a dead canvas.

Runs and settings save locally: native Windows uses its Godot user-data directory, while the web build uses IndexedDB for that browser/site. Browser storage must be allowed. Clearing site data, changing browser/site, or private browsing can remove/prevent persistence. These saves do not sync between computers or between Windows and web. Prefer Save & Return to Title before closing a browser tab; abrupt termination during an animation returns to the last stable checkpoint. The game warns when the browser reports unavailable persistent storage.

Turn CRT off in Options if a device struggles with the screen effect. Browser audio starts after interaction. Tests run muted; audible speaker quality and latency still require hardware testing.

The web CRT uses a blended scanline/mask/vignette overlay without the desktop screen-copy glow. Runtime script errors, unexpected engine exits, and graphics-context loss display a readable message with Reload and Dismiss controls. Updating a hosted game requires replacing the complete web ZIP contents; pushing source to GitHub does not update an independently hosted export. Keep the same site/origin to preserve existing browser saves.

## Verification

- Run `tests/TouchRunner.tscn` with the renderer, Dummy audio and `--test` for native touch-event controls, volume, shop purchase, Joker inspection and pause.
- `python tests/windows_export_smoke.py` launches the real release executable with an isolated test save, sends native window input, checks swaps/save/title/Continue and closes it.
- Install Python Playwright (`python -m pip install playwright`), start the local server above, then run `python tests/web_export_smoke.py`. This tests the actual web release in installed Chrome with fresh browser profiles. Set `SUGAR_BROWSER_CHANNEL=msedge` to test installed Edge. It checks desktop, landscape phone, portrait phone and portrait tablet input, exact move counts, IndexedDB persistence, and Continue after reload.
- Tests never modify the player's existing save. Browser screenshots are written to `builds/test-captures`.
- To investigate WebKit, install `python -m playwright install webkit`, set `SUGAR_BROWSER_ENGINE=webkit`, then run the web smoke test. It still fails on any browser graphics error; it is not a substitute for physical iPhone testing.

Verified on this Windows machine, Chrome and Edge, including emulated touch viewports. Physical Android/iOS devices and Safari were not available; test those devices before advertising full device coverage. Browser emulation does not reproduce mobile GPU, memory, safe-area or audio behavior completely.

References: [Godot web export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html), [Godot Windows export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html).
