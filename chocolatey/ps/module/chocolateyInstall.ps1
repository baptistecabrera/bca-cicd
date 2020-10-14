$ErrorActionPreference = "Stop"

$ModuleName = $env:ChocolateyPackageTitle
$ModuleVersion = $env:ChocolateyPackageVersion
$ModulePath = @()
$PackageParameters = Get-PackageParameters

Remove-Module -Name $ModuleName -Force -ErrorAction SilentlyContinue

if ($PackageParameters.Desktop -or !$PackageParameters.Core)
{
    if ($PSVersionTable.PSVersion -lt [Version]'5.1') { Write-Warning "PowerShell version '$($PSVersionTable.PSVersion.ToString())' is not supported to install this package, at least PowerShell 5.1 must be installed, the module may not work properly." }
    $ModulePath += Join-Path (Join-Path $env:ProgramFiles "WindowsPowerShell\Modules") "$ModuleName\$ModuleVersion"
}
if ($PackageParameters.Core) { $ModulePath += Join-Path (Join-Path $env:ProgramFiles "PowerShell\Modules") "$ModuleName\$ModuleVersion" }

$ModulePath -join "`r`n" | Set-Content (Join-Path $PSScriptRoot "installPath.txt")

$ModulePath | ForEach-Object {
    Write-Verbose "Installation path will be '$_'."

    if ((Test-Path $_))
    {
        Write-Verbose "Removing already installed version."
        Remove-Item -Path $_ -Recurse -Force
    }

    Write-Verbose "Creating folder '$_'."
    New-Item -Path $_ -Force -ItemType Directory | Out-Null

    Write-Verbose "Installing module '$ModuleName' version $ModuleVersion in '$_'."
    Get-ChildItem -Path (Join-Path $PSScriptRoot $ModuleName) | Copy-Item -Destination $_ -Recurse -Container -Force
}

Write-Verbose "Module '$ModuleName' version $ModuleVersion installed."