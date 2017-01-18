

# Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
<#
.SYNOPSIS 
Copy sharepoint users between groups
.DESCRIPTION 
Copy users in a Sharepoint group to another Sharepoint Group
.INPUTS 
  WebURL: site URL
  SourceGroupName: name of the source group
  TargetGroupName: name of the target group
.OUTPUTS 
 None
.EXAMPLE 
Copy-SPGroupToGroup -WebURL "https://foobar/" -SourceGroupName "VIPs" -TargetGroupName "Project Managers"
.NOTES 
 use Sitegroups in case group has not been granted permissions on the site
#>

Function Copy-SPGroupToGroup {
param(
[Parameter(Mandatory=$true,Position=2)]
[string]$WebURL,
[Parameter(Mandatory=$true,Position=0)]
[string]$SourceGroupName,
[Parameter(Mandatory=$true,Position=1)]
[string]$TargetGroupName
)

$web = Get-SPWeb $WebURL

if ($web -eq $null) {
  throw "$WebURL does not match a site or site collection"
}

#Get the Source and Target Groups

$SourceGroup = $web.Sitegroups | where {$_.name -eq $SourceGroupName }
$TargetGroup = $web.Sitegroups | where {$_.name -eq $TargetGroupName }

if ($SourceGroup -eq $null) {
    throw "SourceGroup $SourceGroupName not found"
} 

if ($TargetGroup -eq $null) {
    throw "Target Group $TargetGroupName not found"
} 

#Iterate through each users in the source group

    foreach ($user in $SourceGroup.users)

    {
       $TargetGroup.AddUser($user)
        Write-Verbose "Copied $user from $SourceGroup to $TargetGroup"
        #To move users, Just remove
        #$SourceGroup.RemoveUser($user)
    }

}

