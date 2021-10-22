<#
.SYNOPSIS
    Enables or disables user assignment required for Service Principals associated to App Service
    Easy Authentication. 
.DESCRIPTION
    This script is not designed to run in an automation context as it required Azure Ad administrator role activated.
    Manually run this script AS AN AZURE AS ADMIN if you need to enable or disable user assignment required.
.EXAMPLE
    $ Set-ServicePrincipalAssignmentRequired.ps1 -AssignmentRequired $false
    Make user assignment not required

    $ Set-ServicePrincipalAssignmentRequired.ps1 -AssignmentRequired $true
    Make user assignment required
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [bool]
    $AssigmentRequired = $false
)

az ad sp list --all --query "[?starts_with(displayName, 'app') && ends_with(displayName, 'poc')].{appId:appId, displayName:displayName}" 
| ConvertFrom-Json
| ForEach-Object { 
    if ($_.appRoleAssignmentRequired -ne $AssigmentRequired) {
        Write-Host "$($AssigmentRequired ? "Enabling" : "Disabling") assignment required for '$($_.displayName)' ($($_.objectId))"
        az ad sp update --id $_.objectId --set appRoleAssignmentRequired=$AssigmentRequired
    }
    else {
        Write-Host "Assignment required already $($AssigmentRequired ? "enabled" : "disabled") for '$($_.displayName)' ($($_.objectId))"
    }
}
