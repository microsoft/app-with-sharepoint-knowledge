using Azure.Core;
using Microsoft.Extensions.Logging;

namespace AgentWithSPKnowledgeViaRetrieval.Services;

public class GraphTokenCredential : TokenCredential
{
    private readonly IMultiResourceTokenService _tokenService;
    private readonly ILogger<GraphTokenCredential> _logger;

    public GraphTokenCredential(
        IMultiResourceTokenService tokenService,
        ILogger<GraphTokenCredential> logger)
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
            _logger.LogDebug("Acquiring Microsoft Graph token for request");
            var token = await _tokenService.GetGraphTokenAsync();
            
            // Token expiry is typically 1 hour, but we set a slightly shorter time for safety
            var expiry = DateTimeOffset.UtcNow.AddMinutes(55);
            
            return new AccessToken(token, expiry);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to acquire Graph token for scopes: {Scopes}", 
                string.Join(", ", requestContext.Scopes ?? new string[0]));
            throw;
        }
    }
}