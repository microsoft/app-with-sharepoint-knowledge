using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Logging;
using AgentWithSPKnowledgeViaRetrieval.Services;

namespace AgentWithSPKnowledgeViaRetrieval.Filters;

public class EnsureTokensAcquiredAttribute : Attribute, IAsyncActionFilter
{
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        // Only apply to authenticated users
        if (context.HttpContext.User?.Identity?.IsAuthenticated == true)
        {
            var tokenService = context.HttpContext.RequestServices.GetService<IMultiResourceTokenService>();
            var logger = context.HttpContext.RequestServices.GetService<ILogger<EnsureTokensAcquiredAttribute>>();

            if (tokenService != null && logger != null)
            {
                try
                {
                    logger.LogDebug("Pre-acquiring tokens for authenticated user");
                    await tokenService.EnsureTokensAcquiredAsync();
                }
                catch (Exception ex)
                {
                    logger.LogWarning(ex, "Could not pre-acquire all tokens, continuing with request");
                    // Don't fail the request if token pre-acquisition fails
                    // Individual services will handle consent when needed
                }
            }
        }

        await next();
    }
}