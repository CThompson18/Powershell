Function Get-Token ($credentials,[Switch] $UseTwoFactor)
{
    #$application = "https://THE URL TO YOUR RESOURCE"
    $application = "https://slcisss.slcounty.org/SecretServer"

    $creds = @{
        username = $credentials.UserName
        password = $credentials.GetNetworkCredential().Password
        grant_type = "password"
    };

    $headers = $null
    If ($UseTwoFactor) {
        $headers = @{
            "OTP" = (Read-Host -Prompt "Enter your OTP for 2FA: ")
        }
    }
    try
    {
        $response = Invoke-RestMethod "$application/oauth2/token" -Method Post -Body $creds -Headers $headers;
        $token = $response.access_token;
        return $token;
    }
    catch
    {
        $result = $_.Exception.Response.GetResponseStream();
        $reader = New-Object System.IO.StreamReader($result);
        $reader.BaseStream.Position = 0;
        $reader.DiscardBufferedData();
        $responseBody = $reader.ReadToEnd() | ConvertFrom-Json
        Write-Host "ERROR: $($responseBody.error)"
        return;
    }
}

Function getSecret([string]$requiredSecretId,[string]$requestUsername,[secureString]$requestPassword){
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12    

if($requestUsername -ne $null -and $requestPassword -ne $null){
    $credentials = New-Object System.Management.Automation.PSCredential ("YOUR DOMAIN\YOUR SERVICE ACCOUNT", $requestPassword)
    } else {
    $credentials = Get-Credential
    }

    $token = Get-Token $credentials
    if(-not [string]::IsNullOrEmpty($token)){
    $api = "https://YOUR RESOURCE/PATH"
    $filters = "?filter.searchtext=< mySearchText >"
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $token")
    $result = Invoke-WebRequest -Method Get -Uri $api -Headers $headers
    $information = $result.items
    ForEach($_ in $information){
        if($_.fieldName -eq "Username"){
            $username = $_.itemValue
        }
        if($_.fieldName -eq "Password"){
            $password = ConvertTo-SecureString $_.itemValue -AsPlainText -Force
        }
    }
    $credentials = New-Object System.Management.Automation.PSCredential ($username, $password)
    return $credentials
    } else {
        Write-Host "Request was not able to retrieve a token, check the login credentials"
        return;
    }
}
