using Azure.Core;
using Microsoft.Extensions.Logging;

namespace AgentWithSPKnowledgeViaRetrieval.Services;

public class MultiResourceTokenCredential : TokenCredential
{
    private readonly IMultiResourceTokenService _tokenService;
    private readonly ILogger<MultiResourceTokenCredential> _logger;

    public MultiResourceTokenCredential(
        IMultiResourceTokenService tokenService,
        ILogger<MultiResourceTokenCredential> logger)
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
            // Determine which resource is being requested based on the scopes
            var isAzureAI = requestContext.Scopes?.Any(scope => 
                scope.Contains("cognitiveservices.azure.com", StringComparison.OrdinalIgnoreCase)) == true;

            string token;
            if (isAzureAI)
            {
                _logger.LogDebug("Acquiring Azure AI token");
                token = await _tokenService.GetAzureAITokenAsync();
            }
            else
            {
                _logger.LogDebug("Acquiring Microsoft Graph token");
                token = await _tokenService.GetGraphTokenAsync();
            }

            // Token expiry is typically 1 hour, but we set a slightly shorter time for safety
            var expiry = DateTimeOffset.UtcNow.AddMinutes(55);
            
            return new AccessToken(token, expiry);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to acquire token for scopes: {Scopes}", 
                string.Join(", ", requestContext.Scopes ?? new string[0]));
            throw;
        }
    }
}