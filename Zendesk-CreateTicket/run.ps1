<# 

.SYNOPSIS
    
    This function is used to create a Zendesk ticket.

.DESCRIPTION
                
    This function is used to create a Zendesk ticket.
                
    The function requires the following environment variables to be set:
                
    Zendesk_ApiUsername - User email of the Zendesk user who generated the token
    Zendesk_ApiToken - Token generated for use with the Zendesk API
    Zendesk_Domain - Identifier of the Zendesk domain (e.g., mycompany)
    SecurityKey - Optional, use this as an additional step to secure the function
        
    The function requires the following modules to be installed:
                
    None    

.INPUTS

    Subject - ticket subject
    Description - ticket description
    UserName - user name
    UserEmail - user email
    SecurityKey - optional security key to secure the function

    JSON Structure

    {
        "Subject": "This is a subject",
        "Description": "This is a description",
        "UserName": "John Doe",
        "UserEmail": "user@email.com",
        "SecurityKey", "optional"
    }

.OUTPUTS

    JSON structure of the response from the Zendesk API

#>

using namespace System.Net

param($Request, $TriggerMetadata)

function Add-ZendeskTicket {
    param (
        [string]$ApiUser,
        [string]$ApiToken,
        [string]$Domain,
        [string]$UserName,
        [string]$UserEmail,
        [string]$Subject,
        [string]$Description
    )

    # Define the Zendesk domain
    $zendeskDomain = "$Domain.zendesk.com"

    # Basic Auth string (email/token:api_token)
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($ApiUser)/token:$($ApiToken)"))

    # Create JSON payload
    $jsonPayload = @{
        ticket = @{
            subject = $Subject
            comment = @{ 
                body = $Description 
                }
            requester = @{
                name = $UserName
                email = $UserEmail
                }
        }
    } | ConvertTo-Json

    # Set the request headers
    $headers = @{
        "Authorization" = "Basic $base64AuthInfo"
        "Content-Type" = "application/json"
    }

    # API URL for creating a ticket
    $apiUrl = "https://$zendeskDomain/api/v2/tickets.json"

    # Send the request
    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $jsonPayload

    # Output the response
    return $response
}

$Subject = $Request.Body.Subject
$Description = $Request.Body.Description
$UserName = $Request.Body.UserName
$UserEmail = $Request.Body.UserEmail
$SecurityKey = $env:SecurityKey

if ($SecurityKey -And $SecurityKey -ne $Request.Headers.SecurityKey) {
    Write-Host "Invalid security key"
    break;
}

if (-Not $Subject) {
    Write-Host "Missing subject"
    break;
}
if (-Not $Description) {
    Write-Host "Missing description"
    break;
}
if (-Not $UserName) {
    Write-Host "Missing user name"
    break;
}
if (-Not $UserEmail) {
    Write-Host "Missing user email"
    break;
}

Write-Host "Subject: $Subject"
Write-Host "Description: $Description"
Write-Host "User Name: $UserName"
Write-Host "User Email: $UserEmail"

$result = Add-ZendeskTicket -ApiUser $env:Zendesk_ApiUsername `
    -ApiToken $env:Zendesk_ApiToken `
    -Domain $env:Zendesk_Domain `
    -Subject $Subject `
    -Description $Description `
    -UserName $UserName `
    -UserEmail $UserEmail

Write-Host $result.Message

$body = @{
    response = ($result | ConvertTo-Json);
} 

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    ContentType = "application/json"
})
