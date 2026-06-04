<#
  package_release.ps1 - Gom mod Viet hoa + goi ngon ngu da dich vao 1 file zip chuan UnityModManager.

  Layout zip (UMM doc Info.json trong thu muc con cung ten Id = KingmakerVN):
    KingmakerVN/
      Info.json
      KingmakerVN.dll       (build o may bang mod\build.bat -> out\KingmakerVN\)
      vnVN_pack.json        (goi guid->text FULL: da dich=Viet, chua dich=English; sinh boi  vh.py build/pack)

  Dung local:   .\package_release.ps1                              (lay DLL tu .\out\KingmakerVN\KingmakerVN.dll)
  Dung CI:      .\package_release.ps1 -Dll .\release-assets\KingmakerVN.dll
#>
[CmdletBinding()]
param(
    [string]$Dll    = "$PSScriptRoot\out\KingmakerVN\KingmakerVN.dll",
    [string]$Pack   = "$PSScriptRoot\vnVN_pack.json",
    [string]$OutDir = "$PSScriptRoot\dist"
)
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

# --- Doc version tu Info.json (nguon su that) ---
$infoPath = Join-Path $root "mod\Info.json"
$info = Get-Content $infoPath -Raw | ConvertFrom-Json
$ver  = $info.Version
$id   = $info.Id
Write-Host "Packaging $id v$ver"

# --- Tap hop nguon: cap [duong dan nguon, ten trong zip] ---
$items = @(
    @{ Src = $infoPath; Dst = "Info.json" }
    @{ Src = $Dll;      Dst = "KingmakerVN.dll" }
    @{ Src = $Pack;     Dst = "vnVN_pack.json" }
)
foreach ($it in $items) {
    if (-not (Test-Path $it.Src)) { throw "THIEU file can thiet: $($it.Src)" }
}

# --- Staging sach: <OutDir>\stage\KingmakerVN\... ---
$stageRoot = Join-Path $OutDir "stage"
$modDir    = Join-Path $stageRoot $id
if (Test-Path $stageRoot) { Remove-Item $stageRoot -Recurse -Force }
New-Item -ItemType Directory -Force $modDir | Out-Null

foreach ($it in $items) {
    Copy-Item $it.Src (Join-Path $modDir $it.Dst) -Force
    $sz = [math]::Round((Get-Item $it.Src).Length / 1KB)
    Write-Host "  + $($it.Dst)  ($sz KB)"
}

# --- Nen zip ---
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force $OutDir | Out-Null }
$zip = Join-Path $OutDir "$id-$ver.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path $modDir -DestinationPath $zip -CompressionLevel Optimal
Remove-Item $stageRoot -Recurse -Force

$size = [math]::Round((Get-Item $zip).Length / 1MB, 2)
Write-Host ""
Write-Host "OK -> $zip  ($size MB)" -ForegroundColor Green
