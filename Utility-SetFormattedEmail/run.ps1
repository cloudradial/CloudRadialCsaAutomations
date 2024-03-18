<# 

.SYNOPSIS
    
    This function is used to add a user to a group in Microsoft 365.

.DESCRIPTION
        
    This function is used to add a user to a group in Microsoft 365.
        
    The function requires the following environment variables to be set:
        
    Ms365_AuthAppId - Application Id of the service principal
    Ms365_AuthSecretId - Secret Id of the service principal
    Ms365_TenantId - Tenant Id of the Microsoft 365 tenant
        
    The function requires the following modules to be installed:
        
    Microsoft.Graph

.INPUTS
    
    Message - text of message to place in email
    TicketId - optional - string value of the ticket id used for transaction tracking

    JSON Structure

    {
        "Message": "This is the message"
        "TicketId": "123456
    }

.OUTPUTS

    HTML formatted email message

#>

using namespace System.Net

param($Request, $TriggerMetadata)

$body = @"

<p>The request you submitted has been processed.</p>
<p>$($Request.Body.Message)</p>
<p>If you have any questions on this request, please refer to ticket number # $($Request.Body.TicketId).</p>

"@

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    ContentType = "text/html"
})
