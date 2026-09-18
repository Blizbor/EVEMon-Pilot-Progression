param([string]$OutputDirectory = (Join-Path $PSScriptRoot '..\dist'))
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$package=Join-Path $repo 'package'
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$zip=Join-Path $OutputDirectory 'EvE-Pilot-Progression-EVEMon.zip'
if(Test-Path $zip){Remove-Item $zip -Force}
Compress-Archive -Path (Join-Path $package '*') -DestinationPath $zip -CompressionLevel Optimal
Write-Host $zip
