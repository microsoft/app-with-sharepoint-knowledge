# SPE Compliance Agent - Web Application

An AI-powered compliance checking application for SharePoint documents that uses Azure OpenAI Service and Microsoft Graph.

## Features

- **Web Interface**: User-friendly web interface with Azure AD authentication
- **Delegated Authentication**: Uses Microsoft Identity Web for secure user authentication
- **Microsoft Graph Integration**: Retrieves documents and sends notifications using user's delegated permissions
- **AI-Powered Analysis**: Uses Azure OpenAI to analyze compliance violations
- **Email Notifications**: Automatically sends findings to document authors

## Prerequisites

- Azure subscription
- Azure AD tenant
- Azure App Registration with appropriate permissions
- .NET 8.0 SDK
- Azure Developer CLI (azd)

## Azure App Registration Setup

Your Azure App Registration needs the following permissions:

### API Permissions
- **Microsoft Graph**:
  - `Files.Read.All` (Delegated)
  - `Sites.Read.All` (Delegated) 
  - `Mail.Send` (Delegated)
  - `User.Read.All` (Delegated)

### Authentication
- **Platform**: Web
- **Redirect URIs**: 
  - `https://your-app-url/signin-oidc` (for production)
  - `https://localhost:5001/signin-oidc` (for local development)
- **Logout URL**: `https://your-app-url/signout-callback-oidc`

## Configuration

Update `appsettings.json` with your Azure AD and Azure AI Foundry details:

```json
{
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "TenantId": "your-tenant-id",
    "ClientId": "your-client-id",
    "CallbackPath": "/signin-oidc",
    "SignedOutCallbackPath": "/signout-callback-oidc"
  },
  "AzureAIFoundry": {
    "ProjectEndpoint": "your-azure-ai-foundry-endpoint",
    "ModelName": "gpt-4o",
    "APIKey": "your-api-key"
  },
  "Microsoft365": {
    "TenantId": "your-tenant-id",
    "ClientId": "your-client-id",
    "CopilotRetrievalEndpoint": "https://graph.microsoft.com/beta/copilot/retrieval",
    "FilterExpression": "path:\"https://your-sharepoint-site.sharepoint.com\"",
    "UseUserAuthentication": false,
    "Scopes": [
      "https://graph.microsoft.com/Files.Read.All",
      "https://graph.microsoft.com/Sites.Read.All",
      "https://graph.microsoft.com/Mail.Send",
      "https://graph.microsoft.com/User.Read.All"
    ]
  }
}
```

## Local Development

1. Clone the repository
2. Update `appsettings.json` with your configuration
3. Run the application:
   ```bash
   dotnet run
   ```
4. Navigate to `https://localhost:5001`

## Azure Deployment

Deploy to Azure using Azure Developer CLI:

```bash
# Initialize the environment
azd auth login
azd env new

# Set environment variables (optional)
azd env set AZURE_LOCATION "East US"

# Deploy the application
azd up
```

## How It Works

1. **User Authentication**: Users sign in with their Microsoft 365 account
2. **Delegated Access**: The application uses the user's delegated token to access Microsoft Graph
3. **Document Retrieval**: Queries SharePoint for policy documents and compliance rules
4. **AI Analysis**: Uses Azure OpenAI to analyze documents against compliance rules
5. **Results Display**: Shows violation reports in the web interface
6. **Email Notifications**: Sends compliance findings to document authors

## Security Notes

- The application uses delegated permissions, meaning it can only access data the signed-in user has access to
- No service account or app-only permissions are used
- All authentication flows go through Microsoft Identity platform
- Tokens are handled securely by Microsoft Identity Web library

## Troubleshooting

### Common Issues

1. **Authentication Errors**:
   - Verify Azure AD app registration settings
   - Check redirect URIs match exactly
   - Ensure required permissions are granted and admin consented

2. **Graph API Errors**:
   - Verify user has appropriate SharePoint permissions
   - Check if Microsoft Graph scopes are correctly configured
   - Ensure Copilot for Microsoft 365 is enabled in your tenant

3. **Azure AI Foundry Errors**:
   - Verify API key and endpoint configuration
   - Check if the model deployment is available

## Architecture

```
User Browser → Azure AD Authentication → ASP.NET Core Web App
                                              ↓
Microsoft Graph API ← Delegated Token ← Application
                                              ↓
Azure OpenAI Service ← API Key ← Application
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request