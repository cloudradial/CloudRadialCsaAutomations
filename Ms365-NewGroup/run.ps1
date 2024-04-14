<# 

.SYNOPSIS
    
    This function is to create a new group in Microsoft 365.

.DESCRIPTION
    
    This function is to create a new group in Microsoft 365.
    
    The function requires the following environment variables to be set:
    
    Ms365_AuthAppId - Application Id of the service principal
    Ms365_AuthSecretId - Secret Id of the service principal
    Ms365_TenantId - Tenant Id of the Microsoft 365 tenant
    SecurityKey - Optional, use this as an additional step to secure the function
 
    The function requires the following modules to be installed:
    
    Microsoft.Graph
    
.INPUTS

    GroupName - group name to create
    GroupDescription - group description
    TenantId - string value of the tenant id, if blank uses the environment variable Ms365_TenantId
    TicketId - optional - string value of the ticket id used for transaction tracking
    SecurityKey - Optional, use this as an additional step to secure the function

    JSON Structure

    {
        "GroupName": "Group Name",
        "GroupDescription": "Group Description",
        "TenantId": "12345678-1234-1234-123456789012",
        "TicketId": "123456,
        "SecurityKey", "optional"
    }

.OUTPUTS

    JSON response with the following fields:

    Message - Descriptive string of result
    TicketId - TicketId passed in Parameters
    ResultCode - 200 for success, 500 for failure
    ResultStatus - "Success" or "Failure"

#>

using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "NewGroup function triggered."

$resultCode = 200
$message = ""

$GroupName = $Request.Body.GroupName
$GroupDescription = $Request.Body.GroupDescription
$TenantId = $Request.Body.TenantId
$TicketId = $Request.Body.TicketId
$SecurityKey = $env:SecurityKey

if ($SecurityKey -And $SecurityKey -ne $Request.Headers.SecurityKey) {
    Write-Host "Invalid security key"
    break;
}

if (-Not $GroupName) {
    $message = "GroupName cannot be blank."
    $resultCode = 500
}
else {
    $GroupName = $GroupName.Trim()
}

if (-Not $GroupDescription) {
    $message = "GroupDescription cannot be blank."
    $resultCode = 500
}
else {
    $GroupDescription = $GroupDescription.Trim()
}

if (-Not $TenantId) {
    $TenantId = $env:Ms365_TenantId
}
else {
    $TenantId = $TenantId.Trim()
}

if (-Not $TicketId) {
    $TicketId = ""
}

Write-Host "Group Name: $GroupName"
Write-Host "Group Description: $GroupDescription"
Write-Host "Tenant Id: $TenantId"
Write-Host "Ticket Id: $TicketId"

if ($resultCode -Eq 200) {
    $secure365Password = ConvertTo-SecureString -String $env:Ms365_AuthSecretId -AsPlainText -Force
    $credential365 = New-Object System.Management.Automation.PSCredential($env:Ms365_AuthAppId, $secure365Password)

    Connect-MgGraph -ClientSecretCredential $credential365 -TenantId $TenantId

    $GroupObject = Get-MgGroup -Filter "displayName eq '$GroupName'"

    if (-Not $GroupObject) {
        $message = "Group Name already exists."
        $resultCode = 500
    }

    $GroupObject = New-MgGroup -DisplayName $GroupName -Description $GroupDescription -MailEnabled $true -MailNickname $GroupName -SecurityEnabled $true

    if (-Not $GroupObject) {
        $message = "Request failed. Could not create group `"$GroupName`"."
        $resultCode = 500
    }

    if ($resultCode -Eq 200) {
        $message = "Request completed. `"$GroupName`" has been created."
    }
}

$body = @{
    Message      = $message
    TicketId     = $TicketId
    ResultCode   = $resultCode
    ResultStatus = if ($resultCode -eq 200) { "Success" } else { "Failure" }
} 

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode  = [HttpStatusCode]::OK
        Body        = $body
        ContentType = "application/json"
    })
