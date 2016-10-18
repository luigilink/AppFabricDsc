<#
.EXAMPLE
    This module will install AppFabric 1.1 Server. The binaries for
    AppFabric server in this scenario are stored in C:\Softwares.
    The prerequesites of AppFabric are "NET-Framework-Core" Features
    and "Web-Server" IIS server role.
#>

Configuration Example 
{
    param()
    Import-DscResource -ModuleName AppFabricDsc

    node localhost {
        #**********************************************************
        # AppFabric Server Installation
        #
        # This section of the AppFabric Server Installation includes
        # details of the installation and configuration.
        #********************************************************** 
        # .net 3.5 pre requisite for AppFabric
        WindowsFeature DotNetFramework3dot5
        {
            Ensure = 'Present'
            Name = 'NET-Framework-Core'
        }
        # IIS server role pre requisite for AppFabric
        WindowsFeature InstallWebServer
        {
            Name = "Web-Server"
            Ensure = "Present"
        }
        AFInstall MIDDLEWARE_AppFabric_Install
        {
            Ensure = 'Present'
            Path = "C:\Softwares\WindowsServerAppFabricSetup_x64.exe"
            Features = "hostingservices","hostingadmin"
            EnableUpdate = $true
        }
    }
}
