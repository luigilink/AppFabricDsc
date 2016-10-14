
$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$script:DSCModuleName      = 'AppFabricDsc'
$script:DSCResourceName    = 'MSFT_AFInstallCumulativeUpdate'

#region HEADER

# Unit Test Template Version: 1.1.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit 

#endregion HEADER

# Begin Testing
try
{
    Describe "AFInstallCumulativeUpdate - AppFabric Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
        InModuleScope $ModuleName {
            $testParams = @{
                Build = '1.0.4657.2'
                SetupFile  = "C:\SPAppFabricUpdate\AppFabric-KB3092423-x64-ENU.exe"
            }
            
            Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
            
            Mock Invoke-SPDSCCommand { 
                return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
            }
            
            Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
            Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

            Context "AppFabric Cumulative Update are not installed but should be" {
                Mock Test-Path { return $false }
                Mock Get-ItemProperty { return @{
                    VersionInfo = [pscustomobject]@{
                        ProductVersion = '1.0.4639.0'
                        }
                    }
                } 

                It "returns false from the test method"  {
                    Test-TargetResource @testParams | Should Be $false
                }
            }

            Context "AppFabric Cumulative Update are installed and should be" {
                Mock Test-Path { return $true }
                Mock Get-ItemProperty { return @{
                    VersionInfo = [pscustomobject]@{
                        ProductVersion = $testParams.Build
                        }
                    }
                } 
                
                It "returns true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context "AppFabric Cumulative Update installation executes as expected" {
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
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment 

    #endregion
}

