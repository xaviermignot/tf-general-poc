<#
.SYNOPSIS
    Grant admin consent for App Registrations linked to App Services Easy Authentication
.DESCRIPTION
    This script is not designed to run in an automation context as it required Azure Ad administrator role activated.
    Manually run this script AS AN AZURE AS ADMIN after creating a new App Service to allow users to authenticate on environments
    where Easy Authentication is enabled.
#>

# List App Registrations matching the naming convention of App Services Easy Authentication used in Terraform code
az ad app list --all --query "[?starts_with(displayName, 'app') && ends_with(displayName, 'poc')].{appId:appId, displayName:displayName}" 
| ConvertFrom-Json
| ForEach-Object { 
    # For each App Registration, check if there is already a consent
    $existingConsent = az ad app permission list-grants --id $_.appId | ConvertFrom-Json
    if ($existingConsent.Count -gt 0) {
        Write-Host "Consent already granted for '$($_.displayName)' ($($_.appId))"
    }
    else {
        # If no existing consent, it is granted here
        Write-Host "Granting admin consent for '$($_.displayName)' ($($_.appId))..."
        az ad app permission admin-consent --id $_.appId 
    }
}
