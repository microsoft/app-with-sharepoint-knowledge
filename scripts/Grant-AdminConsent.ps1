<#
.SYNOPSIS
    Grants admin consent to the Azure AD application created by Bicep deployment.

.DESCRIPTION
    This script grants tenant-wide admin consent for all API permissions configured 
    in the Azure AD application. It retrieves the application's Client ID from the 
    azd environment and grants consent for:
    - Microsoft Graph: Files.Read.All, Sites.Read.All, Mail.Send, User.Read (delegated)
    - Azure Cognitive Services: user_impersonation (delegated)

.PARAMETER EnvironmentName
    The azd environment name. If not specified, uses the current active environment.

.EXAMPLE
    .\Grant-AdminConsent.ps1
    Grants admin consent using the current azd environment.

.EXAMPLE
    .\Grant-AdminConsent.ps1 -EnvironmentName "sample-environment-name"
    Grants admin consent for the specified environment.

.NOTES
    Requires:
    - Azure CLI (az) installed and authenticated
    - Global Administrator or Privileged Role Administrator role in Azure AD
    - Microsoft Graph PowerShell module (optional, uses Azure CLI if not available)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$EnvironmentName
)

$ErrorActionPreference = "Stop"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Get-AzdEnvironmentValue {
    param(
        [string]$Key
    )
    
    $envValues = azd env get-values
    foreach ($line in $envValues) {
        if ($line -match "^$Key=`"(.+)`"$") {
            return $matches[1]
        }
    }
    return $null
}

# Main script
Write-ColorOutput "=== Azure AD Application Admin Consent Script ===" "Cyan"
Write-Host ""

# Set environment if specified
if ($EnvironmentName) {
    Write-ColorOutput "Setting azd environment to: $EnvironmentName" "Yellow"
    azd env select $EnvironmentName
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "Failed to select environment. Please check the environment name." "Red"
        exit 1
    }
}

# Get the current environment name
$currentEnv = azd env list --output json | ConvertFrom-Json | Where-Object { $_.IsDefault -eq $true } | Select-Object -ExpandProperty Name
Write-ColorOutput "Using azd environment: $currentEnv" "Green"
Write-Host ""

# Retrieve the Client ID from azd environment
Write-ColorOutput "Retrieving application Client ID from azd environment..." "Yellow"
$clientId = Get-AzdEnvironmentValue -Key "AZURE_CLIENT_ID"

if ([string]::IsNullOrWhiteSpace($clientId)) {
    Write-ColorOutput "ERROR: AZURE_CLIENT_ID not found in azd environment." "Red"
    Write-ColorOutput "Please ensure the application has been deployed using 'azd up' or 'azd deploy'." "Red"
    exit 1
}

Write-ColorOutput "Found Client ID: $clientId" "Green"
Write-Host ""

# Check if user is logged in to Azure CLI
Write-ColorOutput "Checking Azure CLI authentication..." "Yellow"
$accountInfo = az account show 2>$null | ConvertFrom-Json
if (-not $accountInfo) {
    Write-ColorOutput "ERROR: Not logged in to Azure CLI. Please run 'az login' first." "Red"
    exit 1
}

Write-ColorOutput "Logged in as: $($accountInfo.user.name)" "Green"
Write-Host ""

# Get the service principal for the application
Write-ColorOutput "Looking up the application's service principal..." "Yellow"
$sp = az ad sp list --filter "appId eq '$clientId'" --query "[0]" | ConvertFrom-Json

if (-not $sp) {
    Write-ColorOutput "Service principal not found. Creating one..." "Yellow"
    $sp = az ad sp create --id $clientId | ConvertFrom-Json
    Write-ColorOutput "Service principal created successfully." "Green"
} else {
    Write-ColorOutput "Service principal found: $($sp.displayName)" "Green"
}
Write-Host ""

# Get all required resource accesses
Write-ColorOutput "Retrieving application's required permissions..." "Yellow"
$app = az ad app show --id $clientId | ConvertFrom-Json

if (-not $app.requiredResourceAccess -or $app.requiredResourceAccess.Count -eq 0) {
    Write-ColorOutput "No API permissions configured for this application." "Yellow"
    exit 0
}

Write-ColorOutput "Found $($app.requiredResourceAccess.Count) resource(s) with permissions configured." "Green"
Write-Host ""

# Display the permissions that will be granted
Write-ColorOutput "The following permissions will be granted:" "Cyan"
foreach ($resource in $app.requiredResourceAccess) {
    $resourceApp = az ad sp list --filter "appId eq '$($resource.resourceAppId)'" --query "[0]" | ConvertFrom-Json
    $resourceName = if ($resourceApp) { $resourceApp.displayName } else { $resource.resourceAppId }
    
    Write-Host "  Resource: $resourceName" -ForegroundColor White
    foreach ($access in $resource.resourceAccess) {
        $permissionType = if ($access.type -eq "Scope") { "Delegated" } else { "Application" }
        
        # Try to get the permission name
        $permissionName = $access.id
        if ($resourceApp) {
            if ($access.type -eq "Scope") {
                $permission = $resourceApp.oauth2PermissionScopes | Where-Object { $_.id -eq $access.id }
                if ($permission) { $permissionName = $permission.value }
            } else {
                $permission = $resourceApp.appRoles | Where-Object { $_.id -eq $access.id }
                if ($permission) { $permissionName = $permission.value }
            }
        }
        
        Write-Host "    - $permissionName ($permissionType)" -ForegroundColor Gray
    }
    Write-Host ""
}

# Confirm before proceeding
$confirmation = Read-Host "Do you want to grant admin consent for these permissions? (y/N)"
if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-ColorOutput "Admin consent cancelled." "Yellow"
    exit 0
}

Write-Host ""
Write-ColorOutput "Granting admin consent..." "Yellow"

# Grant admin consent using Azure CLI
try {
    # Use the Azure CLI to grant consent
    az ad app permission admin-consent --id $clientId
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-ColorOutput "✓ Admin consent granted successfully!" "Green"
        Write-Host ""
        Write-ColorOutput "The application '$($app.displayName)' now has admin consent for all requested permissions." "Green"
    } else {
        Write-ColorOutput "Failed to grant admin consent. You may need Global Administrator privileges." "Red"
        Write-Host ""
        Write-ColorOutput "Alternative: You can grant consent manually via the Azure Portal:" "Yellow"
        Write-ColorOutput "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/$clientId" "Cyan"
        exit 1
    }
} catch {
    Write-ColorOutput "ERROR: $($_.Exception.Message)" "Red"
    Write-Host ""
    Write-ColorOutput "You can grant consent manually via the Azure Portal:" "Yellow"
    Write-ColorOutput "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/$clientId" "Cyan"
    exit 1
}

Write-Host ""
Write-ColorOutput "Done!" "Cyan"
