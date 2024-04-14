<# 

.SYNOPSIS

    This function is used to create a new password and send it to the user using the PwPush API

.DESCRIPTION

    This function is used to create a new password and send it to the user using the PwPush API.

    It is a demonstration of using the PwPush API and can be adapted as needed.

    The function requires the following environment variables to be set:

    PwPush_ApiEmail - Email address of the PwPush API user
    PwPush_ApiKey - API Key
    SecurityKey - Optional, use this as an additional step to secure the function

.INPUTS

    TicketId - optional - string value of the ticket id used for transaction tracking
    SecurityKey - optional security key to secure the function

    JSON Structure

    {
        "TicketId": "123456",
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


function Create-PwPushLink {
    param (
        [string]$Password,
        [int]$DaysToExpire = 7,
        [int]$ViewsToExpire = 5
    )

    # PwPush Urls, change for privately hosted instances
    $apiUrl = "https://pwpush.com/p.json"
    $retrievalUrl = "https://pwpush.com/en/p/"

    # Set up the authentication headers
    $headers = @{
        "Content-Type" = "application/json"
        "X-User-Email" = $env:PwPush_ApiEmail
        "X-User-Token" = $env:PwPush_ApiKey
    }

    # Create the password payload
    $passwordPayload = @{
        password = @{
            payload = $Password
            expire_after_days = $DaysToExpire
            expire_after_views = $ViewsToExpire
        }
    } | ConvertTo-Json

    Write-Host $passwordPayload

    # Make the API request to create the new link
    $result = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $passwordPayload -Headers $headers -ContentType "application/json"
    
    Write-Host $result

    return $retrievalUrl + $result.url_token

}

function Generate-RandomPassword {
    param (
        [int]$Length = 10
    )

    $lowercase = "abcdefghijklmnopqrstuvwxyz"
    $uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $numbers = "1234567890"
    $special = "!@#$%^&*()"

    # Ensure the password contains at least one of each type of character
    $password = @(
        Get-Random -InputObject $lowercase.ToCharArray()
        Get-Random -InputObject $uppercase.ToCharArray()
        Get-Random -InputObject $numbers.ToCharArray()
        Get-Random -InputObject $special.ToCharArray()
    )

    # Fill the rest of the password length with random characters from the entire set
    for ($i = $password.Length; $i -lt $Length; $i++) {
        $password += Get-Random -InputObject ($lowercase + $uppercase + $numbers + $special).ToCharArray()
    }

    # Shuffle the characters in the password to ensure randomness
    $password = Get-Random -InputObject $password -Count $password.Length

    return -join $password
}

$TicketId = $Request.Body.TicketId
$SecurityKey = $env:SecurityKey

if ($SecurityKey -And $SecurityKey -ne $Request.Headers.SecurityKey) {
    Write-Host "Invalid security key"
    break;
}

if (-Not $TicketId) {
    $TicketId = ""
}

$password = Generate-RandomPassword

Write-Host "Generated password: $password"

$resultUrl = Create-PwPushLink -PwPushUrl $env:PwPush_APIUrl -Password $password

Write-Host "Result URL: $resultUrl"

$message = "Retrieve the new password from the following link: " + $resultUrl

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




