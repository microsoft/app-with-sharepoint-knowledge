using Azure.Core;
using Microsoft.Extensions.Logging;

namespace AgentWithSPKnowledgeViaRetrieval.Services;

/// <summary>
/// TokenCredential specifically designed for Azure AI services that routes requests
/// to the Azure AI token acquisition through the MultiResourceTokenService
/// </summary>
public class AzureAITokenCredential : TokenCredential
{
    private readonly IMultiResourceTokenService _tokenService;
    private readonly ILogger<AzureAITokenCredential> _logger;

    public AzureAITokenCredential(
        IMultiResourceTokenService tokenService,
        ILogger<AzureAITokenCredential> logger)
    {
        _tokenService = tokenService;
        _logger = logger;
    }

    public override AccessToken GetToken(TokenRequestContext requestContext, CancellationToken cancellationToken)
    {
        return GetTokenAsync(requestContext, cancellationToken).GetAwaiter().GetResult();
    }

    public override async ValueTask<AccessToken> GetTokenAsync(TokenRequestContext requestContext, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogDebug("Acquiring Azure AI token for scopes: {Scopes}", 
                string.Join(", ", requestContext.Scopes ?? new string[0]));
                
            string accessToken = await _tokenService.GetAzureAITokenAsync();
            
            // Token expiry is typically 1 hour, but we set a slightly shorter time for safety
            var expiry = DateTimeOffset.UtcNow.AddMinutes(55);
            
            _logger.LogDebug("Successfully acquired Azure AI token");
            return new AccessToken(accessToken, expiry);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to acquire Azure AI token for request context with scopes: {Scopes}", 
                string.Join(", ", requestContext.Scopes ?? new string[0]));
            throw;
        }
    }
}