<# 

.SYNOPSIS
    
    This function is used to add a user to a group in Microsoft 365.

.DESCRIPTION
        
    This function is used to add a user to a group in Microsoft 365.
        
    The function requires the following environment variables to be set:
        
    Ms365_AuthAppId - Application Id of the service principal
    Ms365_AuthSecretId - Secret Id of the service principal
    Ms365_TenantId - Tenant Id of the Microsoft 365 tenant
    CloudradialCsa_PortalUrl - Base URL of the CloudRadial CSA tenant
    SecurityKey - Optional, use this as an additional step to secure the function
   
    The function requires the following modules to be installed:
        
    Microsoft.Graph

.INPUTS
    
    Message - text of message to place in email
    TicketId - optional - string value of the ticket id used for transaction tracking
    SecurityKey - optional security key to secure the function

    JSON Structure

    {
        "Message": "This is the message"
        "TicketId": "123456,
        "SecurityKey", "optional"
    }

.OUTPUTS

    HTML formatted email message

#>

using namespace System.Net

param($Request, $TriggerMetadata)

$TicketId = $Request.Body.TicketId
$PortalUrl = $env:CloudRadialCsa_PortalUrl
$SecurityKey = $env:SecurityKey

if ($SecurityKey -And $SecurityKey -ne $Request.Headers.SecurityKey) {
    Write-Host "Invalid security key"
    break;
}

$body = @"

<p>The request you submitted has been processed.</p>
<p>$($Request.Body.Message)</p>
<p>If you have any questions on this request, please refer to ticket number # <a target="_blank" href="$PortalUrl/app/service/status/$TicketId">$TicketId</a>.</p>

"@

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    ContentType = "text/html"
})
