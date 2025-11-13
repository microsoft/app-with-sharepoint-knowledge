using Azure.Core;
using Microsoft.Identity.Web;
using Microsoft.Identity.Client;

namespace AgentWithSPKnowledgeViaRetrieval.Services;

public class DelegateTokenCredential : TokenCredential
{
    private readonly ITokenAcquisition _tokenAcquisition;
    private readonly string[] _scopes;

    public DelegateTokenCredential(ITokenAcquisition tokenAcquisition, string[] scopes)
    {
        _tokenAcquisition = tokenAcquisition;
        _scopes = scopes;
    }

    public override AccessToken GetToken(TokenRequestContext requestContext, CancellationToken cancellationToken)
    {
        return GetTokenAsync(requestContext, cancellationToken).GetAwaiter().GetResult();
    }

    public override async ValueTask<AccessToken> GetTokenAsync(TokenRequestContext requestContext, CancellationToken cancellationToken)
    {
        try
        {
            // For Azure AI services, we need to make a fresh token request
            // Use GetAccessTokenForUserAsync with incremental consent for the AI scope
            var token = await _tokenAcquisition.GetAccessTokenForUserAsync(_scopes, user: null);
            
            // Parse the token to get expiration time (this is a simplified approach)
            // In a real scenario, you might want to decode the JWT to get the actual expiry
            var expiry = DateTimeOffset.UtcNow.AddHours(1);
            
            return new AccessToken(token, expiry);
        }
        catch (MsalUiRequiredException)
        {
            // This means the user needs to consent to additional scopes
            // In a web app, this would trigger a redirect to the consent page
            throw new UnauthorizedAccessException("Additional consent required for Azure AI services access");
        }
        catch (Exception)
        {
            // If getting user token fails, we could fall back to app token
            // or rethrow the exception based on requirements
            throw;
        }
    }
}