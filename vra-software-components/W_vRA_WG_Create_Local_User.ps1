##vRA Software Component Script to create a new local user and add to local admins

#set-variable -Name user -value $localuser
#set-variable -Name pw -value $localpw
$securepw = ConvertTo-SecureString -String $localpw -AsPlainText -Force
New-LocalUser "$localuser" -Password $securepw -Fullname "$localuser"
#Check if User is already added to local administrators
$groupcheck = get-localgroupmember -group Administrators | where Name -eq $env:COMPUTERNAME\$localuser
#Write-Output $groupcheck
if ($groupcheck -like "$env:COMPUTERNAME\$localuser")
{ 
    Write-Output "$localuser is already a member of local admins"
    exit 0
}
else
{
#begin adding business group to local admins if not already a member
Write-Output "Adding $localuser to Local Administrators"

Add-LocalGroupMember -Group Administrators -Member $localuser
$groupvalidate = get-localgroupmember -group Administrators | where Name -eq $env:COMPUTERNAME\$localuser
#Uncomment below line to check if variable is being populated
#Write-Output $groupvalidate
if ($groupvalidate -like "$env:COMPUTERNAME\$localuser")
{
    Write-Output "Local User "$groupvalidate" successfully added to local admins."
    exit 0
}
else
{
    Write-Output "$localuser not added to local admins."
    exit 1
}
}