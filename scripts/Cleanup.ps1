<#
.SYNOPSIS
    Deletes the Azure AD application and service principal created by Bicep deployment.

.DESCRIPTION
    This script removes the Azure AD application and its associated service principal
    from Azure Active Directory. It searches for applications with unique names 
    starting with 'spe-compliance-app' and allows you to select which ones to delete.

.PARAMETER EnvironmentName
    The azd environment name. If not specified, uses the current active environment.

.PARAMETER Force
    Skip confirmation prompts and force deletion (only works with single application).

.EXAMPLE
    .\Cleanup.ps1
    Searches for and deletes applications (with confirmation).

.EXAMPLE
    .\Cleanup.ps1 -EnvironmentName "pem-agent-20251114"
    Searches for applications in the specified environment.

.EXAMPLE
    .\Cleanup.ps1 -Force
    Deletes a single application without confirmation prompts.

.NOTES
    Requires:
    - Azure CLI (az) installed and authenticated
    - Application Administrator or Global Administrator role in Azure AD
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$EnvironmentName,

    [Parameter(Mandatory=$false)]
    [switch]$Force
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
Write-ColorOutput "=== Azure AD Application Cleanup Script ===" "Cyan"
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
$currentEnv = azd env list --output json 2>$null | ConvertFrom-Json | Where-Object { $_.IsDefault -eq $true } | Select-Object -ExpandProperty Name
if ($currentEnv) {
    Write-ColorOutput "Using azd environment: $currentEnv" "Green"
    Write-Host ""
}

# Search for applications by unique name
Write-ColorOutput "Searching for applications by unique name..." "Yellow"
Write-Host ""

# Get all applications and filter by uniqueName starting with "spe-compliance-app"
# Note: uniqueName is not directly filterable via OData, so we need to get all apps and filter client-side
$appsList = @()
$allAppsJson = az ad app list --output json 2>$null
if ($allAppsJson) {
    $allApps = $allAppsJson | ConvertFrom-Json
    # Filter for apps where uniqueName starts with "spe-compliance-app"
    # The uniqueName is stored in the identifierUris or we need to check the app's properties
    $appsList = $allApps | Where-Object { 
        $_.displayName -eq 'AI App with SharePoint Knowledge' -or
        ($_.identifierUris -and ($_.identifierUris | Where-Object { $_ -like "*spe-compliance-app*" }))
    }
}

if ($appsList.Count -eq 0) {
    Write-ColorOutput "No applications found with unique name starting with 'spe-compliance-app'." "Yellow"
    Write-ColorOutput "Nothing to clean up." "Green"
    exit 0
}

Write-ColorOutput "Found $($appsList.Count) application(s) matching 'spe-compliance-app':" "Green"
Write-Host ""

for ($i = 0; $i -lt $appsList.Count; $i++) {
    $currentApp = $appsList[$i]
    Write-Host "[$($i + 1)] $($currentApp.displayName)" -ForegroundColor White
    Write-Host "    Client ID: $($currentApp.appId)" -ForegroundColor Gray
    Write-Host "    Object ID: $($currentApp.id)" -ForegroundColor Gray
    
    # Display uniqueName if available
    if ($currentApp.uniqueName) {
        Write-Host "    Unique Name: $($currentApp.uniqueName)" -ForegroundColor Cyan
    }
    
    # Extract uniqueName from identifierUris if available
    if ($currentApp.identifierUris -and $currentApp.identifierUris.Count -gt 0) {
        $uniqueNameMatch = $currentApp.identifierUris | Where-Object { $_ -like "*spe-compliance-app*" } | Select-Object -First 1
        if ($uniqueNameMatch) {
            # Try to extract the uniqueName portion
            if ($uniqueNameMatch -match "spe-compliance-app[^/]*") {
                Write-Host "    Identifier: $($matches[0])" -ForegroundColor Gray
            }
        }
    }
    Write-Host ""
}

if ($appsList.Count -eq 1) {
    if (-not $Force) {
        $confirmation = Read-Host "Do you want to delete this application? (y/N)"
        if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
            Write-ColorOutput "Cleanup cancelled." "Yellow"
            exit 0
        }
    }
    $selectedApps = $appsList
} else {
    if ($Force) {
        Write-ColorOutput "ERROR: Multiple applications found. Cannot use -Force flag with multiple apps." "Red"
        Write-ColorOutput "Please select which application(s) to delete." "Yellow"
        exit 1
    }
    
    Write-Host "Which application(s) do you want to delete?" -ForegroundColor Cyan
    Write-Host "Enter numbers separated by commas (e.g., 1,3) or 'all' to delete all:" -ForegroundColor Cyan
    $selection = Read-Host
    
    if ($selection -eq 'all') {
        $selectedApps = $appsList
    } else {
        $indices = $selection -split ',' | ForEach-Object { $_.Trim() }
        $selectedApps = @()
        foreach ($index in $indices) {
            if ($index -match '^\d+$' -and [int]$index -ge 1 -and [int]$index -le $appsList.Count) {
                $selectedApps += $appsList[[int]$index - 1]
            } else {
                Write-ColorOutput "Invalid selection: $index" "Yellow"
            }
        }
    }
    
    if ($selectedApps.Count -eq 0) {
        Write-ColorOutput "No valid applications selected." "Yellow"
        exit 0
    }
    
    Write-Host ""
    Write-ColorOutput "Selected $($selectedApps.Count) application(s) for deletion:" "Cyan"
    foreach ($selectedApp in $selectedApps) {
        Write-Host "  - $($selectedApp.displayName) ($($selectedApp.appId))" -ForegroundColor White
    }
    Write-Host ""
    Write-ColorOutput "WARNING: This action cannot be undone!" "Red"
    $finalConfirm = Read-Host "Are you sure you want to delete these application(s)? (y/N)"
    if ($finalConfirm -ne 'y' -and $finalConfirm -ne 'Y') {
        Write-ColorOutput "Cleanup cancelled." "Yellow"
        exit 0
    }
}

# Delete selected applications
foreach ($selectedApp in $selectedApps) {
    Write-Host ""
    Write-ColorOutput "Processing: $($selectedApp.displayName)" "Cyan"
    
    # Get and delete service principal
    $sp = az ad sp list --filter "appId eq '$($selectedApp.appId)'" --query "[0]" 2>$null | ConvertFrom-Json
    if ($sp) {
        Write-ColorOutput "  Deleting service principal..." "Yellow"
        az ad sp delete --id $sp.id 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "  ✓ Service principal deleted" "Green"
        }
    }
    
    # Delete application
    Write-ColorOutput "  Deleting application..." "Yellow"
    az ad app delete --id $selectedApp.appId 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "  ✓ Application deleted" "Green"
    } else {
        Write-ColorOutput "  ✗ Failed to delete application" "Red"
    }
}

Write-Host ""
Write-ColorOutput "Cleanup completed!" "Cyan"
Write-Host ""
Write-ColorOutput "Note: The application may remain in a deleted state for 30 days." "Gray"
Write-ColorOutput "During this time, you can restore it from the Azure Portal under:" "Gray"
Write-ColorOutput "Azure AD > App registrations > Deleted applications" "Gray"
