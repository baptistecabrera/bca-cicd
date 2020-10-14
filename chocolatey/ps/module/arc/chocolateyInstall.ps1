[CmdLetBinding()]
param()

try
{
    $PackageName = $env:ChocolateyPackageTitle
    $PackageVersion = $env:ChocolateyPackageVersion

    Write-Verbose "Installing '$PackageName' version $PackageVersion."

    $PackageParameters = Get-PackageParameters
    
    $Scope = $PackageParameters.Scope
    
    if ($Scope)
    {
        switch -Regex ($Scope)
        {
            "AllUsers|CurrentUser" { Write-Verbose "Scope will be '$Scope'." }
            default
            {
                Write-Warning "Invalid scope '$Scope', using 'AllUsers' instead."
                $Scope = "AllUsers"
            }
        }
    }
    else { $Scope = "AllUsers" }

    if (($Scope -eq "AllUsers") -and !$env:IS_PROCESSELEVATED) { Write-Warning "Scope is set to 'AllUsers' and PowerShell is not elevated or elevation could not be determined, installation may not succeed." }

    if ($PSVersionTable.PSVersion.Major -lt 3) { Write-Error -Message "PowerShell version '$($PSVersionTable.PSVersion.ToString())' is not supported to install this package, at least PowerShell 3.0 must be installed." -Category NotInstalled -CategoryActivity $MyInvocation.MyCommand -TargetName $PackageName -TargetType "Package" -Exception NotInstalledException }
    elseif ($PSVersionTable.PSVersion.Major -in 3..4)
    {
        Write-Verbose "Importing data from manifest '$PackageName.psd1'."
        Import-LocalizedData -BaseDirectory (Join-Path $PSScriptRoot $PackageName) -FileName "$PackageName.psd1" -BindingVariable PackageManifest
    }
    else
    {
        Write-Verbose "Importing data from manifest '$PackageName.psd1'."
        $PackageManifest = Import-PowerShellDataFile -Path (Join-Path (Join-Path $PSScriptRoot $PackageName) "$PackageName.psd1")
    }

    if ($PackageManifest.PowerShellVersion)
    {
        [version]$RequiredVersion = $PackageManifest.PowerShellVersion
        if ($RequiredVersion -gt $PSVersionTable.PSVersion) { Write-Warning "Module '$PackageName' requires at least PowerShell version $($RequiredVersion.ToString()) when you are running $($PSVersionTable.PSVersion.ToString()), you may not be able to use this module." }
    }

    if ($Scope -eq "CurrentUser") { $ModuleDirectory = Join-Path (Join-Path ($env:PSModulePath.Split(";") | Where-Object { $_ -like "*$($env:USERNAME)*" }) $PackageName) $PackageVersion }
    else { $ModuleDirectory = Join-Path (Join-Path ($env:PSModulePath.Split(";") | Where-Object { $_ -like "*$($env:ProgramFiles)*" }) $PackageName) $PackageVersion }
    Write-Verbose "Installation path will be '$ModuleDirectory'."

    if (Test-Path $ModuleDirectory)
    {
        Write-Verbose "Removing already installed version."
        Remove-Item -Path $ModuleDirectory -Recurse -Force
    }
    Write-Verbose "Creating folder '$ModuleDirectory'."
    New-Item -Path $ModuleDirectory -Force -ItemType Directory | Out-Null

    Write-Verbose "Copying files to '$ModuleDirectory'."
    Get-ChildItem -Path (Join-Path $PSScriptRoot $PackageName) | Copy-Item -Destination $ModuleDirectory -Recurse -Container -Force

    if (Test-Path (Join-Path $ModuleDirectory "install.ps1"))
    {
        try
        {
            Write-Verbose "Running additional installation script"
            Push-Location $ModuleDirectory
            .\install.ps1 @PackageParameters
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

    Write-Verbose "'$PackageName' version $PackageVersion installed."
}
catch
{
    Write-Error $_
}