<#
.SYNOPSIS

This function gets all Key properties defined in the resource schema file

.PARAMETER Build

This is the build number of the cumulative update used to check if already installed.

.PARAMETER SetupFile

This is the Full Path of the CU executable to launch

#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Build,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SetupFile
    )

    Write-Verbose -Message ("Getting AppFabric ProductVersion from " + `
                            "Microsoft.ApplicationServer.Caching.Configuration.dll")
    $getAFInstalledProductPath = Get-AFDscInstalledProductPath
    
    if ($getAFInstalledProductPath)
    {
        $afConfDLL = Join-Path -Path $getAFInstalledProductPath `
                            -ChildPath ("PowershellModules\DistributedCacheConfiguration\" + `
                                        "Microsoft.ApplicationServer.Caching.Configuration.dll")
        if(Test-Path -Path $afConfDLL)
        {
            $afInstall = (Get-ItemProperty -Path $afConfDLL -Name VersionInfo)
            $Build = $afInstall.VersionInfo.ProductVersion
        }
        else
        {
            Write-Verbose -Message 'AppFabric not installed'
            [Version]$Build = '0.0.0.0'
        }
    }
    else
    {
        throw [Exception] 'AppFabric must be installed before applying Cumulative Updates'
        [Version]$Build = '0.0.0.0'
    }    
    
    return @{
        Build = $Build
        SetupFile = $SetupFile
    }
}

<#
.SYNOPSIS

This function sets all Key properties defined in the resource schema file

.PARAMETER Build

This is the build number of the cumulative update used to check if already installed.

.PARAMETER SetupFile

This is the Full Path of the CU executable to launch

#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Build,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SetupFile
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues.Build)
    {
        throw [Exception] 'AppFabric must be installed before applying Cumulative Updates'
    }

    Write-Verbose -Message 'Beginning installation of AppFabric Cumulative Update'
    
    $setup = Start-Process -FilePath $SetupFile `
                           -ArgumentList "/quiet /passive /norestart" `
                           -Wait `
                           -PassThru

    if ($setup.ExitCode -eq 0) 
    {
        Write-Verbose -Message "AppFabric Cumulative Update installation complete"
            $pr1 = ("HKLM:\Software\Microsoft\Windows\CurrentVersion\" + `
                    "Component Based Servicing\RebootPending")
            $pr2 = ("HKLM:\Software\Microsoft\Windows\CurrentVersion\" + `
                    "WindowsUpdate\Auto Update\RebootRequired")
            $pr3 = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
            if (    ($null -ne (Get-Item $pr1 -ErrorAction SilentlyContinue)) `
                -or ($null -ne (Get-Item $pr2 -ErrorAction SilentlyContinue)) `
                -or ((Get-Item $pr3 | Get-ItemProperty).PendingFileRenameOperations.count -gt 0) `
                ) 
            {
                    
                Write-Verbose -Message ("xAFInstallCumulativeUpdate has detected the server has pending " + `
                                        "a reboot. Flagging to the DSC engine that the " + `
                                        "server should reboot before continuing.")
                $global:DSCMachineStatus = 1
            }
    }
    else
    {
        throw "SharePoint cumulative update install failed, exit code was $($setup.ExitCode)"
    }
}

<#
.SYNOPSIS

This function tests all Key properties defined in the resource schema file

.PARAMETER Build

This is the build number of the cumulative update used to check if already installed.

.PARAMETER SetupFile

This is the Full Path of the CU executable to launch

#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Build,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SetupFile
    )

    Write-Verbose -Message "Testing desired minium build number"
    $CurrentValues = Get-TargetResource @PSBoundParameters

    [Version]$DesiredBuild = $Build
    [Version]$ActualBuild = $CurrentValues.Build
    
    if ($ActualBuild -ge $DesiredBuild)
    {
        return $true
    }
    else
    {
        return $false
    }
}

Export-ModuleMember -Function *-TargetResource
