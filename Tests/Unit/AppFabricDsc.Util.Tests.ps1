[CmdletBinding()]
param(
    [String] $AFSCmdletModule = (Join-Path $PSScriptRoot "\Stubs\AppFabricServer.psm1" -Resolve)
)

$Global:CurrentAFSCmdletModule = $AFSCmdletModule

[String] $moduleRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Modules\AppFabricDsc" -Resolve
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path $PSScriptRoot "..\..\Modules\AppFabricDsc\Modules\AppFabricDsc.Util\AppFabricDsc.Util.psm1" -Resolve)

InModuleScope "AppFabricDsc.Util" {
    Describe "AppFabricDsc.Util tests [AppFabric server]" {

        Import-Module $Global:CurrentAFSCmdletModule -WarningAction SilentlyContinue 

        Context "Validate Test-AFDscParameterState" {
            It "Returns true for two identical tables" {
                $desired = @{ Example = "test" }
                Test-AFDscParameterState -CurrentValues $desired -DesiredValues $desired | Should Be $true
            }

            It "Returns false when a value is different" {
                $current = @{ Example = "something" }
                $desired = @{ Example = "test" }
                Test-AFDscParameterState -CurrentValues $current -DesiredValues $desired | Should Be $false
            }

            It "Returns false when a value is missing" {
                $current = @{ }
                $desired = @{ Example = "test" }
                Test-AFDscParameterState -CurrentValues $current -DesiredValues $desired | Should Be $false
            }

            It "Returns true when only a specified value matches, but other non-listed values do not" {
                $current = @{ Example = "test"; SecondExample = "true" }
                $desired = @{ Example = "test"; SecondExample = "false"  }
                Test-AFDscParameterState -CurrentValues $current -DesiredValues $desired -ValuesToCheck @("Example") | Should Be $true
            }

            It "Returns false when only specified values do not match, but other non-listed values do " {
                $current = @{ Example = "test"; SecondExample = "true" }
                $desired = @{ Example = "test"; SecondExample = "false"  }
                Test-AFDscParameterState -CurrentValues $current -DesiredValues $desired -ValuesToCheck @("SecondExample") | Should Be $false
            }

            It "Returns false when an empty array is used in the current values" {
                $current = @{ }
                $desired = @{ Example = "test"; SecondExample = "false"  }
                Test-AFDscParameterState -CurrentValues $current -DesiredValues $desired | Should Be $false
            }
        }
    }
}
