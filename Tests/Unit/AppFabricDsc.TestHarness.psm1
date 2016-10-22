function Invoke-AFSDscUnitTestSuite() 
{
    param
    (
        [parameter(Mandatory = $false)]
        [System.String]
        $TestResultsFile,

        [parameter(Mandatory = $false)]
        [System.String]
        $DscTestsPath,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $CalculateTestCoverage = $true
    )

    Write-Verbose -Message "Commencing AppFabricDsc unit tests"

    $repoDir = Join-Path $PSScriptRoot "..\..\" -Resolve

    $testCoverageFiles = @()
    if ($CalculateTestCoverage -eq $true)
    {
        Write-Warning -Message ("Code coverage statistics are being calculated. This will slow the " + `
                                "start of the tests by several minutes while the code matrix is " + `
                                "built. Please be patient")
        Get-ChildItem "$repoDir\modules\AppFabricDsc\*.psm1" -Recurse | ForEach-Object -Process { 
            if ($_.FullName -notlike "*\DSCResource.Tests\*")
            {
                $testCoverageFiles += $_.FullName    
            }
        }    
    }
    
    $testResultSettings = @{ }
    if ([String]::IsNullOrEmpty($TestResultsFile) -eq $false)
    {
        $testResultSettings.Add("OutputFormat", "NUnitXml")
        $testResultSettings.Add("OutputFile", $TestResultsFile)
    }
    Import-Module "$repoDir\modules\AppFabricDsc\AppFabricDsc.psd1"
    Import-Module (Join-Path $repoDir "\Tests\Unit\Stubs\AppFabricServer.psm1") -WarningAction SilentlyContinue

    $testsToRun = @()
    $testsToRun += @(@{
        'Path' = (Join-Path -Path $repoDir -ChildPath "\Tests\Unit")
        'Parameters' = @{ 
            'AFSCmdletModule' = (Join-Path $repoDir "\Tests\Unit\Stubs\AppFabricServer.psm1")
        }
    })
    
    if ($PSBoundParameters.ContainsKey("DscTestsPath") -eq $true)
    {
        $testsToRun += @{
            'Path' = $DscTestsPath
            'Parameters' = @{ }
        }
    }
    $previousVerbosePreference = $Global:VerbosePreference 
    try
    {
        $Global:VerbosePreference = "SilentlyContinue"
        $results = Invoke-Pester -Script $testsToRun `
            -CodeCoverage $testCoverageFiles `
            -PassThru @testResultSettings    
    }
    finally
    {
        $Global:VerbosePreference = $previousVerbosePreference
    }
    
    return $results
}
