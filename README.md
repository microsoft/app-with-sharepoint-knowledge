# AI Application with SharePoint Knowledge and Actions

This project features a web application and an agent designed to help users process information from their SharePoint content and generate summary reports. The application leverages the Azure AI Foundry SDK to host and communicate with the agent, which utilizes the Copilot Retrieval API for semantic queries of relevant SharePoint content. The Retrieval API relies on SharePoint’s built-in semantic index and access control.

<br/>

<div align="center">
  
[**SOLUTION OVERVIEW**](#solution-overview) \| [**GETTING STARTED**](#getting-started) \| [**BUSINESS SCENARIO**](#business-scenario) \| [**SUPPORTING DOCUMENTATION**](#supporting-documentation)

</div>
<br/>

<b>IMPORTANT!</b> Solution templates are to assist your development of AI solutions for specific scenarios. Review all provided resources and carefully test all AI solution behavior in the context of your use case and specifically the use of [Microsoft 365 Copilot Retrieval API](https://learn.microsoft.com/en-us/microsoft-365-copilot/extensibility/api/ai-services/retrieval/overview).   AI solutions you create may be subject to legal and regulatory requirements, may require licenses, or may not be suitable for all industries, scenarios, or use cases. By using any solution template, you are acknowledging that AI solutions or other output created using that template are solely your responsibility, and that you will comply with all applicable laws, regulations, and relevant safety standards, terms of service, and codes of conduct.

<h2><img src="./docs/images/readme/solution-overview.png" width="48" />
Solution overview
</h2>

This solution deploys a web-based chat application with AI capabilities running in Azure Container App.

The application leverages Azure AI Foundry projects and Azure AI services to provide intelligent policy compliance analysis. It supports retrieving content from SharePoint sites using Microsoft Graph API and analyzes documents against compliance rules using Azure AI models. The solution includes built-in monitoring capabilities with tracing to ensure easier troubleshooting and optimized performance.

This solution creates an Azure AI Foundry project and Azure AI services. Instructions are provided for deployment through Azure Developer CLI and local development environment.

### Solution architecture

The app code runs in Azure Container Apps to process user requests for policy compliance checking. It leverages Azure AI projects and Azure AI services, including the model and Microsoft Graph API for SharePoint content retrieval.

|![image](./docs/images/readme/agent-with-sp-knowledge-m1-solution-diagram.png)|
|---|

<br/>

### Key Features

• **Policy Compliance Analysis**: The AI chat application analyzes SharePoint documents against organizational compliance rules, providing detailed violation reports with citations.

• **SharePoint Integration**: Uses Microsoft Graph API with proper authentication to retrieve policy documents from SharePoint sites with respect for user permissions.

• **Built-in Monitoring and Tracing**: Integrated monitoring capabilities, including structured logging with ILogger, enable tracing and logging for easier troubleshooting and performance optimization.

• **Web-based Interface**: Modern Bootstrap-based responsive web interface with authentication flows and real-time progress indicators.

Here is a screenshot showing the web application interface:

![Screenshot of the policy compliance web application showing the main interface with compliance check functionality](./docs/agent_with_sp_knowledge_output.png)

> [!WARNING]
> This template, the application code and configuration it contains, has been built to showcase Microsoft Azure specific services and tools. We strongly advise our customers not to make this code part of their production environments without implementing or enabling additional security features.

For a more comprehensive list of best practices and security recommendations for Intelligent Applications, [visit our official documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/).

## Getting Started

### Quick Deploy

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/microsoft/agent-with-sharepoint-knowledge)
[![Open in Dev Containers](https://img.shields.io/static/v1?style=for-the-badge&label=Dev%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/microsoft/agent-with-sharepoint-knowledge)

You can run this repository virtually by using GitHub Codespaces or VS Code Dev Containers. Click on one of the buttons above to open this repository in one of those options.

After deployment, try asking the application to check policy compliance to test your web application.

## Local Development

For developers who want to run the application locally or customize the application:

### Prerequisites

- .NET 8.0 SDK
- Azure AI Foundry resource  
- Microsoft 365 tenant with SharePoint
- Azure App Registration with delegated permissions

### Setup Instructions

1. **Clone the Repository**

   ```bash
   git clone https://github.com/microsoft/agent-with-sharepoint-knowledge
   cd agent-with-sharepoint-knowledge
   ```

2. **Configure Azure App Registration**

   1. **Create an Azure App Registration**:
      - Go to [Azure Portal](https://portal.azure.com)
      - Navigate to **Azure Active Directory** → **App registrations**  
      - Click **New registration**
      - Name: your app name
      - Supported account types: **Accounts in this organizational directory only (Single tenant)**
      - Redirect URI: **Web** platform with `https://localhost:5001/signin-oidc`
      - Click **Register**

   2. **Configure Authentication**:
      - Go to **Authentication** in the left menu
      - Under **Platform configurations**:
        - Ensure **Web** platform is configured with redirect URI: `https://localhost:5001/signin-oidc`
        - Add logout URL: `https://localhost:5001/signout-callback-oidc`
        - Enable **ID tokens** under Implicit grant and hybrid flows

   3. **Create Client Secret**:
      - Go to **Certificates & secrets**
      - Click **New client secret**
      - Add description and set expiration
      - **Copy the secret value** immediately (you won't see it again)

   4. **Configure API Permissions**:
      - Go to **API permissions** → **Add a permission** → **Microsoft Graph** → **Delegated permissions**
      - Add these permissions:
        - `Files.Read.All`
        - `Sites.Read.All`
        - `Mail.Send`
        - `User.Read.All`
      - Click **Grant admin consent**

3. **Configure Application Settings**

   1. Copy the example configuration:

      ```bash
      cp appsettings.example.json appsettings.json
      ```

   2. Update `appsettings.json` with your values:

      ```json
      {
        "AzureAd": {
          "Instance": "https://login.microsoftonline.com/",
          "TenantId": "your-tenant-id",
          "ClientId": "your-client-id", 
          "ClientSecret": "your-client-secret",
          "CallbackPath": "/signin-oidc",
          "SignedOutCallbackPath": "/signout-callback-oidc"
        },
        "AzureAIFoundry": {
          "ProjectEndpoint": "your-azure-ai-inference-endpoint",
          "ModelName": "your-model-name",
          "APIKey": "your-api-key"
        },
        "Microsoft365": {
          "TenantId": "your-tenant-id",
          "ClientId": "your-client-id",
          "FilterExpression": "path:\"https://your-sharepoint-site.sharepoint.com\""
        }
      }
      ```

      > [!NOTE]
      > You will need your Azure AI inference endpoint (which is not your Azure AI Foundry Project endpoint). To get this navigate to `Models + Endpoints > name of Model` Switch the SDK to `Azure AI Inference SDK` and the code panel should have some code sample with the relevant endpoint. This endpoint will look something like `https://{projectName}.cognitiveservices.azure.com/openai/deployments/{modelName}`

4. **Run Locally**

   ```bash
   # Install dependencies
   dotnet restore

   # Build the application
   dotnet build

   # Run the application
   dotnet run
   ```

   The application will be available at:
   - HTTP: `http://localhost:5000`
   - HTTPS: `https://localhost:5001`

### Azure Developer CLI Deployment

```bash
# Initialize environment
azd init

# Provision and deploy
azd up
```

After running the azd commands above you will be presented with the URL to the deployed container app. Add the following redirect URIs to the same app registration mentioned above:

- `https://{your-container-app-url}/signin-oidc`
- `https://{your-container-app-url}/signout-callback-oidc`


## Resource Clean-up

To prevent incurring unnecessary charges, it's important to clean up your Azure resources after completing your work with the application.

**When to Clean Up:**

- After you have finished testing or demonstrating the application
- If the application is no longer needed or you have transitioned to a different project or environment  
- When you have completed development and are ready to decommission the application

**Deleting Resources:** To delete all associated resources and shut down the application, execute the following command:

```bash
azd down
```

Please note that this process may take up to 20 minutes to complete.

> [!WARNING]
> Alternatively, you can delete the resource group directly from the Azure Portal to clean up resources.

## Guidance

### Costs

Pricing varies per region and usage, so it isn't possible to predict exact costs for your usage. The majority of the Azure resources used in this infrastructure are on usage-based pricing tiers. However, Azure Container Registry has a fixed cost per registry per day.

You can try the [Azure pricing calculator](https://azure.microsoft.com/en-us/pricing/calculator) for the resources:

- **Azure AI Foundry**: Free tier. [Pricing](https://azure.microsoft.com/pricing/details/ai-studio/)
- **Azure AI Services**: S0 tier, defaults to gpt-4o-mini models. Pricing is based on token count. [Pricing](https://azure.microsoft.com/pricing/details/cognitive-services/)
- **Azure Container App**: Consumption tier with 0.5 CPU, 1GiB memory/storage. Pricing is based on resource allocation, and each month allows for a certain amount of free usage. [Pricing](https://azure.microsoft.com/pricing/details/container-apps/)
- **Azure Container Registry**: Basic tier. [Pricing](https://azure.microsoft.com/pricing/details/container-registry/)
- **Log analytics**: Pay-as-you-go tier. Costs based on data ingested. [Pricing](https://azure.microsoft.com/pricing/details/monitor/)

> [!WARNING]
> To avoid unnecessary costs, remember to take down your app if it's no longer in use, either by deleting the resource group in the Portal or running `azd down`.

### Security Guidelines

This template uses [Managed Identity](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview) for deployment and Microsoft Identity Web for local development.

To ensure continued best practices in your own repository, we recommend that anyone creating solutions based on our templates ensure that the [Github secret scanning](https://docs.github.com/code-security/secret-scanning/about-secret-scanning) setting is enabled.

You may want to consider additional security measures, such as:

- Enabling Microsoft Defender for Cloud to [secure your Azure resources](https://learn.microsoft.com/azure/defender-for-cloud/)
- Protecting the Azure Container Apps instance with a [firewall](https://learn.microsoft.com/azure/container-apps/waf-app-gateway) and/or [Virtual Network](https://learn.microsoft.com/azure/container-apps/networking?tabs=workload-profiles-env%2Cazure-cli)

> [!IMPORTANT]
> **Security Notice**  
> This template, the application code and configuration it contains, has been built to showcase Microsoft Azure specific services and tools. We strongly advise our customers not to make this code part of their production environments without implementing or enabling additional security features.
>
> For a more comprehensive list of best practices and security recommendations for Intelligent Applications, [visit our official documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/).

### Resources

This template creates everything you need to get started with Azure AI Foundry:

| Resource | Purpose |
|----------|---------|
| **Azure AI Project** | Provides a collaborative workspace for AI development with access to models, data, and compute resources |
| **Azure AI Services** | Powers the AI agents for policy compliance analysis and intelligent document processing. Default models deployed are gpt-4o-mini, but any Azure AI models can be specified per the documentation |
| **Azure Container Apps** | Hosts and scales the web application with serverless containers |
| **Azure Container Registry** | Stores and manages container images for secure deployment |
| **Application Insights** | Optional - Provides application performance monitoring, logging, and telemetry for debugging and optimization |
| **Log Analytics Workspace** | Optional - Collects and analyzes telemetry data for monitoring and troubleshooting |

### Troubleshooting

For solutions to common deployment, container app, and app issues, see the [Troubleshooting Guide](./docs/TROUBLESHOOTING.md).
