<# 

.SYNOPSIS
    
    This function is used to set the status of a ConnectWise ticket based on the result code.

.DESCRIPTION
                
    This function is used to set the status of a ConnectWise ticket based on the result code.
                
    The function requires the following environment variables to be set:
                
    ConnectWisePsa_ApiBaseUrl - Base URL of the ConnectWise API
    ConnectWisePsa_ApiCompanyId - Company Id of the ConnectWise API
    ConnectWisePsa_ApiPublicKey - Public Key of the ConnectWise API
    ConnectWisePsa_ApiPrivateKey - Private Key of the ConnectWise API
    ConnectWisePsa_ApiClientId - Client Id of the ConnectWise API
    ConnectWisePsa_ApiStatusClosed - Status to set when result code is 200
    ConnectWisePsa_ApiStatusOpen - Status to set when result code is not 200
    SecurityKey - Optional, use this as an additional step to secure the function
        
    The function requires the following modules to be installed:
                
    None    

.INPUTS

    TicketId - string value of numeric ticket number
    ResultCode - numeric value of result code, 200 = success
    SecurityKey - optional security key to secure the function

    JSON Structure

    {
        "TicketId": "123456"
        "ResultCode": 200,
        "SecurityKey", "optional"
    }

.OUTPUTS

    JSON structure of the response from the ConnectWise API

#>

using namespace System.Net

param($Request, $TriggerMetadata)

function Set-ConnectWiseTicketStatus {
    param (
        [string]$ConnectWiseUrl,
        [string]$PublicKey,
        [string]$PrivateKey,
        [string]$ClientId,
        [string]$TicketId,
        [string]$Status
    )

    # Construct the API endpoint for adding a note
    $apiUrl = "$ConnectWiseUrl/v4_6_release/apis/3.0/service/tickets/$TicketId"

    # ConnectWise API requires the status to be an ID value
    # Each board has its own status values, so we need to get the ticket to find the right board,
    #   and then get the status ID from the board based on the name of the status 

    # Set up the authentication headers
    $headers = @{
        "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${PublicKey}:${PrivateKey}"))
        "Content-Type" = "application/json"
        "ClientId" = $ClientId
    }
    
    $ticket = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $headers

    Write-Host ($ticket | ConvertTo-Json)

    $boardUrl = "$ConnectWiseUrl/v4_6_release/apis/3.0/service/boards/${ticket.board.id}/statuses?pageSize=100"

    Write-Host $boardUrl

    $statuses = Invoke-RestMethod -Uri $boardUrl -Method Get -Headers $headers
    
    $status = $Statuses | Where-Object { $_.name -eq $StatusName }

    $operationList = @()
    $operation = @{
        op = "replace"
        path = "status/id"
        value = "$statusId"
    }
    $operationList += $operation
    
    # Make the API request to add the note
    $result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers $headers -Body -Body (ConvertTo-Json -InputObject $operationList)
    Write-Host $result
    return $result
}

$TicketId = $Request.Body.TicketId
$StatusClosed = $env:ConnectWisePsa_ApiStatusClosed
$StatusOpen = $env:ConnectWisePsa_ApiStatusOpen
$SecurityKey = $env:SecurityKey

if ($SecurityKey -And $SecurityKey -ne $Request.Headers.SecurityKey) {
    Write-Host "Invalid security key"
    break;
}

if (-Not $TicketId) {
    Write-Host "Missing ticket number"
    break;
}
if (-Not $StatusClosed) {
    Write-Host "Missing status closed value"
    break;
}
if (-Not $StatusOpen) {
    Write-Host "Missing status open value"
    break;
}

if ($Request.Body.ResultCode -eq 200) {
    $Status = $StatusClosed
}
else {
    $Status = $StatusOpen
}

Write-Host "TicketId: $TicketId"
Write-Host "StatusOpen: $StatusOpen"
Write-Host "StatusClosed: $StatusClosed"
Write-Host "Status: $Status"

$result = Set-ConnectWiseTicketStatus -ConnectWiseUrl $env:ConnectWisePsa_ApiBaseUrl `
    -PublicKey "$env:ConnectWisePsa_ApiCompanyId+$env:ConnectWisePsa_ApiPublicKey" `
    -PrivateKey $env:ConnectWisePsa_ApiPrivateKey `
    -ClientId $env:ConnectWisePsa_ApiClientId `
    -TicketId $TicketId `
    -Status = $Status

Write-Host $result.Message

$body = @{
    response = ($result | ConvertTo-Json);
} 

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    ContentType = "application/json"
})
