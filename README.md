# AppFabricDsc

Build status: [![Build status](https://ci.appveyor.com/api/projects/status/baacdt4ll6mly9mp/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/AppFabricDsc/branch/master)

The **AppFabricDsc** module contains DSC resources for deployment and configuration of AppFabric in a way that is fully compliant with the requirements of System Center.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Contributing
The AppFabricDsc PowerShell module provides DSC resources that can be used to deploy and configure AddFabric product. 

Please leave comments, feature requests, and bug reports in the issues tab for this module.

If you would like to modify AppFabricDsc module, please feel free.  
As specified in the license, you may copy or modify this resource as long as they are used on the Windows Platform.
Please refer to the [Contribution Guidelines](https://github.com/luigilink/AppFabricDsc/wiki/Contributing) for information about style guides, testing and patterns for contributing to DSC resources.

## Installation

To manually install the module, download the source code and unzip the contents of the \Modules\AppFabricDsc directory to the $env:ProgramFiles\WindowsPowerShell\Modules folder 

To install from the PowerShell gallery using PowerShellGet (in PowerShell 5.0) run the following command:

    Find-Module -Name AppFabricDsc -Repository PSGallery | Install-Module

To confirm installation, run the below command and ensure you see the SharePoint DSC resoures available:

    Get-DscResource -Module AppFabricDsc

## Requirements 

The minimum PowerShell version required is 4.0, which ships in Windows 8.1 or Windows Server 2012R2 (or higher versions).
The preferred version is PowerShell 5.0 or higher, which ships with Windows 10 or Windows Server 2016. 
This is discussed [on the AppFabricDsc wiki](https://github.com/PowerShell/AppFabricDsc/wiki/Remote%20sessions%20and%20the%20InstallAccount%20variable), but generally PowerShell 5 will run the SharePoint DSC resources faster and with improved verbose level logging.

## Documentation and examples

For a full list of resources in AppFabricDsc and examples on their use, check out the [AppFabricDsc wiki](https://github.com/PowerShell/AppFabricDsc/wiki).
You can also review the "examples" directory in the AppFabricDsc module for some general use scenarios for all of the resources that are in the module.

## Changelog

A full list of changes in each version can be found in the [change log](CHANGELOG.md)
