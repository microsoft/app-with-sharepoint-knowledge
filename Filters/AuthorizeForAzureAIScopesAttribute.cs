using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Identity.Web;
using Microsoft.Identity.Client;
using Microsoft.Extensions.Logging;

namespace AgentWithSPKnowledgeViaRetrieval.Filters;

public class AuthorizeForAzureAIScopesAttribute : Attribute, IAsyncActionFilter
{
    private readonly string[] _scopes = { "https://cognitiveservices.azure.com/.default" };

    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        if (context.HttpContext.User?.Identity?.IsAuthenticated == true)
        {
            var tokenAcquisition = context.HttpContext.RequestServices.GetService<ITokenAcquisition>();
            var logger = context.HttpContext.RequestServices.GetService<ILogger<AuthorizeForAzureAIScopesAttribute>>();

            if (tokenAcquisition != null)
            {
                try
                {
                    // Try to acquire the token silently
                    await tokenAcquisition.GetAccessTokenForUserAsync(_scopes);
                    logger?.LogDebug("Azure AI token acquired successfully");
                }
                catch (MsalUiRequiredException ex)
                {
                    logger?.LogInformation("Azure AI consent required, redirecting user");
                    
                    // Create a challenge with the required scopes
                    var properties = new Microsoft.AspNetCore.Authentication.AuthenticationProperties();
                    properties.Items.Add("scopes", string.Join(" ", _scopes));
                    
                    // Return a challenge result to trigger consent
                    context.Result = new ChallengeResult("OpenIdConnect", properties);
                    return;
                }
                catch (Exception ex)
                {
                    logger?.LogError(ex, "Failed to acquire Azure AI token");
                    context.Result = new UnauthorizedResult();
                    return;
                }
            }
        }

        await next();
    }
}