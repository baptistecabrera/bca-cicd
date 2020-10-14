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

    if ($Scope -eq "CurrentUser") { $ScriptDirectory = Join-Path (Split-Path ($env:PSModulePath.Split(";") | Where-Object { $_ -like "*$($env:USERNAME)*" }) -Parent) "Scripts" }
    else { $ScriptDirectory = Join-Path (Split-Path ($env:PSModulePath.Split(";") | Where-Object { $_ -like "*$($env:ProgramFiles)*" }) -Parent) "Scripts" }

    Write-Verbose "Installation path will be '$ScriptDirectory'."

    if (!(Test-Path $ScriptDirectory))
    {
         Write-Verbose "Creating folder '$ScriptDirectory'."
        New-Item -Path $ScriptDirectory -Force -ItemType Directory | Out-Null
    }

    Write-Verbose "Copying files to '$ScriptDirectory'."
    Get-ChildItem -Path (Join-Path $PSScriptRoot $PackageName) | Copy-Item -Destination $ScriptDirectory -Recurse -Container -Force

    if (Test-Path (Join-Path $ScriptDirectory "install.ps1"))
    {
        try
        {
            Write-Verbose "Running additional installation script"
            Push-Location $ScriptDirectory
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