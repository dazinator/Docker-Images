$ErrorActionPreference = 'Stop'

Configuration BasicTools
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    node localhost
    {  
        Script NugetPackageProvider   
        {
            SetScript = {Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force}
            TestScript =  {if ((Get-PackageProvider -listavailable -name nuget -erroraction SilentlyContinue).Count -eq 0) {return $false} else {return $true}}
            GetScript = {@{Result = "true"}}       
        }
        Script ChocolateyPackageProvider   
        {
            SetScript = {Register-PackageSource -Name chocolatey -ProviderName Chocolatey -Location http://chocolatey.org/api/v2/ -force}
            TestScript =  {if ((Get-PackageProvider -listavailable -name Chocolatey -erroraction SilentlyContinue).Count -eq 0) {return $false} else {return $true}}
            GetScript = {@{Result = "true"}}       
        }        
        Script PSDscResources # this module is necessary as PSDesiredStateConfiguration has bugs and this module supercedes: https://github.com/PowerShell/DscResources/issues/235
        { 
            SetScript = {Install-Module PSDscResources}
            TestScript =  {if ((get-module PSDscResources -ListAvailable).Count -eq 0){return $false}else {return $true}}
            GetScript = {@{Result = "true"}}
            DependsOn = "[Script]NugetPackageProvider"
        }           
        Script NtfsAccessControl
        { 
            SetScript = {Install-Module cNtfsAccessControl}
            TestScript =  {if ((get-module cNtfsAccessControl -ListAvailable).Count -eq 0){return $false}else {return $true}}
            GetScript = {@{Result = "true"}}
            DependsOn = "[Script]NugetPackageProvider"
        }     
        Script PowershellModule
        { 
            SetScript = {Install-Module PowershellModule}
            TestScript =  {if ((get-module PowershellModule -ListAvailable).Count -eq 0){return $false}else {return $true}}
            GetScript = {@{Result = "true"}}
            DependsOn = "[Script]NugetPackageProvider"
        }     
    }
}

BasicTools

Start-DscConfiguration -Path .\BasicTools -Wait -verbose -Force