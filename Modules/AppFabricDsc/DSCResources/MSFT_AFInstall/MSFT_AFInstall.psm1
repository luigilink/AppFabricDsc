$Script:UninstallPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
$script:InstallKeyPattern = 'AppFabric'

<#
.SYNOPSIS

This function gets all Key properties defined in the resource schema file

.PARAMETER Ensure

This is The Ensure Set to 'present' to specificy that the product should be installed.

.PARAMETER Path

This is the full path of setup.exe

.PARAMETER Features

This is a list for the AppFabric Features that will be installed

.PARAMETER Gac

This is boolean for install all assemblies associated with the specified features into the Global Assembly Cache

.PARAMETER EnableUpdate

This is boolean that enable updates after AppFabric Server setup complete

#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,
                
        [Parameter(Mandatory = $false)]
        [System.String[]]
        [ValidateSet("hostingservices","hostingadmin","cachingservice","cacheclient","cacheadmin")]
        $Features,

        [Parameter(Mandatory = $false)]
        [System.Boolean]
        $Gac,

        [Parameter(Mandatory = $false)]
        [System.Boolean]
        $EnableUpdate
    )

    if ($Ensure -eq "Absent") 
    {
        throw "Uninstallation is not supported by AppFabric Dsc"
    }

    Write-Verbose -Message "Getting details of installation of AppFabric Server"
    $matchPath = "HKEY_LOCAL_MACHINE\\$($Script:UninstallPath.Replace('\','\\'))" + `
                    "\\$script:InstallKeyPattern"
    $afsPath = Get-ChildItem -Path "HKLM:\$Script:UninstallPath" | Where-Object -FilterScript {
        $_.Name -match $matchPath
    }

    $localEnsure = "Absent"
    if($null -ne $afsPath)
    {
        $localEnsure = "Present"
    }
    
    return @{
        Ensure = $localEnsure
        Path = $Path
    }
}

<#
.SYNOPSIS

This function sets all Key properties defined in the resource schema file

.PARAMETER Ensure

This is The Ensure Set to 'present' to specificy that the product should be installed.

.PARAMETER Path

This is the full path of setup.exe

.PARAMETER Features

This is a list for the AppFabric Features that will be installed

.PARAMETER Gac

This is boolean for install all assemblies associated with the specified features into the Global Assembly Cache

.PARAMETER EnableUpdate

This is boolean that enable updates after AppFabric Server setup complete

#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,
        
        [Parameter(Mandatory = $false)]
        [System.String[]]
        [ValidateSet("hostingservices","hostingadmin","cachingservice","cacheclient","cacheadmin")]
        $Features,

        [Parameter(Mandatory = $false)]
        [System.Boolean]
        $Gac,

        [Parameter(Mandatory = $false)]
        [System.Boolean]
        $EnableUpdate
    )

    if ($Ensure -eq "Absent") 
    {
        throw "Uninstallation is not supported by AppFabric Dsc"
    }

    Write-Verbose -Message "Starting installation of AppFabric Server"
    # Create install arguments
    $arguments = "/Install "
    
    if ($Features)
    {
        foreach($feature in $Features)
        {
            if ($feature -eq $Features[-1])
            {
                 $arguments += $feature
            }
            else 
            {
                $arguments += $feature + ","
            }
        }
    }

    if ($Gac)
    {
        $arguments += " /GAC"
    }

    if ($EnableUpdate)
    {
        $arguments += " /EnableUpdates"
    }

    $installer = Start-Process -FilePath $Path `
                               -ArgumentList $arguments `
                               -Wait `
                               -PassThru

    switch ($installer.ExitCode) 
    {
        0 { 
            Write-Verbose -Message "Installation of AppFabric Server succeeded."
         }
        Default {
            throw ("AppFabric Server installation failed. Exit code " + `
                   "'$($installer.ExitCode)' was returned. Check " + `
                   "Event log in eventvwr for further information")
        }
    }
}

<#
.SYNOPSIS

This function tests all Key properties defined in the resource schema file

.PARAMETER Ensure

This is The Ensure Set to 'present' to specificy that the product should be installed.

.PARAMETER Path

This is the full path of setup.exe

.PARAMETER Features

This is a list for the AppFabric Features that will be installed

.PARAMETER Gac

This is boolean for install all assemblies associated with the specified features into the Global Assembly Cache

.PARAMETER EnableUpdate

This is boolean that enable updates after AppFabric Server setup complete

#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,
                
        [Parameter(Mandatory = $false)]
        [System.String[]]
        [ValidateSet("hostingservices","hostingadmin","cachingservice","cacheclient","cacheadmin")]
        $Features,

        [Parameter(Mandatory = $false)]
        [System.Boolean]
        $Gac,

        [Parameter(Mandatory = $false)]
        [System.Boolean]
        $EnableUpdate
    )

    if ($Ensure -eq "Absent") 
    {
        throw "Uninstallation is not supported by AppFabric Dsc"
    }
    
    Write-Verbose -Message "Testing for installation of AppFabric Server"

    $currentValues = Get-TargetResource @PSBoundParameters
    return Test-AFDscParameterState -CurrentValues $CurrentValues `
                                     -DesiredValues $PSBoundParameters `
                                     -ValuesToCheck @("Ensure")
}

Export-ModuleMember -Function *-TargetResource
