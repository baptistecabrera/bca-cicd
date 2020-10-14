$ErrorActionPreference = "Stop"

$ModuleName = $env:ChocolateyPackageTitle
$ModuleVersion = $env:ChocolateyPackageVersion
$ModulePath = Get-Content (Join-Path $PSScriptRoot "installPath.txt") -ErrorAction SilentlyContinue

Remove-Module -Name $ModuleName -Force -ErrorAction SilentlyContinue

if (!$ModulePath) { Write-Warning "No module path found, '$ModuleName' may have been manually uninstalled." }
$ModulePath | ForEach-Object {
    $ParentModulePath = (Split-Path $_ -Parent)

    Write-Verbose "Module path is '$_'."

    if ((Test-Path $_))
    {
        Write-Verbose "Emtpying directory '$_'."
        Remove-Item -Path $_ -Recurse -Force
    }
    else { Write-Warning "Path '$_' not found, '$ModuleName' may have been manually uninstalled." }
    if ((Test-Path $ParentModulePath) -and ((Get-ChildItem -Path $ParentModulePath | Measure-Object).Count -eq 0))
    {
        Write-Verbose "No file left in '$($ParentModulePath)', removing folder."
        Remove-Item -Path $ParentModulePath -Recurse -Force
    }
}

Write-Verbose "Module '$ModuleName' version $ModuleVersion uninstalled."