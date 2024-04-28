<# 

.SYNOPSIS
    
    This function is used to add a note to an Autotask ticket.

.DESCRIPTION
                
    This function is used to add a note to an Autotask ticket.
                
    The function requires the following environment variables to be set:
                
    AutotaskPsa_ApiUsername - Username of the Autotask API member
    AutotaskPsa_ApiSecret - Secret of the Autotask API member
    AutotaskPsa_ApiIntegrationCode - Autotask tracking identifier: 
        https://autotask.net/help/Content/4_Admin/1CompanySettings_Users/ResourcesUsersHR/Resources/API_Tracking_Identifier.htm 
    SecurityKey - Optional, use this as an additional step to secure the function
        
    The function requires the following modules to be installed:
                
    None    

.INPUTS

    TicketId - string value of numeric ticket number (not the T.. version but Autotask's internal id number which is an integer)
    Title - note title
    Message - note text
    SecurityKey - optional security key to secure the function

    JSON Structure

    {
        "TicketId": "123456",
        "Title": "This is a title",
        "Message": "This is a note",
        "SecurityKey", "optional"
    }

.OUTPUTS

    JSON structure of the response from the Autotask API

#>

using namespace System.Net

param($Request, $TriggerMetadata)

function Add-AutotaskTicketNote {
    param (
        [string]$Username,
        [string]$Secret,
        [string]$IntegrationCode,
        [string]$TicketId,
        [string]$Title,
        [string]$Text
    )

    $SecureSecret = ConvertTo-SecureString $Secret -AsPlainText -Force

    # Convert the securestring back to a normal string
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureSecret)
    $SecureString = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
    
    write-host $IntegrationCode
    write-host $Username
    write-host $Secret
    WRite-Host $SecureString
    Write-Host $Title
    Write-Host $Text
    Write-Host $TicketId

    # Create headers dictionary
    $headers = @{
        "ApiIntegrationcode" = $IntegrationCode
        "UserName" = $Username
        "Secret" = $Secret
        "Content-Type" = "application/json"
    }
    
    $VersionInfo = Invoke-RestMethod -Uri "https://webservices.autotask.net/atservicesrest/versioninformation"

    Write-Host ($VersionInfo | ConvertTo-Json)

    # Get API version information
    $Version = $VersionInfo.apiversions | select-object -last 1

    Write-Host $Version

    $AutotaskBaseURI = Invoke-RestMethod -Uri "https://webservices.autotask.net/atservicesrest/$Version/zoneInformation?user=$Username"

    Write-Host $AutotaskBaseURI

    $AutotaskBaseUrl = $AutotaskBaseURI.url

    Write-Host $AutotaskBaseUrl

    $TicketNote = @{
        "publish" = 1
        "ticketId" = $TicketId
        "description" = $Text
        "title" = $Title
        "noteType" = 3
    } | ConvertTo-Json

    $TicketNoteUrl = "${AutotaskBaseUrl}${Version}/tickets/${TicketId}/notes"

    Write-Host $TicketNoteUrl

    $result = Invoke-RestMethod -Uri $TicketNoteUrl -Method Post -Headers $headers -Body $TicketNote

    Write-Host ($result | ConvertTo-Json)
    
    return $result
}

$TicketId = $Request.Body.TicketId
$Title = $Request.Body.Title
$Text = $Request.Body.Message
$SecurityKey = $env:SecurityKey

if ($SecurityKey -And $SecurityKey -ne $Request.Headers.SecurityKey) {
    Write-Host "Invalid security key"
    break;
}

if (-Not $TicketId) {
    Write-Host "Missing ticket number"
    break;
}
if (-Not $Title) {
    Write-Host "Missing ticket note title"
    break;
}
if (-Not $Text) {
    Write-Host "Missing ticket note text"
    break;
}

Write-Host "TicketId: $TicketId"
Write-Host "Title: $Title"
Write-Host "Text: $Text"

$result = Add-AutotaskTicketNote `
    -Username $env:AutotaskPsa_ApiUsername `
    -Secret $env:AutotaskPsa_ApiSecret `
    -IntegrationCode $env:AutotaskPsa_ApiIntegrationCode `
    -TicketId $TicketId `
    -Title $Title `
    -Text $Text

Write-Host $result.Message

$body = @{
    response = ($result | ConvertTo-Json);
} 

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    ContentType = "application/json"
})
