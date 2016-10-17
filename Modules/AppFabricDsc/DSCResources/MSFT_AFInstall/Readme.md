**Description**

This resource is used to install the AppFabric Binaries. The Path parameter should point to the 
full path of AppFabric Cumulative Setup file, like 'C:\Softwares\WindowsServerAppFabricSetup_x64.exe'.
The Features parameter should contain the Specificy AppFabric Features that will be installed. The 
Gac parameter install all assemblies associated with the specified features into the Global Assembly Cache. 
The EnableUpdate parameter check for updates after AppFabric Server setup completes. This module depends 
on the NET-Framework-Core and Web-Server Windows Feature, which can be done through the use of WindowsFeature.
