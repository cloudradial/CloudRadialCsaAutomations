<# 

.SYNOPSIS
    
    This function is used to set the status of an Autotask ticket based on the result code.

.DESCRIPTION
                
    This function is used to set the status of an Autotask ticket based on the result code.
                
    The function requires the following environment variables to be set:
                
    AutotaskPsa_ApiUsername - Username of the Autotask API member
    AutotaskPsa_ApiSecret - Secret of the Autotask API member
    AutotaskPsa_ApiIntegrationCode - Autotask tracking identifier: 
        https://autotask.net/help/Content/4_Admin/1CompanySettings_Users/ResourcesUsersHR/Resources/API_Tracking_Identifier.htm 
    AutotaskPsa_ApiStatusClosed - Status to set when result code is 200
    AutotaskPsa_ApiStatusOpen - Status to set when result code is not 200
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

    JSON structure of the response from the Autotask API

#>

using namespace System.Net

param($Request, $TriggerMetadata)

function Set-AutotaskTicketStatus {
    param (
        [string]$Username,
        [string]$Secret,
        [string]$IntegrationCode,
        [string]$TicketId,
        [string]$StatusName
    )

    $SecureSecret = ConvertTo-SecureString $Secret -AsPlainText -Force

    # Convert the securestring back to a normal string
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureSecret)
    $SecureString = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
    
    # Create headers dictionary
    $headers = @{
        "ApiIntegrationcode" = $IntegrationCode
        "UserName" = $Username
        "Secret" = $SecureString
        "Content-Type" = "application/json"
    }
    
    $VersionInfo = Invoke-RestMethod -Uri "http://webservices.autotask.net/atservicesrest/versioninformation"

    Write-Host ($VersionInfo | ConvertTo-Json)

    # Get API version information
    $Version = $VersionInfo.apiversions | select-object -last 1

    Write-Host $Version

    $AutotaskBaseURI = Invoke-RestMethod -Uri "http://webservices.autotask.net/atservicesrest/$Version/zoneInformation?user=$Username"

    Write-Host $AutotaskBaseURI

    $AutotaskBaseUrl = $AutotaskBaseURI.url

    Write-Host $AutotaskBaseUrl

    $StatusUrl = "$($AutotaskBaseUrl)$($Version)/tickets/entityinformation/fields"

    Write-Host $StatusUrl

    # Get ticket status entities
    $EntityInfo = Invoke-RestMethod -Uri $StatusUrl -Method Get -Headers $headers
    
    Write-Host ($EntityInfo | ConvertTo-Json)

    # Find the status entity that matches the status name
    $StatusEntities = ($EntityInfo.fields | Where-Object { $_.name -eq "status" }).picklistValues

    Write-Host ($StatusEntities | ConvertTo-Json)

    $StatusEntity = $StatusEntities | Where-Object { $_.label -eq $StatusName }

    Write-Host ($StatusEntity | ConvertTo-Json)
    
    if ($StatusEntity) {
        # Update the ticket status
        $TicketUpdate = @{
            "id" = $TicketId
            "status" = $StatusEntity.value
        } | ConvertTo-Json
    
        $TicketUpdateUrl = "${AutotaskBaseUrl}${Version}/Tickets"

        Write-Host $TicketUpdateUrl

        Invoke-RestMethod -Uri $TicketUpdateUrl -Method Patch -Headers $headers -Body $TicketUpdate
    } else {
        Write-Host "Status '$StatusName' not found"
    }
    
    return $StatusEntity
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

$result = Set-AutotaskTicketStatus `
    -Username "$env:AutotaskPsa_ApiUsername" `
    -Secret $env:AutotaskPsa_ApiSecret `
    -IntegrationCode $env:AutotaskPsa_ApiIntegrationCode `
    -TicketId $TicketId `
    -StatusName $Status

Write-Host $result.Message

$body = @{
    response = ($result | ConvertTo-Json);
} 

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    ContentType = "application/json"
})
