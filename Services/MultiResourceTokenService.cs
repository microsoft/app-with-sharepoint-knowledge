using Microsoft.Identity.Web;
using Microsoft.Identity.Client;
using Microsoft.Extensions.Logging;

namespace AgentWithSPKnowledgeViaRetrieval.Services;

public interface IMultiResourceTokenService
{
    Task<string> GetGraphTokenAsync();
    Task<string> GetAzureAITokenAsync();
    Task EnsureTokensAcquiredAsync();
}

public class MultiResourceTokenService : IMultiResourceTokenService
{
    private readonly ITokenAcquisition _tokenAcquisition;
    private readonly ILogger<MultiResourceTokenService> _logger;
    
    private static readonly string[] GraphScopes = {
        "https://graph.microsoft.com/Files.Read.All",
        "https://graph.microsoft.com/Sites.Read.All",
        "https://graph.microsoft.com/Mail.Send",
        "https://graph.microsoft.com/User.Read.All"
    };
    
    private static readonly string[] AzureAIScopes = {
        "https://cognitiveservices.azure.com/.default"
    };

    public MultiResourceTokenService(
        ITokenAcquisition tokenAcquisition,
        ILogger<MultiResourceTokenService> logger)
    {
        _tokenAcquisition = tokenAcquisition;
        _logger = logger;
    }

    public async Task<string> GetGraphTokenAsync()
    {
        try
        {
            var token = await _tokenAcquisition.GetAccessTokenForUserAsync(GraphScopes);
            _logger.LogDebug("Successfully acquired Microsoft Graph token");
            return token;
        }
        catch (MsalUiRequiredException ex)
        {
            _logger.LogWarning("Microsoft Graph token requires additional consent: {Error}", ex.Message);
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to acquire Microsoft Graph token");
            throw;
        }
    }

    public async Task<string> GetAzureAITokenAsync()
    {
        try
        {
            var token = await _tokenAcquisition.GetAccessTokenForUserAsync(AzureAIScopes);
            _logger.LogDebug("Successfully acquired Azure AI token");
            return token;
        }
        catch (MsalUiRequiredException ex)
        {
            _logger.LogWarning("Azure AI token requires additional consent: {Error}", ex.Message);
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to acquire Azure AI token");
            throw;
        }
    }

    public async Task EnsureTokensAcquiredAsync()
    {
        _logger.LogInformation("Attempting to pre-acquire tokens for all resources");
        
        try
        {
            // Try to acquire Graph token first
            await GetGraphTokenAsync();
            _logger.LogInformation("Microsoft Graph token pre-acquired successfully");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not pre-acquire Microsoft Graph token");
        }

        try
        {
            // Try to acquire Azure AI token
            await GetAzureAITokenAsync();
            _logger.LogInformation("Azure AI token pre-acquired successfully");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not pre-acquire Azure AI token");
        }
    }
}