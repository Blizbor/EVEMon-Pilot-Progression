[CmdletBinding()]
param(
    [string]$CertificatesPath,
    [string]$SkillsPath,
    [string]$DefinitionsPath = (Join-Path $PSScriptRoot 'EVEMon-Pilot-Progression.definitions.json')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$CertificateFileName = 'eve-certificates-en-US.xml.gzip'
$SkillsFileName       = 'eve-skills-en-US.xml.gzip'
$ProjectName          = 'EVEMon Pilot Progression'
$LegacyProjectName    = 'EvE Pilot Progression'
$LegacyGmhGroupName   = 'GMH - Generic Must Have'
$LegacyCharProgression = 'Char Progression'
$OurGroupId           = 900000000
$OurClassIdMin        = 900001000
$OurClassIdMax        = 900001999
$OurCertificateIdMin  = 900101000
$OurCertificateIdMax  = 900101999
$AllowedGrades = @('Basic','Standard','Improved','Advanced','Elite')

function Read-GZipText {
    param([Parameter(Mandatory=$true)][string]$Path)
    $file = [System.IO.File]::OpenRead($Path)
    try {
        $gzip = New-Object -TypeName System.IO.Compression.GZipStream -ArgumentList @($file, [System.IO.Compression.CompressionMode]::Decompress)
        try {
            $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList @($gzip, [System.Text.Encoding]::UTF8, $true)
            try { return $reader.ReadToEnd() }
            finally { $reader.Dispose() }
        }
        finally { $gzip.Dispose() }
    }
    finally { $file.Dispose() }
}

function Write-GZipXml {
    param(
        [Parameter(Mandatory=$true)][System.Xml.XmlDocument]$Xml,
        [Parameter(Mandatory=$true)][string]$Path
    )
    $file = [System.IO.File]::Create($Path)
    try {
        $gzip = New-Object -TypeName System.IO.Compression.GZipStream -ArgumentList @($file, [System.IO.Compression.CompressionMode]::Compress)
        try {
            $utf8 = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList @($false)
            $writer = New-Object -TypeName System.IO.StreamWriter -ArgumentList @($gzip, $utf8)
            try {
                $Xml.Save($writer)
                $writer.Flush()
            }
            finally { $writer.Dispose() }
        }
        finally { $gzip.Dispose() }
    }
    finally { $file.Dispose() }
}

function Find-EVEMonExe {
    $candidates = New-Object System.Collections.Generic.List[string]
    if (${env:ProgramFiles(x86)}) { $candidates.Add((Join-Path ${env:ProgramFiles(x86)} 'EVEMon\EVEMon.exe')) }
    if ($env:ProgramFiles) { $candidates.Add((Join-Path $env:ProgramFiles 'EVEMon\EVEMon.exe')) }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return (Resolve-Path -LiteralPath $candidate).Path }
    }
    return $null
}

function Find-ResourceFile {
    param([Parameter(Mandatory=$true)][string]$FileName)
    $candidates = New-Object System.Collections.Generic.List[string]
    $exe = Find-EVEMonExe
    if ($exe) { $candidates.Add((Join-Path (Split-Path -Parent $exe) "Resources\$FileName")) }
    if ($env:ProgramFiles) { $candidates.Add((Join-Path $env:ProgramFiles "EVEMon\Resources\$FileName")) }
    if (${env:ProgramFiles(x86)}) { $candidates.Add((Join-Path ${env:ProgramFiles(x86)} "EVEMon\Resources\$FileName")) }
    $candidates.Add((Join-Path (Get-Location).Path "src\EVEMon.Common\Resources\$FileName"))
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return (Resolve-Path -LiteralPath $candidate).Path }
    }
    return $null
}

function Resolve-RuntimeCertificates {
    param([string]$ExplicitPath)
    if ($ExplicitPath) {
        if (-not (Test-Path -LiteralPath $ExplicitPath -PathType Leaf)) { throw "Nie znaleziono certificates datafile: $ExplicitPath" }
        return (Resolve-Path -LiteralPath $ExplicitPath).Path
    }
    $appDir = Join-Path $env:APPDATA 'EVEMon'
    $appFile = Join-Path $appDir $CertificateFileName
    if (Test-Path -LiteralPath $appFile -PathType Leaf) { return (Resolve-Path -LiteralPath $appFile).Path }
    $resource = Find-ResourceFile -FileName $CertificateFileName
    if (-not $resource) { throw "Nie znaleziono $CertificateFileName w APPDATA ani Resources EVEMona." }
    New-Item -ItemType Directory -Path $appDir -Force | Out-Null
    Copy-Item -LiteralPath $resource -Destination $appFile -Force
    return (Resolve-Path -LiteralPath $appFile).Path
}

function Resolve-SkillsForRead {
    param([string]$ExplicitPath)
    if ($ExplicitPath) {
        if (-not (Test-Path -LiteralPath $ExplicitPath -PathType Leaf)) { throw "Nie znaleziono skills datafile: $ExplicitPath" }
        return (Resolve-Path -LiteralPath $ExplicitPath).Path
    }
    $appFile = Join-Path (Join-Path $env:APPDATA 'EVEMon') $SkillsFileName
    if (Test-Path -LiteralPath $appFile -PathType Leaf) { return (Resolve-Path -LiteralPath $appFile).Path }
    $resource = Find-ResourceFile -FileName $SkillsFileName
    if (-not $resource) { throw "Nie znaleziono $SkillsFileName w APPDATA ani Resources EVEMona." }
    return $resource
}

function Build-SkillIdMap {
    param([Parameter(Mandatory=$true)][System.Xml.XmlDocument]$SkillsXml)
    $map = @{}
    foreach ($node in @($SkillsXml.SelectNodes("//*[local-name()='skill' and @id and @name]"))) {
        $name = [string]$node.GetAttribute('name')
        $id = [string]$node.GetAttribute('id')
        if ($name -and $id) { $map[$name] = $id }
    }
    if ($map.Count -lt 100) { throw "Podejrzanie malo skilli w $SkillsFileName ($($map.Count)). Nic nie zapisano." }
    return $map
}

function Get-MissingDefinitionSkills {
    param(
        [Parameter(Mandatory=$true)]$Definitions,
        [Parameter(Mandatory=$true)][hashtable]$SkillIdMap
    )
    $missing = New-Object System.Collections.Generic.List[string]
    foreach ($c in $Definitions) {
        foreach ($g in @($c.grades)) {
            foreach ($r in @($g.requirements)) {
                $s = [string]$r.skill
                if (-not $SkillIdMap.ContainsKey($s) -and -not $missing.Contains($s)) { $missing.Add($s) }
            }
        }
    }
    return @($missing | Sort-Object)
}

function New-XmlElementWithAttributes {
    param(
        [Parameter(Mandatory=$true)][System.Xml.XmlDocument]$Document,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][hashtable]$Attributes
    )
    $node = $Document.CreateElement($Name)
    foreach ($key in $Attributes.Keys) { $node.SetAttribute([string]$key, [string]$Attributes[$key]) }
    return $node
}

function Validate-Definitions {
    param([Parameter(Mandatory=$true)]$Definition)
    $defs = @($Definition.certificates)
    $expectedCerts = [int]$Definition.certificate_count
    $expectedGrades = [int]$Definition.evemon_grade_count
    $expectedRequires = [int]$Definition.evemon_requires_count
    if ($defs.Count -ne $expectedCerts) { throw "Definitions: oczekiwano $expectedCerts certyfikatow, jest $($defs.Count)." }
    $classIds=@{}; $certIds=@{}; $names=@{}; $gradeCount=0; $requiresCount=0
    foreach ($c in $defs) {
        $cid=[int]$c.class_id; $certid=[int]$c.certificate_id; $name=[string]$c.name
        if ($classIds.ContainsKey($cid)) { throw "Duplikat class_id $cid" }
        if ($certIds.ContainsKey($certid)) { throw "Duplikat certificate_id $certid" }
        if ($names.ContainsKey($name)) { throw "Duplikat nazwy '$name'" }
        $classIds[$cid]=$true; $certIds[$certid]=$true; $names[$name]=$true
        if (@($c.grades).Count -ne 5) { throw "'$name' musi miec 5 grade'ow dla Certificate Browser EVEMona." }
        for ($i=0; $i -lt 5; $i++) {
            if ([string]$c.grades[$i].grade -ne $AllowedGrades[$i]) { throw "Niepoprawna kolejnosc grade'ow w '$name'." }
        }
        foreach ($g in @($c.grades)) {
            $gradeCount++
            $seen=@{}
            foreach ($r in @($g.requirements)) {
                $skill=[string]$r.skill; $level=[int]$r.level
                if (-not $skill -or $level -lt 1 -or $level -gt 5) { throw "Niepoprawne wymaganie w '$name' / $($g.grade)." }
                if ($seen.ContainsKey($skill)) { throw "Duplikat skilla '$skill' w '$name' / $($g.grade)." }
                $seen[$skill]=$true; $requiresCount++
            }
            if ($seen.Count -eq 0) { throw "Pusty grade w '$name' / $($g.grade)." }
        }
    }
    if ($gradeCount -ne $expectedGrades) { throw "Definitions: oczekiwano $expectedGrades grade entries, jest $gradeCount." }
    if ($requiresCount -ne $expectedRequires) { throw "Definitions: oczekiwano $expectedRequires requires, jest $requiresCount." }
}

function Test-IsOurCertificateGroup {
    param([Parameter(Mandatory=$true)][System.Xml.XmlElement]$Group)
    $name=[string]$Group.GetAttribute('name')
    $idText=[string]$Group.GetAttribute('id')
    $id=0L; [void][long]::TryParse($idText,[ref]$id)
    if ($name -eq $ProjectName -or $name -eq $LegacyProjectName -or $name -eq $LegacyGmhGroupName -or $name -eq $LegacyCharProgression -or $id -eq $OurGroupId) { return $true }
    foreach ($cl in @($Group.SelectNodes('certificateClass'))) {
        $v=0L
        if ([long]::TryParse([string]$cl.GetAttribute('id'),[ref]$v) -and $v -ge $OurClassIdMin -and $v -le $OurClassIdMax) { return $true }
        foreach ($cert in @($cl.SelectNodes('certificate'))) {
            $cv=0L
            if ([long]::TryParse([string]$cert.GetAttribute('id'),[ref]$cv) -and $cv -ge $OurCertificateIdMin -and $cv -le $OurCertificateIdMax) { return $true }
        }
    }
    return $false
}

function Remove-OurCertificateGroups {
    param([Parameter(Mandatory=$true)][System.Xml.XmlDocument]$Xml)
    $removed = New-Object System.Collections.Generic.List[string]
    foreach ($group in @($Xml.SelectNodes('/certificatesDatafile/certificateGroup'))) {
        if (Test-IsOurCertificateGroup -Group $group) {
            $removed.Add("id=$($group.GetAttribute('id')) name='$($group.GetAttribute('name'))'")
            [void]$group.ParentNode.RemoveChild($group)
        }
    }
    return @($removed)
}

function Add-RequiresFromDefinition {
    param(
        [Parameter(Mandatory=$true)][System.Xml.XmlDocument]$Document,
        [Parameter(Mandatory=$true)][System.Xml.XmlElement]$Certificate,
        [Parameter(Mandatory=$true)][hashtable]$SkillIdMap,
        [Parameter(Mandatory=$true)][string]$Grade,
        [Parameter(Mandatory=$true)]$Requirements
    )
    foreach ($r in @($Requirements)) {
        $skill=[string]$r.skill; $level=[int]$r.level
        if (-not $SkillIdMap.ContainsKey($skill)) { throw "Brak skilla '$skill' w EVEMon skills datafile. Nic nie zapisano." }
        $node = New-XmlElementWithAttributes -Document $Document -Name 'requires' -Attributes @{
            id=[string]$SkillIdMap[$skill]; skill=$skill; level=$level; grade=$Grade
        }
        [void]$Certificate.AppendChild($node)
    }
}

if (Get-Process -Name 'EVEMon' -ErrorAction SilentlyContinue) {
    throw 'EVEMon jest uruchomiony. Zamknij go calkowicie i uruchom instalator ponownie.'
}
if (-not (Test-Path -LiteralPath $DefinitionsPath -PathType Leaf)) { throw "Nie znaleziono definicji: $DefinitionsPath" }
$definition = Get-Content -LiteralPath $DefinitionsPath -Raw | ConvertFrom-Json
if ([string]$definition.project -ne $ProjectName) { throw "Nieoczekiwany projekt w definitions.json: $($definition.project)" }
Validate-Definitions -Definition $definition
$definitions = @($definition.certificates)

$exe = Find-EVEMonExe
if ($exe) {
    $vi=(Get-Item -LiteralPath $exe).VersionInfo
    Write-Host "EVEMon:       $exe"
    Write-Host "Version:      $($vi.ProductVersion)"
}
else { Write-Host 'EVEMon exe:   nie znaleziono automatycznie (datafile nadal moga byc dostepne).' -ForegroundColor Yellow }

Write-Host ''
Write-Host 'PREREQUISITE: run EVEMon once and install all datafile/SDE updates before applying this package.' -ForegroundColor Cyan
Write-Host 'Then close EVEMon completely. This installer never patches eve-skills.' -ForegroundColor Cyan
Write-Host ''

$certPath = Resolve-RuntimeCertificates -ExplicitPath $CertificatesPath
$skillPath = Resolve-SkillsForRead -ExplicitPath $SkillsPath
Write-Host "Certificates: $certPath"
Write-Host "Skills:       $skillPath"
Write-Host "Definitions:  $DefinitionsPath"

$skillPath = Resolve-SkillsForRead -ExplicitPath $SkillsPath
[xml]$skillsXml = Read-GZipText -Path $skillPath
$skillMap = Build-SkillIdMap -SkillsXml $skillsXml
$missing = @(Get-MissingDefinitionSkills -Definitions $definitions -SkillIdMap $skillMap)
if ($missing.Count -gt 0) {
    $msg = "EVEMon skills datafile nie zawiera $($missing.Count) wymaganych skilli:`r`n  - " + ($missing -join "`r`n  - ")
    throw $msg + "`r`nNic nie zapisano. Zaktualizuj datafiles w EVEMonie 5.x; ten instalator celowo NIE patchuje skilli."
}

[xml]$certXml = Read-GZipText -Path $certPath
if (-not $certXml.DocumentElement -or $certXml.DocumentElement.Name -ne 'certificatesDatafile') {
    throw "Nieoczekiwany root w $CertificateFileName. Nic nie zapisano."
}
$removed = @(Remove-OurCertificateGroups -Xml $certXml)

$group = New-XmlElementWithAttributes -Document $certXml -Name 'certificateGroup' -Attributes @{
    id=$OurGroupId
    name=$ProjectName
    description='Role-based pilot progression standards aligned with EvE Modular Skillplans.'
}
foreach ($c in $definitions) {
    $class = New-XmlElementWithAttributes -Document $certXml -Name 'certificateClass' -Attributes @{
        id=[int]$c.class_id; name=[string]$c.name; description=[string]$c.description
    }
    $certificate = New-XmlElementWithAttributes -Document $certXml -Name 'certificate' -Attributes @{
        id=[int]$c.certificate_id; description=[string]$c.description
    }
    foreach ($g in @($c.grades)) {
        Add-RequiresFromDefinition -Document $certXml -Certificate $certificate -SkillIdMap $skillMap -Grade ([string]$g.grade) -Requirements $g.requirements
    }
    [void]$class.AppendChild($certificate)
    [void]$group.AppendChild($class)
}
[void]$certXml.DocumentElement.AppendChild($group)

$expectedCerts=[int]$definition.certificate_count
$expectedGrades=[int]$definition.evemon_grade_count
$expectedRequires=[int]$definition.evemon_requires_count
$timestamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$certBackup="$certPath.backup-evemon-pilot-progression-$timestamp"
$certTemp="$certPath.evemon-pilot-progression-temp"
try {
    if (Test-Path -LiteralPath $certTemp) { Remove-Item -LiteralPath $certTemp -Force }
    Write-GZipXml -Xml $certXml -Path $certTemp
    [xml]$verify=Read-GZipText -Path $certTemp
    $vg=$verify.SelectSingleNode("/certificatesDatafile/certificateGroup[@id='$OurGroupId' and @name='$ProjectName']")
    if (-not $vg) { throw 'Walidacja: brak nowej grupy EVEMon Pilot Progression.' }
    $classes=@($vg.SelectNodes('certificateClass'))
    $requires=@($vg.SelectNodes('certificateClass/certificate/requires'))
    $gradeKeys=@{}
    foreach ($cl in $classes) {
        foreach ($r in @($cl.SelectNodes('certificate/requires'))) {
            $gradeKeys["$($cl.GetAttribute('id'))|$($r.GetAttribute('grade'))"]=$true
        }
    }
    if ($classes.Count -ne $expectedCerts) { throw "Walidacja: certyfikaty $($classes.Count), oczekiwano $expectedCerts." }
    if ($gradeKeys.Count -ne $expectedGrades) { throw "Walidacja: grade entries $($gradeKeys.Count), oczekiwano $expectedGrades." }
    if ($requires.Count -ne $expectedRequires) { throw "Walidacja: requires $($requires.Count), oczekiwano $expectedRequires." }

    Copy-Item -LiteralPath $certPath -Destination $certBackup -Force
    Copy-Item -LiteralPath $certTemp -Destination $certPath -Force
}
catch {
    if (Test-Path -LiteralPath $certBackup) { Copy-Item -LiteralPath $certBackup -Destination $certPath -Force -ErrorAction SilentlyContinue }
    throw
}
finally {
    if (Test-Path -LiteralPath $certTemp) { Remove-Item -LiteralPath $certTemp -Force -ErrorAction SilentlyContinue }
}

Write-Host ''
Write-Host 'OK - zainstalowano EVEMon Pilot Progression dla EVEMon 5.x.' -ForegroundColor Green
Write-Host "Usuniete stare grupy: $($removed.Count)"
foreach ($x in $removed) { Write-Host "  - $x" }
Write-Host "Backup certyfikatow: $certBackup"
Write-Host "Skills datafile:      NIE MODYFIKOWANY przez instalacje EVEMon Pilot Progression"
Write-Host "Certyfikaty:          $expectedCerts"
Write-Host "Poziomy logiczne:     $($definition.logical_milestone_count) (w tym lokalne drabiny 5-stopniowe)"
Write-Host "EVEMon grade entries: $expectedGrades (mieszanka realnych poziomow i aliasow zgodnosci)"
Write-Host "Wymagania EVEMon:     $expectedRequires"
Write-Host ''
Write-Host 'Uruchom EVEMon -> Certificate Browser -> EVEMon Pilot Progression.' -ForegroundColor Cyan
