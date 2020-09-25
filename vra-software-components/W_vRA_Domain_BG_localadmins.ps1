##vRA Software Component Script to added the requestor's business group's respective Domain AD security group, to the local adminsrators group of the windows machine
#
# Configure the sc_vragb variable as a property in the vRA software component when you create it
#
#Ingest sc_vragb software component property to be used locally within script and set it to new variable#
set-variable -Name vrabg -value $sc_vragb
#
#Set NETBIOS domain name
set-variable -Name domain -value "Insert NETBIOS Domain here"
#Check if Business Group is already added to local administrators
$groupcheck = get-localgroupmember -group Administrators | where Name -eq $domain\$vrabg
#Write-Output $groupcheck
if ($groupcheck -like "$domain\$vrabg")
{ 
    Write-Output "$vrabg is already a member of local admins"
    exit 0
}
else
{
#begin adding business group to local admins if not already a member
Write-Output "Adding vRA Business group to Local Administrators"

Add-LocalGroupMember -Group Administrators -Member "$domain"\$vrabg
$groupvalidate = get-localgroupmember -group Administrators | where Name -eq $domain\$vrabg
#Uncomment below line to check if variable is being populated
#Write-Output $groupvalidate
if ($groupvalidate -like "$domain\$vrabg")
{
    Write-Output "Requestor "$groupvalidate" successfully added to local admins."
    exit 0
}
else
{
    Write-Output "Business group not added to local admins."
    exit 1
}
}