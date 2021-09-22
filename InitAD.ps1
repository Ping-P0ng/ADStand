$DomainName = "test.local"
$DomainNetbiosName = "TEST"
$SafeModeAdministratorPassword = "Qwerty12345"
###
#    Windows Server 2003: 2 or Win2003
#    Windows Server 2008: 3 or Win2008
#    Windows Server 2008 R2: 4 or Win2008R2
#    Windows Server 2012: 5 or Win2012
#    Windows Server 2012 R2: 6 or Win2012R2
#    Windows Server 2016: 7 or WinThreshold
###
$DomainMode = "WinThreshold"

Write-Host -ForegroundColor Green "DomainName: $($DomainName)"
Write-Host -ForegroundColor Green "DomainNetbiosName: $($DomainNetbiosName)"
Write-Host -ForegroundColor Green "SafeModeAdministratorPassword: $($SafeModeAdministratorPassword)"
Write-Host -ForegroundColor Green "DomainMode: $($DomainMode)"
Write-Host "-------------------------------------------------------"
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools;

Install-WindowsFeature -Name DNS -IncludeManagementTools;

Import-Module ADDSDeployment;

Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -DomainMode $DomainMode -DomainName $DomainName -DomainNetbiosName $DomainNetbiosName -ForestMode "WinThreshold" -InstallDns:$true -LogPath "C:\Windows\NTDS" -NoRebootOnCompletion:$false -SysvolPath "C:\Windows\SYSVOL" -Force:$true -SafeModeAdministratorPassword $(ConvertTo-SecureString $SafeModeAdministratorPassword -AsPlainText -Force);
Write-Host "-------------------------------------------------------"