[CmdletBinding()]
param(
    [String] $AFSCmdletModule = (Join-Path $PSScriptRoot "\Stubs\AppFabricServer.psm1" -Resolve)
)

$Script:DSCModuleName      = 'AppFabricDsc'
$Script:DSCResourceName    = 'MSFT_AFInstallCumulativeUpdate'
$Global:CurrentAFSCmdletModule = $AFSCmdletModule
$Global:AFInstalledPath = 'C:\Program Files\App Fabric Server\1.1 for Windows Server'

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
     InModuleScope $script:DSCResourceName {
            $testParams = @{
                Build = '1.0.4657.2'
                SetupFile  = "C:\SPAppFabricUpdate\AppFabric-KB3092423-x64-ENU.exe"
            }
        Describe "MSFT_AFInstallCumulativeUpdate tests [AppFabric server]" {           
            Import-Module (Join-Path $PSScriptRoot "..\..\Modules\AppFabricDsc" -Resolve)
            Import-Module $Global:CurrentAFSCmdletModule -WarningAction SilentlyContinue 

            Context "AppFabric Cumulative Update are not installed but should be" {
                Mock Get-AFDscInstalledProductPath { return $Global:AFInstalledPath }
                Mock Test-Path { return $false }
                Mock Get-ItemProperty { return @{
                    VersionInfo = [pscustomobject]@{
                        ProductVersion = '1.0.4639.0'
                        }
                    }
                }

                $result = Get-TargetResource @testParams

                It 'Should return the same values as passed as parameters' {
                    $result.SetupFile | Should Be $testParams.SetupFile
                }

                It "Should return 0.0.0.0 as the build version" {
                    $result.Build | Should Be '0.0.0.0'
                }

                It "Should return false from the test method"  {
                    Test-TargetResource @testParams | Should Be $false
                }
            }

            Context "AppFabric Cumulative Update are installed and should be" {
                Mock Get-AFDscInstalledProductPath { return $Global:AFInstalledPath }
                Mock Test-Path { return $true }
                Mock Get-ItemProperty { return @{
                    VersionInfo = [pscustomobject]@{
                        ProductVersion = $testParams.Build
                        }
                    }
                } 
                                
                $result = Get-TargetResource @testParams

                It 'Should return the same values as passed as parameters' {
                    $result.Build | Should Be $testParams.Build
                    $result.SetupFile | Should Be $testParams.SetupFile
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context "AppFabric Cumulative Update installation executes as expected" {
                Mock Get-AFDscInstalledProductPath { return $Global:AFInstalledPath }
                Mock Test-Path { return $true }
                Mock Get-ItemProperty { return @{
                    VersionInfo = [pscustomobject]@{
                        ProductVersion = '1.0.4639.0'
                        }
                    }
                } 
                Mock Start-Process { @{ ExitCode = 0 }}
                Mock Get-ItemProperty { return @{
                    VersionInfo = [pscustomobject]@{
                        ProductVersion = $testParams.Build
                        }
                    }
                }
                Set-TargetResource @testParams
                $getResults = Get-TargetResource @testParams

                It "AppFabric Cumulative Update installation Successfully" {
                    $getResults.Build | Should Be $testParams.Build
                }
            }

            Context "AppFabric Cumulative Update installation fails" {
                Mock Get-AFDscInstalledProductPath { return $Global:AFInstalledPath }
                Mock Test-Path { return $true }
                Mock Get-ItemProperty { return @{
                    VersionInfo = [pscustomobject]@{
                        ProductVersion = '1.0.4639.0'
                        }
                    }
                }
                Mock Start-Process { @{ ExitCode = -1 }}

                It "throws an exception on an unknown exit code" {
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
