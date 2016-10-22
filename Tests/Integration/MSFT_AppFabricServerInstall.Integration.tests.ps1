$Script:DSCModuleName      = 'AppFabricDsc'
$Script:DSCResourceName    = 'MSFT_AFInstall'

#region HEADER
# Integration Test Template Version: 1.1.1
[String] $script:moduleRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Modules\$Script:DSCModuleName" -Resolve
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration

#endregion

# Using try/finally to always cleanup.
try
{
    #region Integration Tests   
    $webServerInstalled = (Get-WindowsFeature -Name Web-Server).Installed
    $aspDotNET35 = (Get-WindowsFeature -Name 'NET-Framework-Core').Installed
    Describe 'Environment' {
        Context 'Windows Features' {

            It 'Should have Web-Server installed' {
                $webServerInstalled | Should Be $true
            }

            It 'Should have NET-Framework-Core installed' {
                $aspDotNET35 | Should Be $true
            }
        }
    }

    if($webServerInstalled -eq $false -or $aspDotNET35 -eq $false)
    {
        break
    }
    
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    Describe "$($Script:DSCResourceName)_Integration" {
        $uninstallKey = 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\AppFabric'        
        It 'Should compile without throwing' {
            {
                & "$($script:DSCResourceName)_Config" -OutputPath $TestEnvironment.WorkingFolder
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $wacRegPathExist = Test-Path -Path $uninstallKey
            $wacRegPathExist | Should Be $true
        }
    }
    #endregion
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #endregion
}
