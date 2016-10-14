$Script:UninstallPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$script:InstallKeyPattern = "AppFabric"

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [System.String]
        $Path,
                
        [parameter(Mandatory = $false)]
        [ValidateSet("hostingservices","hostingadmin","cachingservice","cacheclient","cacheadmin")]
        [System.String[]]
        $Features,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $Gac,

        [parameter(Mandatory = $false)]
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

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [System.String]
        $Path,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("hostingservices","hostingadmin","cachingservice","cacheclient","cacheadmin")]
        [System.String[]]
        $Features,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $Gac,

        [parameter(Mandatory = $false)]
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

    switch ($installer.ExitCode) {
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

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [System.String]
        $Path,
                
        [parameter(Mandatory = $false)]
        [ValidateSet("hostingservices","hostingadmin","cachingservice","cacheclient","cacheadmin")]
        [System.String[]]
        $Features,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $Gac,

        [parameter(Mandatory = $false)]
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
