$UserNameListPath = ".\UserNameList.txt"
$CountUser = 100
$OrganizationalUnitList = @("Accounting Department","HR Department","IT Department","Legal Department","Finance Department","Marketing Department")
$PCList = @("W10","XP","W7","W8")
$GroupList = @("Internet Access","Local Users","DB Access","Regional Admin")

foreach($CureentOrganizationalUnit in $OrganizationalUnitList)
{
    try
    {
        New-ADOrganizationalUnit -Name $CureentOrganizationalUnit -Path "DC=test,DC=local"
        Write-Host -ForegroundColor Green "Add: OU=$($CureentOrganizationalUnit),DC=test,DC=local"
        New-ADOrganizationalUnit -Name "Users" -Path "OU=$($CureentOrganizationalUnit),DC=test,DC=local"
        Write-Host -ForegroundColor Green "Add: OU=Users,OU=$($CureentOrganizationalUnit),DC=test,DC=local"
        New-ADOrganizationalUnit -Name "Groups" -Path "OU=$($CureentOrganizationalUnit),DC=test,DC=local"
        Write-Host -ForegroundColor Green "Add: OU=Groups,OU=$($CureentOrganizationalUnit),DC=test,DC=local"
        New-ADOrganizationalUnit -Name "Computers" -Path "OU=$($CureentOrganizationalUnit),DC=test,DC=local"
        Write-Host -ForegroundColor Green "Add: OU=Computers,OU=$($CureentOrganizationalUnit),DC=test,DC=local"
    }
    catch
    {
        Write-Host -ForegroundColor Red "Fail: OU=$($CureentOrganizationalUnit),DC=test,DC=local"
    }
}

##### Test Organization #####

$CheckUserNameList = Test-Path $UserNameListPath -PathType Leaf
if($CheckUserNameList -eq $true)
{
    $ArrayUserNameList = @()
    $RawUserNameList = Get-Content $UserNameListPath 
    Write-Host "Open $($UserNameListPath)" -ForegroundColor Green
    foreach($Line in $RawUserNameList)
    {
        $ArrayUserNameList += $Line
    }
    foreach($CureentOrganizationalUnit in $OrganizationalUnitList)
    {
        $GlobalGroup = "$($CureentOrganizationalUnit) Group"
        try
        {
            
            New-ADGroup -Name $GlobalGroup -SamAccountName $GlobalGroup -GroupCategory Security -GroupScope Global -DisplayName $GlobalGroup -Path "OU=Groups,OU=$($CureentOrganizationalUnit),DC=test,DC=local" -Description $GlobalGroup
            Write-Host "Success add group: CN=$($GlobalGroup),OU=Groups,OU=$($CureentOrganizationalUnit),DC=test,DC=local" -ForegroundColor Green
        }
        catch
        {
            Write-Host "Fail add group: CN=$($GlobalGroup),OU=Groups,OU=$($CureentOrganizationalUnit),DC=test,DC=local" -ForegroundColor Red   
        }
        for($i = 1;$i -le $CountUser;$i++)
        {
            $RandomNumbers = Get-Random -InputObject (0..$ArrayUserNameList.Length) -Count 2
            $RandomPass = Get-Random -InputObject (10000..99999) -Count 1
            $DisplayName = "$($ArrayUserNameList[$RandomNumbers[0]]) $($ArrayUserNameList[$RandomNumbers[1]])"
            $SamAccountName = "$($ArrayUserNameList[$RandomNumbers[0]]).$($ArrayUserNameList[$RandomNumbers[1]])"
            try
            {
                New-ADUser -Name $DisplayName -Path "OU=Users,OU=$($CureentOrganizationalUnit),DC=test,DC=local" -AccountPassword $(ConvertTo-SecureString "Qwerty$($RandomPass)" -AsPlainText -Force) -Company "Test Corp." -Organization "Narnia" -Department $CureentOrganizationalUnit -Description "$($CureentOrganizationalUnit) - $($DisplayName)" -DisplayName $DisplayName -EmailAddress "$($SamAccountName)@test.local" -Enabled $True -OfficePhone "+66666666" -PasswordNeverExpires $True -SamAccountName $SamAccountName
                Add-ADGroupMember -Identity $GlobalGroup -Members $SamAccountName
                Write-Host "Success add user: CN=$($DisplayName),OU=Users,OU=$($CureentOrganizationalUnit),DC=test,DC=local" -ForegroundColor Green
                $ComputerName = "TEST$($PCList | Get-Random)$(Get-Random -InputObject (100000..999999) -Count 1)"
                New-ADComputer -Name "$($ComputerName) ($($DisplayName))" -SamAccountName $ComputerName -Path "OU=Computers,OU=$($CureentOrganizationalUnit),DC=test,DC=local" -Description $DisplayName -Enabled $True -Location "Narnia" 
                Write-Host "Success add computer: CN=$($ComputerName),OU=Computers,OU=$($CureentOrganizationalUnit),DC=test,DC=local" -ForegroundColor Green
            }
            catch
            {
                Write-Host "Fail add user: CN=$($DisplayName),OU=Users,OU=$($CureentOrganizationalUnit),DC=test,DC=local" -ForegroundColor Red
            }
        }
        foreach($CurrentGroup  in $GroupList)
        {
            $CurrentGroup = "$($CurrentGroup) $($CureentOrganizationalUnit.Split(' ')[0])"
            try
            {
                New-ADGroup -Name $CurrentGroup -SamAccountName $CurrentGroup -GroupCategory Security -GroupScope Global -DisplayName $CurrentGroup -Path "OU=Groups,OU=$($CureentOrganizationalUnit),DC=test,DC=local" -Description $CurrentGroup
                Write-Host "Success add group: CN=$($CurrentGroup),OU=Groups,OU=$($CureentOrganizationalUnit),DC=test,DC=local" -ForegroundColor Green
            }
            catch
            {
                Write-Host "Fail add group: CN=$($CurrentGroup),OU=Groups,OU=$($CureentOrganizationalUnit),DC=test,DC=local" -ForegroundColor Red   
            }
            $OUUsersList = Get-ADUser -SearchBase "OU=Users,OU=$($CureentOrganizationalUnit),DC=test,DC=local" -Filter *
            
            foreach($CurrentUser in $OUUsersList | Get-Random -Count $([int]($CountUser/$GroupList.Length)))
            {
                Add-ADGroupMember -Identity $CurrentGroup -Members $CurrentUser
            }
        }
    }
}
else
{
    Write-Host "File $($UserNameListPath) not found" -ForegroundColor Red
}

##### SPN Users #####
try
{
    New-ADOrganizationalUnit -Name "ServiceUsers" -Path "DC=test,DC=local"
    Write-Host -ForegroundColor Green "Add: OU=ServiceUsers,DC=test,DC=local"
    try
    {
        New-ADUser -Name "Service DB" -Path "OU=ServiceUsers,DC=test,DC=local" -AccountPassword $(ConvertTo-SecureString "Qwerty$(Get-Random -InputObject (10000..99999) -Count 1)" -AsPlainText -Force) -Company "Test Corp." -Organization "Narnia" -Department "Service Account" -Description "Service Account" -DisplayName "Service DB" -Enabled $True -PasswordNeverExpires $True -SamAccountName "ServiceDB"
        Set-ADUser -Identity "ServiceDB" -ServicePrincipalNames @{Add='MSSQLSvc/SQLSERVER.test.local:1433'}
        Write-Host -ForegroundColor Green "Add SPN: ServiceDB > MSSQLSvc/SQLSERVER.test.local:1433"
    }
    catch
    {
        Write-Host -ForegroundColor Red "Fail add ServiceDB user"
    }
    try
    {
        New-ADUser -Name "Service WEB" -Path "OU=ServiceUsers,DC=test,DC=local" -AccountPassword $(ConvertTo-SecureString "Qwerty$(Get-Random -InputObject (10000..99999) -Count 1)" -AsPlainText -Force) -Company "Test Corp." -Organization "Narnia" -Department "Service Account" -Description "Service Account" -DisplayName "Service WEB" -Enabled $True -PasswordNeverExpires $True -SamAccountName "ServiceWEB"
        Set-ADUser -Identity "ServiceWEB" -ServicePrincipalNames @{Add='HTTP/WEBSERVER.test.local'}
        Write-Host -ForegroundColor Green "Add SPN: ServiceWEB > HTTP/WEBSERVER.test.local"
    }
    catch
    {
        Write-Host -ForegroundColor Red "Fail add ServiceWEB user"
    }
}
catch
{
    Write-Host -ForegroundColor Red "Fail: OU=ServiceUsers,DC=test,DC=local"
}


##### AS-REP roasting #####
try
{
    New-ADUser -Name "OldUser" -Path "OU=ServiceUsers,DC=test,DC=local" -AccountPassword $(ConvertTo-SecureString "Qwerty$(Get-Random -InputObject (10000..99999) -Count 1)" -AsPlainText -Force) -Company "Test Corp." -Organization "Narnia" -Department "Service Account" -Description "Service Account" -DisplayName "OldUser" -Enabled $True -PasswordNeverExpires $True -SamAccountName "OldUser"
    Set-ADAccountControl -Identity "OldUser"  -doesnotrequirepreauth $true
    Write-Host -ForegroundColor Green "Add doesnotrequirepreauth user: OldUser"
}
catch
{
    Write-Host -ForegroundColor Red "Fail add OldUser user"
}
try
{
    New-ADUser -Name "VeryOldUser" -Path "OU=ServiceUsers,DC=test,DC=local" -AccountPassword $(ConvertTo-SecureString "Qwerty$(Get-Random -InputObject (10000..99999) -Count 1)" -AsPlainText -Force) -Company "Test Corp." -Organization "Narnia" -Department "Service Account" -Description "Service Account" -DisplayName "VeryOldUser" -Enabled $True -PasswordNeverExpires $True -SamAccountName "VeryOldUser"
    Set-ADAccountControl -Identity "VeryOldUser"  -Doesnotrequirepreauth $true
    Write-Host -ForegroundColor Green "Add doesnotrequirepreauth user: VeryOldUser"
}
catch
{
    Write-Host -ForegroundColor Red "Fail add VeryOldUser user"
}