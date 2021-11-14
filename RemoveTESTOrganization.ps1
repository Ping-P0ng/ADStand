$OrganizationalUnitList = @("Accounting Department","HR Department","IT Department","Legal Department","Finance Department","Marketing Department","ServiceUsers")


foreach($CureentOrganizationalUnit in $OrganizationalUnitList)
{
    try
    {
        $ou = Get-ADOrganizationalUnit -Identity "OU=$($CureentOrganizationalUnit),DC=test,DC=local" 
        Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion $false -Identity $ou
        Remove-ADOrganizationalUnit -Identity $ou -Recursive -Confirm:$False
        Write-Host -ForegroundColor Green "OU=$($CureentOrganizationalUnit),DC=test,DC=local"
    }
    catch
    {
        Write-Host -ForegroundColor Red "OU=$($CureentOrganizationalUnit),DC=test,DC=local"
    }
}