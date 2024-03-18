<# 

.SYNOPSIS
    
        This function is used to add a note to a ConnectWise ticket.

.DESCRIPTION
                    
            This function is used to add a note to a ConnectWise ticket.
                    
            The function requires the following environment variables to be set:
                    
            ConnectWisePsa_ApiBaseUrl - Base URL of the ConnectWise API
            ConnectWisePsa_ApiCompanyId - Company Id of the ConnectWise API
            ConnectWisePsa_ApiPublicKey - Public Key of the ConnectWise API
            ConnectWisePsa_ApiPrivateKey - Private Key of the ConnectWise API
            ConnectWisePsa_ApiClientId - Client Id of the ConnectWise API
                    
            The function requires the following modules to be installed:
                    
            None        

.INPUTS

    TicketId - string value of numeric ticket number
    Message - text of note to add
    Internal - boolean indicating whether not should be internal only

    JSON Structure

    {
        "TicketId": "123456",
        "Message": "This is a note",
        "Internal": true
    }

.OUTPUTS
    
    JSON structure of the response from the ConnectWise API

#>

using namespace System.Net

param($Request, $TriggerMetadata)

function Add-ConnectWiseTicketNote {
    param (
        [string]$ConnectWiseUrl,
        [string]$PublicKey,
        [string]$PrivateKey,
        [string]$ClientId,
        [string]$TicketId,
        [string]$Text,
        [boolean]$Internal = $false
    )

    # Construct the API endpoint for adding a note
    $apiUrl = "$ConnectWiseUrl/v4_6_release/apis/3.0/service/tickets/$TicketId/notes"

    # Create the note serviceObject
    $notePayload = @{
        ticketId = $TicketId
        text = $Text
        detailDescriptionFlag = $true
        internalAnalysisFlag = $Internal
        #resolutionFlag = $false
        #customerUpdatedFlag = $false 
    } | ConvertTo-Json
    
    # Set up the authentication headers
    $headers = @{
        "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${PublicKey}:${PrivateKey}"))
        "Content-Type" = "application/json"
        "clientId" = $ClientId
    }

    # Make the API request to add the note
    $result = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $notePayload
    Write-Host $result
    return $result
}

$TicketId = $Request.Body.TicketId
$Text = $Request.Body.Message
$Internal = $Request.Body.Internal

if (-Not $TicketId) {
    Write-Host "Missing ticket number"
    break;
}
if (-Not $Text) {
    Write-Host "Missing ticket text"
    break;
}
if (-Not $Internal) {
    $internal = $false
}

Write-Host "TicketId: $TicketId"
Write-Host "Text: $Text"
Write-Host "Internal: $Internal"

$result = Add-ConnectWiseTicketNote -ConnectWiseUrl $env:ConnectWisePsa_ApiBaseUrl `
    -PublicKey "$env:ConnectWisePsa_ApiCompanyId+$env:ConnectWisePsa_ApiPublicKey" `
    -PrivateKey $env:ConnectWisePsa_ApiPrivateKey `
    -ClientId $env:ConnectWisePsa_ApiClientId `
    -TicketId $TicketId `
    -Text $Text `
    -Internal $Internal

Write-Host $result.Message

$body = @{
    response = $result | ConvertTo-Json;
} 

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    ContentType = "application/json"
})
