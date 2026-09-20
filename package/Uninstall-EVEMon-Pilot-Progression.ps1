[CmdletBinding()]
param([string]$CertificatesPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0
$FileName='eve-certificates-en-US.xml.gzip'
$ProjectName='EVEMon Pilot Progression'
$LegacyProjectName='EvE Pilot Progression'
$LegacyName='GMH - Generic Must Have'
$LegacyCharProgression='Char Progression'
$GroupId=900000000
$ClassMin=900001000; $ClassMax=900001999
$CertMin=900101000; $CertMax=900101999

function Read-GZipText {
    param([string]$Path)
    $file=[System.IO.File]::OpenRead($Path)
    try {
        $gzip=New-Object -TypeName System.IO.Compression.GZipStream -ArgumentList @($file,[System.IO.Compression.CompressionMode]::Decompress)
        try {
            $reader=New-Object -TypeName System.IO.StreamReader -ArgumentList @($gzip,[System.Text.Encoding]::UTF8,$true)
            try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
        } finally { $gzip.Dispose() }
    } finally { $file.Dispose() }
}
function Write-GZipXml {
    param([System.Xml.XmlDocument]$Xml,[string]$Path)
    $file=[System.IO.File]::Create($Path)
    try {
        $gzip=New-Object -TypeName System.IO.Compression.GZipStream -ArgumentList @($file,[System.IO.Compression.CompressionMode]::Compress)
        try {
            $utf8=New-Object -TypeName System.Text.UTF8Encoding -ArgumentList @($false)
            $writer=New-Object -TypeName System.IO.StreamWriter -ArgumentList @($gzip,$utf8)
            try { $Xml.Save($writer); $writer.Flush() } finally { $writer.Dispose() }
        } finally { $gzip.Dispose() }
    } finally { $file.Dispose() }
}
function Is-Ours {
    param([System.Xml.XmlElement]$Group)
    $n=[string]$Group.GetAttribute('name'); $v=0L
    [void][long]::TryParse([string]$Group.GetAttribute('id'),[ref]$v)
    if ($n -eq $ProjectName -or $n -eq $LegacyProjectName -or $n -eq $LegacyName -or $n -eq $LegacyCharProgression -or $v -eq $GroupId) { return $true }
    foreach ($cl in @($Group.SelectNodes('certificateClass'))) {
        $x=0L
        if ([long]::TryParse([string]$cl.GetAttribute('id'),[ref]$x) -and $x -ge $ClassMin -and $x -le $ClassMax) { return $true }
        foreach ($cert in @($cl.SelectNodes('certificate'))) {
            $y=0L
            if ([long]::TryParse([string]$cert.GetAttribute('id'),[ref]$y) -and $y -ge $CertMin -and $y -le $CertMax) { return $true }
        }
    }
    return $false
}
if (Get-Process -Name 'EVEMon' -ErrorAction SilentlyContinue) { throw 'Zamknij EVEMon przed odinstalowaniem.' }
if (-not $CertificatesPath) { $CertificatesPath=Join-Path (Join-Path $env:APPDATA 'EVEMon') $FileName }
if (-not (Test-Path -LiteralPath $CertificatesPath -PathType Leaf)) { throw "Nie znaleziono $CertificatesPath" }
$CertificatesPath=(Resolve-Path -LiteralPath $CertificatesPath).Path
[xml]$xml=Read-GZipText -Path $CertificatesPath
$removed=New-Object System.Collections.Generic.List[string]
foreach ($g in @($xml.SelectNodes('/certificatesDatafile/certificateGroup'))) {
    if (Is-Ours -Group $g) {
        $removed.Add("id=$($g.GetAttribute('id')) name='$($g.GetAttribute('name'))'")
        [void]$g.ParentNode.RemoveChild($g)
    }
}
if ($removed.Count -eq 0) { Write-Host 'Nie znaleziono zainstalowanej grupy EVEMon Pilot Progression. Nic nie zmieniono.'; exit 0 }
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$backup="$CertificatesPath.backup-before-evemon-pilot-progression-uninstall-$stamp"
$temp="$CertificatesPath.evemon-pilot-progression-uninstall-temp"
try {
    Write-GZipXml -Xml $xml -Path $temp
    [xml]$verify=Read-GZipText -Path $temp
    foreach ($g in @($verify.SelectNodes('/certificatesDatafile/certificateGroup'))) { if (Is-Ours -Group $g) { throw 'Walidacja uninstall: nadal znaleziono nasza grupe.' } }
    Copy-Item -LiteralPath $CertificatesPath -Destination $backup -Force
    Copy-Item -LiteralPath $temp -Destination $CertificatesPath -Force
} finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } }
Write-Host 'Usunieto EVEMon Pilot Progression z lokalnego datafile certyfikatow.' -ForegroundColor Green
foreach ($x in $removed) { Write-Host "  - $x" }
Write-Host "Backup: $backup"
Write-Host 'Plik eve-skills NIE zostal zmieniony.'
