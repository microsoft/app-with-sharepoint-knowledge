# Troubleshooting Guide

## Authentication Issues

**Error: `AADSTS9002327` - "Tokens issued for the 'Single-Page Application' client-type..."**

- **Cause**: App registration is configured as SPA instead of Web Application
- **Solution**:
  1. Go to Azure Portal → App registrations → Your app → Authentication
  2. Remove all **Single-page application** platforms
  3. Keep only **Web** platform with proper redirect URIs
  4. Ensure **ID tokens** are enabled under Implicit grant and hybrid flows

**Error: `AADSTS7000218` - "The request body must contain the following parameter: 'client_assertion' or 'client_secret'"**

- **Cause**: Missing client secret for web application
- **Solution**:
  1. Go to Azure Portal → App registrations → Your app → Certificates & secrets
  2. Create a new client secret
  3. Update `appsettings.json` with the secret value

## SharePoint Access

- Verify the user has access to the SharePoint content
- Check the `FilterExpression` path is correct
- Ensure `Sites.Read.All` and `Files.Read.All` permissions are granted with admin consent

## Azure AI Foundry

- Ensure you have the correct Azure AI inference endpoint (not the Azure AI Foundry Project endpoint)
- Ensure the model name matches your deployment
- Check Azure AI Foundry resource permissions and API keys