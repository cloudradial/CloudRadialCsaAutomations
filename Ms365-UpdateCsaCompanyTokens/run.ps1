<#

.SYNOPSIS

    This function is used to update the company tokens in CloudRadial from a Microsoft 365 tenant.

.DESCRIPTION
    
    This function is used to update the company tokens in CloudRadial from a Microsoft 365 tenant.
    
    The function requires the following environment variables to be set:
    
    Ms365_AuthAppId - Application Id of the Azure AD application
    Ms365_AuthSecretId - Secret Id of the Azure AD application
    Ms365_TenantId - Tenant Id of the Azure AD application
    CloudRadialCsa_ApiPublicKey - Public Key of the CloudRadial API
    CloudRadialCsa_ApiPrivateKey - Private Key of the CloudRadial API
    SecurityKey - Optional, use this as an additional step to secure the function

    The function requires the following modules to be installed:
    
    Microsoft.Graph     

.INPUTS

    CompanyId - numeric company id
    TenantId - string value of the tenant id, if blank uses the environment variable Ms365_TenantId
    SecurityKey - Optional, use this as an additional step to secure the function

    JSON Structure

    {
        "CompanyId": "12"
        "TenantId": "12345678-1234-1234-1234-123456789012",
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

function Set-CloudRadialToken {
    param (
        [string]$Token,
        [string]$AppId,
        [string]$SecretId,
        [int]$CompanyId,
        [string]$GroupList
    )

    Write-Host $AppId

    Write-host $SecretId

    Write-Host $CompanyId

    Write-Host $GroupList

    # Construct the basic authentication header
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${AppId}:${SecretId}"))
    $headers = @{
        "Authorization" = "Basic $base64AuthInfo"
        "Content-Type" = "application/json"
    }

write-host $base64AuthInfo

    $body = @{
        "companyId" = $CompanyId
        "token" = "$Token"
        "value" = "$GroupList"
    }

    $bodyJson = $body | ConvertTo-Json

    # Replace the following URL with the actual REST API endpoint
    $apiUrl = "https://api.us.cloudradial.com/api/beta/token"

    $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Body $bodyJson -Method Post

    Write-Host "API response: $($response | ConvertTo-Json -Depth 4)"
}

$companyId = $Request.Body.CompanyId
$tenantId = $Request.Body.TenantId
$SecurityKey = $env:SecurityKey

if ($SecurityKey -And $SecurityKey -ne $Request.Headers.SecurityKey) {
    Write-Host "Invalid security key"
    break;
}

if (-Not $companyId) {
    $companyId = 1
}

if (-Not $tenantId) {
    $tenantId = $env:Ms365_TenantId
}

$resultCode = 200
$message = ""

$secure365Password = ConvertTo-SecureString -String $env:Ms365_AuthSecretId -AsPlainText -Force
$credential365 = New-Object System.Management.Automation.PSCredential($env:Ms365_AuthAppId, $secure365Password)

Connect-MgGraph -ClientSecretCredential $credential365 -TenantId $tenantId

# Get all groups in the tenant
$groupList = Get-MgGroup -All

# Extract group names
$groupNames = $groupList | Select-Object -ExpandProperty DisplayName

# Convert the array of group names to a comma-separated string
$groupNamesString = $groupNames -join ","

Set-CloudRadialToken -Token "CompanyGroups" -AppId $env:CloudRadialCsa_ApiPublicKey -SecretId $env:CloudRadialCsa_ApiPrivateKey -CompanyId $companyId -GroupList $groupNamesString

Write-Host "Updated CompanyGroups for Company Id: $companyId."

# Get the list of domains
$domains = Get-MgDomain

$domainNames = $domains | Select-Object -ExpandProperty Id

$domainNamesString = $domainNames -join ","

Set-CloudRadialToken -Token "CompanyDomains" -AppId $$env:CloudRadialCsa_ApiPublicKey -SecretId $env:CloudRadialCsa_ApiPrivateKey -CompanyId $companyId -GroupList $domainNamesString

Write-Host "Updated CompanyDomains for Company Id: $companyId."

$message = "Company tokens for $comanyId have been updated."

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

