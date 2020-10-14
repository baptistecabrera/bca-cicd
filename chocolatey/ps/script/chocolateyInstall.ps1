$ErrorActionPreference = "Stop"

$ScriptName = $env:ChocolateyPackageTitle
$ScriptVersion = $env:ChocolateyPackageVersion
$ScriptPath = @()
$PackageParameters = Get-PackageParameters

if ($PackageParameters.Desktop -or !$PackageParameters.Core) { $ScriptPath += Join-Path $env:ProgramFiles "WindowsPowerShell\Scripts" }
if ($PackageParameters.Core) { $ScriptPath += Join-Path $env:ProgramFiles "PowerShell\Scripts" }

$ScriptPath -join "`r`n" | Set-Content (Join-Path $PSScriptRoot "installPath.txt")

$ScriptPath | ForEach-Object {
    Write-Verbose "Installation path will be '$_'."

    if (!(Test-Path $_))
    {
        Write-Verbose "Creating folder '$_'."
        New-Item -Path $_ -Force -ItemType Directory | Out-Null
    }

    Write-Verbose "Installing script '$ScriptName' version $ScriptVersion in '$_'."
    Get-ChildItem -Path (Join-Path $PSScriptRoot $ScriptName) -Filter ("{0}.ps1" -f $ScriptName) | Copy-Item -Destination $_ -Recurse -Container -Force
}
Write-Verbose "Script '$ScriptName' version $ScriptVersion installed."