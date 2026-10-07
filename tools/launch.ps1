param([switch]$Editor, [switch]$ExportArt)
$projectRoot = Split-Path $PSScriptRoot -Parent
if ($ExportArt) {
    $asepritePath = 'C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe'
    if (-not (Test-Path -LiteralPath $asepritePath)) { throw 'Aseprite was not found. Export PNGs manually or update tools/launch.ps1.' }
    $artArgs = @('-b', '--script-param', ('"root=' + $projectRoot + '"'), '--script', ('"' + (Join-Path $PSScriptRoot 'export_art.lua') + '"'))
    Start-Process -FilePath $asepritePath -ArgumentList $artArgs -WindowStyle Hidden -Wait
    exit
}
$godotPath = $env:GODOT_EXE
if (-not $godotPath -or -not (Test-Path -LiteralPath $godotPath)) {
    $found = Get-Command godot -ErrorAction SilentlyContinue
    if ($found) { $godotPath = $found.Source }
    else { throw 'Open project.godot in Godot, or set GODOT_EXE to your Godot executable.' }
}
if (-not $Editor -and -not (Test-Path -LiteralPath (Join-Path $projectRoot '.godot/imported'))) {
    $importArgs = @('--headless', '--audio-driver', 'Dummy', '--path', ('"' + $projectRoot + '"'), '--editor', '--import', '--quit')
    $importProcess = Start-Process -FilePath $godotPath -ArgumentList $importArgs -WindowStyle Hidden -Wait -PassThru
    if ($importProcess.ExitCode -ne 0) { throw 'Godot could not import this project. Open project.godot in the editor for diagnostics.' }
}
$launchArgs = @('--path', ('"' + $projectRoot + '"'))
if ($Editor) { $launchArgs += '--editor' }
# This foreground launch is the user's interactive game/editor, not a background test.
Start-Process -FilePath $godotPath -ArgumentList $launchArgs
