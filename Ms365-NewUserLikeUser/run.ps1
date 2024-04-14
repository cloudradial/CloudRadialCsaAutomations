<# 

.SYNOPSIS
    
    This function is used to add a note to a ConnectWise ticket.

.DESCRIPTION

    This function creates a new user in the tenant with the same licenses and group memberships as an existing user.

    The function requires the following environment variables to be set:

    Ms365_AuthAppId - Application Id of the service principal
    Ms365_AuthSecretId - Secret Id of the service principal
    Ms365_TenantId - Tenant Id of the Microsoft 365 tenant
    SecurityKey - Optional, use this as an additional step to secure the function

    The function requires the following modules to be installed:
    
    Microsoft.Graph

.INPUTS

    UserEmail - user email address that exists in the tenant
    GroupName - group name that exists in the tenant
    TenantId - string value of the tenant id, if blank uses the environment variable Ms365_TenantId
    TicketId - optional - string value of the ticket id used for transaction tracking
    SecurityKey - Optional, use this as an additional step to secure the function

    JSON Structure

    {
        "UserEmail": "email@address.com",
        "GroupName": "Group Name",
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

Write-Host "Create User Like Another User function triggered."

$resultCode = 200
$message = ""

$NewUserEmail = $Request.Body.NewUserEmail
$ExistingUserEmail = $Request.Body.ExistingUserEmail
$NewUserFirstName = $Request.Body.NewUserFirstName
$NewUserLastName = $Request.Body.NewUserLastName
$NewUserDisplayName = $Request.Body.NewUserDisplayName
$TenantId = $Request.Body.TenantId
$TicketId = $Request.Body.TicketId
$SecurityKey = $env:SecurityKey

if ($SecurityKey -And $SecurityKey -ne $Request.Headers.SecurityKey) {
    Write-Host "Invalid security key"
    break;
}

if (-Not $userEmail) {
    $message = "UserEmail cannot be blank."
    $resultCode = 500
}
else {
    $UserEmail = $UserEmail.Trim()
}

if (-Not $groupName) {
    $message = "GroupName cannot be blank."
    $resultCode = 500
}
else {
    $GroupName = $GroupName.Trim()
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

Write-Host "User Email: $UserEmail"
Write-Host "Group Name: $GroupName"
Write-Host "Tenant Id: $TenantId"
Write-Host "Ticket Id: $TicketId"

if ($resultCode -Eq 200) {
    $secure365Password = ConvertTo-SecureString -String $env:Ms365_AuthSecretId -AsPlainText -Force
    $credential365 = New-Object System.Management.Automation.PSCredential($env:Ms365_AuthAppId, $secure365Password)

    Connect-MgGraph -ClientSecretCredential $credential365 -TenantId $TenantId

    # Define the existing user's UserPrincipalName (UPN) and the new user's UPN
    $existingUserUpn = $ExistingUserEmail
    $newUserUpn = $NewUserEmail

    # Retrieve the existing user's details
    $existingUser = Get-MgUser -UserPrincipalName $existingUserUpn

    if (-Not $existingUser) {
        $message = "Request failed. User `"$ExistingUserEmail`" could not be found."
        $resultCode = 500
    }

    # Check if the existing user has any assigned licenses
    if ($existingUser.AssignedLicenses.Count -eq 0) {
        Write-Host "The existing user `"$ExistingUserEmail`" does not have any assigned licenses."
    }
    else {
        # Retrieve all available licenses
        $availableLicenses = Get-MgSubscribedSku

        # Check if the available licenses match the existing user's licenses
        $existingUserLicenseIds = $existingUser.AssignedLicenses.SkuId
        $missingLicenses = $availableLicenses | Where-Object { $existingUserLicenseIds -notcontains $_.SkuId }

        if ($missingLicenses.Count -gt 0) {
            Write-Host "The following licenses are missing for the new user:"
            $missingLicenses | ForEach-Object {
                Write-Host "- $($_.SkuPartNumber)"
            }
            $resultCode = 500
            $message = "Request failed. The existing user `"$ExistingUserEmail`" has licenses that are not available for the new user."
    }

    if ($resultCode -eq 200) {
        # Create the new user
        $newUser = New-MgUser -UserPrincipalName $newUserUpn -DisplayName $NewUserDisplayName -GivenName $NewUserFirstName -Surname $NewUserLastName

        # Assign the same licenses as the existing user
        $existingUser.AssignedLicenses | ForEach-Object {
            Set-MgUserLicense -UserId $newUser.Id -AddLicenses @{ SkuId = $_.SkuId }
        }

        # Add the new user to specified groups (replace with actual group IDs)
        $groupIds = @("group1-id", "group2-id")
        $groupIds | ForEach-Object {
            New-MgGroupMember -GroupId $_ -DirectoryObjectId $newUser.Id
        }

        $message = "New user `"$NewUserEmail`" created successfully and assigned licenses and added to groups like user `"$ExistingUserEmail`"."
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
