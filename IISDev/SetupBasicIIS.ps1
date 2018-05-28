param(
    [Parameter(Mandatory = $true)]
    [string]$iisAdminUserName, 
    [Parameter(Mandatory = $true)]
    [securestring]$iisAdminUserPassword      
);

#==================
# Global Flags ====
$ErrorActionPreference = 'Stop'

Configuration BasicIIS
{
    param(
    [Parameter(Mandatory = $true)][PSCredential]$iisRemoteAdminUserCredential,
    [Parameter(Mandatory = $true)][string]$iisRemoteAdminUserName
    )

    Import-DscResource -ModuleName PSDscResources
    Import-DscResource -ModuleName PowershellModule
    #$securePassword = $iisRemoteAdminUserCredential.Password

    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($iisRemoteAdminUserCredential.Password)
    $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    node localhost
    {       
        WindowsFeature IIS 
        { 
            Ensure          = "Present" 
            Name            = "Web-Server" 
        } 
        WindowsFeature HTTPWCF
        {
            Ensure = "Present"
            Name = "net-wcf-http-Activation45"
        } 
        WindowsFeature Web-Http-Tracing
        {
            Ensure = "Present"
            Name = "Web-Http-Tracing"
        } 
        WindowsFeature Web-Request-Monitor
        {
            Ensure = "Present"
            Name = "Web-Request-Monitor"
        } 
        WindowsFeature Web-Mgmt-Service
        {
            Ensure = "Present"
            Name = "Web-Mgmt-Service"
        } 
        WindowsFeature Web-Health  # Health and Diagnostics
        {
            Name = "Web-Health"
            Ensure = "Present"
        }
        WindowsFeature Web-Http-Errors  # HTTP Errors
        {
             Name = "Web-Http-Errors"
             Ensure = "Present"
        }
        WindowsFeature Web-Http-Logging  # HTTP Logging
        {
             Name = "Web-Http-Logging"
             Ensure = "Present"
        }
        WindowsFeature Web-Http-Redirect  # HTTP Redirection
        {
            Name = "Web-Http-Redirect"
            Ensure = "Present"
        }
        WindowsFeature Web-Static-Content  # Static Content
        {
             Name = "Web-Static-Content"
            Ensure = "Present"
        }
        WindowsFeature Web-WebServer  # Web Server
        {
            Name = "Web-WebServer"
            Ensure = "Present"
        }
        # WindowsFeature Web-WMI  # IIS 6 WMI Compatibility
        # {
        #     Name = "Web-WMI"
        #     Ensure = "Absent"
        # }
        Service WebManagementService
        {    
            Name = "WMSVC"
            StartupType = "Automatic"
            State = "Running"
            DependsOn = "[WindowsFeature]IIS"
        }
        Registry RemoteManagement
        {
            Key = "HKLM:\SOFTWARE\Microsoft\WebManagement\Server"
            ValueName =  "EnableRemoteManagement"
            ValueData = 1
            ValueType = "Dword"
            DependsOn = "[WindowsFeature]Web-Mgmt-Service"
            Force=$true
        }
        # Group AdminGroupIncludeIisRemoteAdminUser
        # {
        #     # This removes TestGroup, if present
        #     # To create a new group, set Ensure to "Present“            
        #     Ensure = "Present"
        #     GroupName = "Administrators"
        #     MembersToInclude= "$iisRemoteAdminUserName"
        #     Credential = $iisRemoteAdminUserCredential
        #     DependsOn = "[Script]AddIisUser"
        # }   

        Script AddIisUserToAdminGroup # see https://github.com/PowerShell/PSDscResources/issues/99 and https://social.msdn.microsoft.com/Forums/en-US/e51acf07-8d85-467d-9d2c-fb07ddd482c7/newlocaluser-with-securestring-password-throws-cryptographicexception-the-system-cannot-find-the?forum=windowscontainers
        { 
            SetScript = {net localgroup administrators $using:iisRemoteAdminUserName /add}
            TestScript =  {if ((net localgroup administrators | Select-String "$using:iisRemoteAdminUserName" -SimpleMatch) -eq $null){return $false}else {return $true}}
            GetScript = {@{Result = "true"}}  
            DependsOn = "[Script]AddIisUser"          
        }   
        
        Script AddIisUser # see https://github.com/PowerShell/PSDscResources/issues/99 and https://social.msdn.microsoft.com/Forums/en-US/e51acf07-8d85-467d-9d2c-fb07ddd482c7/newlocaluser-with-securestring-password-throws-cryptographicexception-the-system-cannot-find-the?forum=windowscontainers
        { 
            SetScript = {net user /add $using:iisRemoteAdminUserName $using:UnsecurePassword}
            TestScript =  {try 
                {  
                   return (Get-LocalUser $using:iisRemoteAdminUserName).Count -eq 1 
                } catch {
                   return $false  
                }}
            GetScript = {@{Result = "true"}}            
        }   

        # Script AddIisUser # see https://github.com/PowerShell/PSDscResources/issues/99 and https://social.msdn.microsoft.com/Forums/en-US/e51acf07-8d85-467d-9d2c-fb07ddd482c7/newlocaluser-with-securestring-password-throws-cryptographicexception-the-system-cannot-find-the?forum=windowscontainers
        # { 
        #     SetScript = {New-LocalUser $using:iisRemoteAdminUserName -Password $using:securePassword -FullName "$using:iisRemoteAdminUserName" -Description "IIS Remote Administrator."}
        #     TestScript =  {try 
        #         {  
        #            return (Get-LocalUser $using:iisRemoteAdminUserName).Count -eq 1 
        #         } catch {
        #            return $false  
        #         }}
        #     GetScript = {@{Result = "true"}}            
        # }     
        # User IisRemoteAdminUser # User for remote IIS administration
        # {
        #     Ensure = "Present"  
        #     UserName = $iisRemoteAdminUserName
        #     Password = $iisRemoteAdminUserCredential # This needs to be a credential object           
        # }   
        PSModuleResource xWebAdministration
        {
            Ensure='Present'
            Module_Name = 'xWebAdministration'
          #  DependsOn = "[Script]NugetPackageProvider"
        }      
        # Script xWebAdministration
        # { 
        #     SetScript = {Install-Module xWebAdministration}
        #     TestScript =  {if ((get-module xwebadminstration -ListAvailable).Count -eq 0){return $false}else {return $true}}
        #     GetScript = {@{Result = "true"}}           
        # }    
        # WindowsFeature WindowsDefenderFeatures
        # {
        #     Ensure = "Absent"
        #     Name = "Windows-Defender-Features"
        #     IncludeAllSubFeature = $true
        # }      
         
    }
}



#$iisRemoteAdminUserName = "IISRemoteAdmin"
# $secUserPassword = ConvertTo-SecureString "IISRemoteAdmin" -AsPlainText -Force
# $userCreds = New-Object System.Management.Automation.PSCredential ($iisRemoteAdminUserName, $secUserPassword)

$userCreds = New-Object System.Management.Automation.PSCredential ($iisAdminUserName, $iisAdminUserPassword)
# New-LocalUser $iisRemoteAdminUserName -Password $userCreds.Password -FullName "$iisRemoteAdminUserName" -Description "IIS Remote Administrator."


$cd = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDscAllowPlainTextPassword = $true
        }
    )
}

BasicIIS -iisRemoteAdminUserCredential $userCreds -iisRemoteAdminUserName $iisAdminUserName -ConfigurationData $cd

Start-DscConfiguration -Path .\BasicIIS -Wait -verbose -Force