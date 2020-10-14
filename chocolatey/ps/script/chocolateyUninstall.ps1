$ErrorActionPreference = "Stop"

$ScriptName = $env:ChocolateyPackageTitle
$ScriptVersion = $env:ChocolateyPackageVersion
$ScriptPath = Get-Content (Join-Path $PSScriptRoot "installPath.txt") -ErrorAction SilentlyContinue

if (!$ScriptPath) { Write-Warning "No script path found, '$ScriptName' may have been manually uninstalled." }
$ScriptPath | ForEach-Object {
    $ScriptFilePath = Join-Path $ScriptPath ("{0}.ps1" -f $ScriptName)
    Write-Verbose "Script path is '$ScriptFilePath'."

    if ((Test-Path $ScriptFilePath))
    {
        Write-Verbose "Removing script '$ScriptFilePath'."
        Remove-Item -Path $ScriptFilePath -Force
    }
    else { Write-Warning "Path '$ScriptFilePath' not found, '$ScriptName' may have been manually uninstalled." }
}

Write-Verbose "Script '$ScriptName' version $ScriptVersion uninstalled."