$ErrorActionPreference = 'Stop'

$secUserPassword = ConvertTo-SecureString "Passw0rd#1" -AsPlainText -Force
$iisAdminUserName = "DnnRemoteAdmin"

. ./SetupBasicTools.ps1

New-Item -Path c:\Sites -ItemType directory
. ./SetupBasicIIS.ps1 -iisAdminUserName $iisAdminUserName -iisAdminUserPassword $secUserPassword