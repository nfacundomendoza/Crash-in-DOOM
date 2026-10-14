param([string]$Scenario = 'updated', [string]$ExtraMod = '', [int]$Map = 1, [string]$WadPath = '')
$projectPath = Split-Path -Parent $PSScriptRoot
$enginePath = Join-Path $projectPath 'tools\gzdoom\gzdoom.exe'
Get-Process gzdoom -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $enginePath } | Stop-Process
if (!$WadPath) { $WadPath = Join-Path $projectPath 'DOOM2.WAD' }
if (!(Test-Path -LiteralPath $WadPath)) { throw 'Indica -WadPath con la ruta a tu DOOM2.WAD.' }
$argsText = '-iwad "' + $wadPath + '" -file "' + $projectPath + '\crash-in-doom.pk3"'
if ($ExtraMod) { $argsText += ' -file "' + $ExtraMod + '"' }
$argsText += ' -config "' + $projectPath + '\verification\test.ini" -window -width 1280 -height 720 -noidle -noautoload -warp ' + $Map + ' -skill 2 -exec "' + $projectPath + '\start.cfg" -exec "' + $projectPath + '\verification\' + $Scenario + '.cfg" +logfile "' + $projectPath + '\verification\' + $Scenario + '.log"'
$gameProcess = Start-Process -FilePath $enginePath -WorkingDirectory $projectPath -ArgumentList $argsText -WindowStyle Hidden -PassThru
if (!$gameProcess.WaitForExit(25000)) { Write-Output ('Test still running: ' + $gameProcess.Id) }
Get-Content -LiteralPath (Join-Path $projectPath ('verification\' + $Scenario + '.log')) -Tail 14
