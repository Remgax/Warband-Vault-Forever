param(
    [string]$WowPath = 'D:\World of Warcraft\_forever_'
)
$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot '..\WarbandVaultForever'
$wowRoot = (Resolve-Path -LiteralPath $WowPath).Path
if (-not (Test-Path -LiteralPath (Join-Path $wowRoot 'Wow.exe'))) {
    throw 'Select a WoW client folder containing Wow.exe.'
}
$addons = Join-Path $wowRoot 'Interface\AddOns'
$destination = Join-Path $addons 'WarbandVaultForever'
if (Test-Path -LiteralPath $destination) {
    $backupRoot = Join-Path $PSScriptRoot '..\work\install-backups'
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    $backup = Join-Path $backupRoot ('WarbandVaultForever-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
    Copy-Item -LiteralPath $destination -Destination $backup -Recurse
    Write-Output "Previous addon copied to $backup"
}
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Get-ChildItem -LiteralPath $source -Force | Copy-Item -Destination $destination -Recurse -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot '..\LICENSE') -Destination $destination -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot '..\CHANGELOG.md') -Destination $destination -Force
Write-Output "Installed to $destination"
Write-Output 'Restart WoW after first installation. Then enable Warband Vault Forever and type /wvf.'
