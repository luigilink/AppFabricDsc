[CmdletBinding()]
param(
    [String] $AFSCmdletModule = (Join-Path $PSScriptRoot "\Stubs\AppFabricServer.psm1" -Resolve)
)

$Script:DSCModuleName      = 'AppFabricDsc'
$Script:DSCResourceName    = 'MSFT_AFInstall'
$Global:CurrentAFSCmdletModule = $AFSCmdletModule

#region HEADER

# Unit Test Template Version: 1.2.0
[String] $script:moduleRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Modules\$Script:DSCModuleName" -Resolve
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Script:DSCModuleName `
    -DSCResourceName $Script:DSCResourceName `
    -TestType Unit 

#endregion HEADER

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    InModuleScope $Script:DSCResourceName {
        Describe "MSFT_AFInstall tests [AppFabric server]" {

            Import-Module (Join-Path $PSScriptRoot "..\..\Modules\AppFabricDsc" -Resolve)
            Import-Module $Global:CurrentAFSCmdletModule -WarningAction SilentlyContinue 

            Context "AppFabric server is not installed, but should be" {
                $testParams = @{
                    Ensure = "Present"
                    Path = "C:\Softwares\WindowsServerAppFabricSetup_x64.exe"
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @()
                }
                Mock -CommandName Start-Process -MockWith {
                    return @{
                        ExitCode = 0
                    }
                }

                It "Returns that it is not installed from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }

                It "Returns false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Starts the install from the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Start-Process
                }
            }

            Context "AppFabric server is installed and should be" {
                $testParams = @{
                    Ensure = "Present"
                    Path = "C:\Softwares\WindowsServerAppFabricSetup_x64.exe"
                }

                Mock Get-ChildItem -MockWith {
                    return @(
                        @{
                            Name = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\AppFabric"
                        }
                    )
                }

                It "Returns that it is installed from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }

                It "Returns true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context "AppFabric server is not installed, but should be" {
                $testParams = @{
                    Ensure = "Present"
                    Path = "C:\Softwares\WindowsServerAppFabricSetup_x64.exe"
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @()
                }
                Mock -CommandName Start-Process -MockWith {
                    return @{
                        ExitCode = 1001
                    }
                }

                It "Starts the install from the set method" {
                    { Set-TargetResource @testParams } | Should Throw
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
