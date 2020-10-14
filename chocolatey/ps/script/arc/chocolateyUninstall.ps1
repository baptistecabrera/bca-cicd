[CmdLetBinding()]
param()

try
{
    $PackageName = $env:ChocolateyPackageTitle
    $PackageVersion = $env:ChocolateyPackageVersion

    Write-Verbose "Uninstalling '$PackageName' version $PackageVersion."

    $PackageParameters = Get-PackageParameters

    if (!$env:IS_PROCESSELEVATED) { Write-Verbose "PowerShell is not elevated or elevation could not be determined, uninstallation may not succeed." }

    $ScriptDirectory = $env:PSModulePath.Split(";") | ForEach-Object { Join-Path (Split-Path $_ -Parent) "Scripts" } | Where-Object { (Test-Path (Join-Path $_ "$PackageName.ps1")) }
    Write-Verbose "Script installed in '$($ScriptDirectory -join ""', '"")'."

    if (Test-Path (Join-Path $PSScriptRoot "uninstall.ps1"))
    {
        try
        {
            Write-Verbose "Running additional uninstallation script"
            Push-Location $PSScriptRoot
            .\uninstall.ps1 @PackageParameters
        }
        catch
        {
            Write-Error $_
        }
        finally
        {
            Pop-Location
        }
    }

    $ScriptDirectory | ForEach-Object {
        Remove-Item (Join-Path $_ "$PackageName.ps1") -Force
    }

    Write-Verbose "'$PackageName' version $PackageVersion uninstalled."
}
catch
{
    Write-Error $_
}