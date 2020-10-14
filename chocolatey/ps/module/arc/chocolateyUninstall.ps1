[CmdLetBinding()]
param()

try
{
    $PackageName = $env:ChocolateyPackageTitle
    $PackageVersion = $env:ChocolateyPackageVersion

    Write-Verbose "Uninstalling '$PackageName' version $PackageVersion."

    $PackageParameters = Get-PackageParameters

    if (!$env:IS_PROCESSELEVATED) { Write-Verbose "PowerShell is not elevated or elevation could not be determined, uninstallation may not succeed." }

    $ModuleDirectory = Split-Path (Get-Module -Name $PackageName -ListAvailable | Where-Object { $_.Version -eq $PackageVersion }).Path -Parent
    $ParentModuleDirectory = (Split-Path $ModuleDirectory -Parent)
    Write-Verbose "Installation path is '$ModuleDirectory'."

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

    if (Test-Path $ModuleDirectory)
    {
        Write-Verbose "Emtpying directory '$ModuleDirectory'."
        Remove-Item -Path $ModuleDirectory -Recurse -Force
    }
    if ((Test-Path $ParentModuleDirectory) -and ((Get-ChildItem -Path $ParentModuleDirectory | Measure-Object).Count -eq 0))
    {
        Write-Verbose "No file left in '$($ParentModuleDirectory)', removing folder."
        Remove-Item -Path $ParentModuleDirectory -Recurse -Force
    }

    Write-Verbose "'$PackageName' version $PackageVersion uninstalled."
}
catch
{
    Write-Error $_
}