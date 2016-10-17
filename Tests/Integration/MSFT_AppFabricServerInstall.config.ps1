configuration MSFT_AppFabricServerInstall_config {
    Import-DscResource -ModuleName 'AppFabricDsc'
    node localhost {
        AFInstall Integration_Test
        {
            Ensure = 'Present'
            Path = "C:\Softwares\WindowsServerAppFabricSetup_x64.exe"
            Features = "hostingservices","hostingadmin"
            EnableUpdate = $true
        }
    }
}
