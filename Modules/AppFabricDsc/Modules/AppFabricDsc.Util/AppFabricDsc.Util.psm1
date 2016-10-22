<#
.SYNOPSIS

This cmdlet determines the version number of AppFabric that is installed locally

#>
function Get-AFDscInstalledProductVersion
{
    [CmdletBinding()]
    [OutputType([Version])]
    param()

    $uninstallPath = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*

    return $uninstallPath | `
        Select-Object DisplayName, DisplayVersion | `
        Where-Object {
            $_.DisplayName -match "AppFabric 1.1"
        } | ForEach-Object -Process {
            return [Version]::Parse($_.DisplayVersion)
        } | Select-Object -First 1
}

<#
.SYNOPSIS

This cmdlet determines the install path of AppFabric that is installed locally

#>
function Get-AFDscInstalledProductPath
{
    [CmdletBinding()]
    [OutputType([String])]
    param()

    $uninstallPath = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*

    return $uninstallPath | `
        Select-Object DisplayName, InstallLocation | `
        Where-Object {
            $_.DisplayName -match "AppFabric 1.1"
        } | ForEach-Object -Process {
            return $_.InstallLocation
        } | Select-Object -First 1
}

<#
.SYNOPSIS

This method is used to compare current and desired values for any DSC resource

.PARAMETER CurrentValues

This is hashtable of the current values that are applied to the resource

.PARAMETER DesiredValues 

This is a PSBoundParametersDictionary of the desired values for the resource

.PARAMETER ValuesToCheck

This is a list of which properties in the desired values list should be checkked.
If this is empty then all values in DesiredValues are checked.

#>
function Test-AFDscParameterState 
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]  
        [HashTable]
        $CurrentValues,
        
        [Parameter(Mandatory = $true)]  
        [Object]
        $DesiredValues,

        [Parameter(Mandatory = $false)] 
        [Array]
        $ValuesToCheck
    )

    $returnValue = $true

    if (($DesiredValues.GetType().Name -ne "HashTable") `
        -and ($DesiredValues.GetType().Name -ne "CimInstance") `
        -and ($DesiredValues.GetType().Name -ne "PSBoundParametersDictionary")) 
    {
        throw ("Property 'DesiredValues' in Test-SQLDscParameterState must be either a " + `
               "Hashtable or CimInstance. Type detected was $($DesiredValues.GetType().Name)")
    }

    if (($DesiredValues.GetType().Name -eq "CimInstance") -and ($null -eq $ValuesToCheck)) 
    {
        throw "If 'DesiredValues' is a CimInstance then property 'ValuesToCheck' must contain a value"
    }

    if (($null -eq $ValuesToCheck) -or ($ValuesToCheck.Count -lt 1)) 
    {
        $keyList = $DesiredValues.Keys
    } 
    else 
    {
        $keyList = $ValuesToCheck
    }

    $keyList | ForEach-Object -Process {
        if (($_ -ne "Verbose")) 
        {
            if (($CurrentValues.ContainsKey($_) -eq $false) `
            -or ($CurrentValues.$_ -ne $DesiredValues.$_) `
            -or (($DesiredValues.ContainsKey($_) -eq $true) -and ($DesiredValues.$_.GetType().IsArray))) 
            {
                if ($DesiredValues.GetType().Name -eq "HashTable" -or `
                    $DesiredValues.GetType().Name -eq "PSBoundParametersDictionary") 
                {
                    
                    $checkDesiredValue = $DesiredValues.ContainsKey($_)
                } 
                else 
                {
                    $checkDesiredValue = Test-SPDSCObjectHasProperty $DesiredValues $_
                }

                if ($checkDesiredValue) 
                {
                    $desiredType = $DesiredValues.$_.GetType()
                    $fieldName = $_
                    if ($desiredType.IsArray -eq $true) 
                    {
                        if (($CurrentValues.ContainsKey($fieldName) -eq $false) `
                        -or ($null -eq $CurrentValues.$fieldName)) 
                        {
                            Write-Verbose -Message ("Expected to find an array value for " + `
                                                    "property $fieldName in the current " + `
                                                    "values, but it was either not present or " + `
                                                    "was null. This has caused the test method " + `
                                                    "to return false.")
                            $returnValue = $false
                        } 
                        else 
                        {
                            $arrayCompare = Compare-Object -ReferenceObject $CurrentValues.$fieldName `
                                                           -DifferenceObject $DesiredValues.$fieldName
                            if ($null -ne $arrayCompare) 
                            {
                                Write-Verbose -Message ("Found an array for property $fieldName " + `
                                                        "in the current values, but this array " + `
                                                        "does not match the desired state. " + `
                                                        "Details of the changes are below.")
                                $arrayCompare | ForEach-Object -Process {
                                    Write-Verbose -Message "$($_.InputObject) - $($_.SideIndicator)"
                                }
                                $returnValue = $false
                            }
                        }
                    } 
                    else 
                    {
                        switch ($desiredType.Name) 
                        {
                            "String" {
                                if (-not [String]::IsNullOrEmpty($CurrentValues.$fieldName) -or `
                                    -not [String]::IsNullOrEmpty($DesiredValues.$fieldName))
                                {
                                    Write-Verbose -Message ("String value for property $fieldName does not match. " + `
                                                            "Current state is '$($CurrentValues.$fieldName)' " + `
                                                            "and Desired state is '$($DesiredValues.$fieldName)'")
                                    $returnValue = $false
                                }
                            }
                            "Int32" {
                                if (-not ($DesiredValues.$fieldName -eq 0) -or `
                                    -not ($null -eq $CurrentValues.$fieldName))
                                { 
                                    Write-Verbose -Message ("Int32 value for property " + "$fieldName does not match. " + `
                                                            "Current state is " + "'$($CurrentValues.$fieldName)' " + `
                                                            "and desired state is " + "'$($DesiredValues.$fieldName)'")
                                    $returnValue = $false
                                }
                            }
                            "Int16" {
                                if (-not ($DesiredValues.$fieldName -eq 0) -or `
                                    -not ($null -eq $CurrentValues.$fieldName))
                                { 
                                    Write-Verbose -Message ("Int32 value for property " + "$fieldName does not match. " + `
                                                            "Current state is " + "'$($CurrentValues.$fieldName)' " + `
                                                            "and desired state is " + "'$($DesiredValues.$fieldName)'")
                                    $returnValue = $false
                                }
                            }
                            default {
                                Write-Verbose -Message ("Unable to compare property $fieldName " + `
                                                        "as the type ($($desiredType.Name)) is " + `
                                                        "not handled by the " + `
                                                        "Test-SQLDscParameterState cmdlet")
                                $returnValue = $false
                            }
                        }
                    }
                }            
            }
        } 
    }
    return $returnValue
}

Export-ModuleMember -Function *
