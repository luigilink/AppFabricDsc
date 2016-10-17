$Script:DSCModuleName      = 'AppFabricDsc'
$Script:DSCResourceName    = 'MSFT_AFInstall' 

[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Script:DSCModuleName `
    -DSCResourceName $Script:DSCResourceName `
    -TestType Integration 

try
{
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

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Script:DSCResourceName).config.ps1"
    . $ConfigFile

    Describe "$($Script:DSCResourceName)_Integration" {
        $uninstallKey = 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\AppFabric'        
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($Script:DSCResourceName)_Config -OutputPath `$TestEnvironment.WorkingFolder"
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
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
