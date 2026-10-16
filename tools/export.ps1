param([ValidateSet('All','Windows','Web')][string]$Target='All', [string]$GodotExe=$env:GODOT_EXE)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
if (-not $GodotExe) { $GodotExe=(Get-Command godot -ErrorAction Stop).Source }
if (-not (Test-Path -LiteralPath $GodotExe)) { throw 'Set GODOT_EXE or pass -GodotExe with the Godot executable path.' }
$buildRoot=Join-Path $projectRoot 'builds'
New-Item -ItemType Directory -Force -Path $buildRoot | Out-Null
function Run-Godot([string[]]$ExportArgs, [string]$LogName) {
 $log=Join-Path $buildRoot ($LogName+'.log')
 $err=Join-Path $buildRoot ($LogName+'-errors.log')
 $argsList=@('--headless','--audio-driver','Dummy','--path',('"'+$projectRoot+'"'))+$ExportArgs
 $process=Start-Process -FilePath $GodotExe -ArgumentList $argsList -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $log -RedirectStandardError $err
 if ($process.ExitCode -ne 0 -or (Select-String -LiteralPath $err -Pattern 'ERROR:|SCRIPT ERROR' -Quiet)) { throw "Godot failed. See $log and $err" }
}
Run-Godot @('--editor','--import','--quit') 'import'
if ($Target -in @('All','Windows')) {
 $folder=Join-Path $buildRoot 'windows'
 New-Item -ItemType Directory -Force -Path $folder | Out-Null
 Run-Godot @('--export-release','"Windows Desktop"',('"'+(Join-Path $folder 'SugarRush.exe')+'"')) 'windows-export'
 Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/DISTRIBUTION-LICENSES.txt'),(Join-Path $projectRoot 'docs/GODOT-NOTICES.txt') -Destination $folder
 Compress-Archive -Path (Join-Path $folder '*') -DestinationPath (Join-Path $buildRoot 'SugarRush-Windows.zip') -Force
}
if ($Target -in @('All','Web')) {
 $folder=Join-Path $buildRoot 'web'
 New-Item -ItemType Directory -Force -Path $folder | Out-Null
 Run-Godot @('--export-release','Web',('"'+(Join-Path $folder 'index.html')+'"')) 'web-export'
 Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/DISTRIBUTION-LICENSES.txt'),(Join-Path $projectRoot 'docs/GODOT-NOTICES.txt') -Destination $folder
 Compress-Archive -Path (Join-Path $folder '*') -DestinationPath (Join-Path $buildRoot 'SugarRush-Web.zip') -Force
}
Write-Output "Exports ready in $buildRoot"
