Import-Module Azure.Storage

# The following functions have been gratefully borrowed from this article: https://gallery.technet.microsoft.com/scriptcenter/InvokeTwitterAPIs-84cf88a3
# and used under the MIT license that is attributed to it

function Get-OAuth {
     <#
          .SYNOPSIS
           This function creates the authorization string needed to send a POST or GET message to the Twitter API
          .PARAMETER AuthorizationParams
           This hashtable should the following key value pairs
           HttpEndPoint - the twitter resource url [Can be found here: https://dev.twitter.com/rest/public]
           RESTVerb - Either 'GET' or 'POST' depending on the action
           Params - A hashtable containing the rest parameters (key value pairs) associated that method
           OAuthSettings - A hashtable that must contain only the following keys and their values (Generate here: https://dev.twitter.com/oauth)
                       ApiKey 
                       ApiSecret 
		               AccessToken
	                   AccessTokenSecret
          .LINK
           This function evolved from code found in Adam Betram's Get-OAuthAuthorization function in his MyTwitter module.
           The MyTwitter module can be found here: https://gallery.technet.microsoft.com/scriptcenter/Tweet-and-send-Twitter-DMs-8c2d6f0a
           Adam Betram's blogpost here: http://www.adamtheautomator.com/twitter-powershell/ provides a detailed explanation
           about how to generate an access token needed to create the authorization string 
          .EXAMPLE
            $OAuth = @{'ApiKey' = 'yourapikey'; 'ApiSecret' = 'yourapisecretkey';'AccessToken' = 'yourapiaccesstoken';'AccessTokenSecret' = 'yourapitokensecret'}	
            $Parameters = @{'q'='rumi'}
            $AuthParams = @{}
            $AuthParams.Add('HttpEndPoint', 'https://api.twitter.com/1.1/search/tweets.json')
            $AuthParams.Add('RESTVerb', 'GET')
            $AuthParams.Add('Params', $Parameters)
            $AuthParams.Add('OAuthSettings', $OAuth)
            $AuthorizationString = Get-OAuth -AuthorizationParams $AuthParams
          
     #>
    [OutputType('System.Management.Automation.PSCustomObject')]
    Param($AuthorizationParams)
    process{
    try {

    	    ## Generate a random 32-byte string. I'm using the current time (in seconds) and appending 5 chars to the end to get to 32 bytes
	        ## Base64 allows for an '=' but Twitter does not.  If this is found, replace it with some alphanumeric character
	        $OauthNonce = [System.Convert]::ToBase64String(([System.Text.Encoding]::ASCII.GetBytes("$([System.DateTime]::Now.Ticks.ToString())12345"))).Replace('=', 'g')
    	    ## Find the total seconds since 1/1/1970 (epoch time)
		    $EpochTimeNow = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact("01/01/1970", "dd'/'MM'/'yyyy", $null)
		    $OauthTimestamp = [System.Convert]::ToInt64($EpochTimeNow.TotalSeconds).ToString();
        	## Build the signature
			$SignatureBase = "$([System.Uri]::EscapeDataString($AuthorizationParams.HttpEndPoint))&"
			$SignatureParams = @{
				'oauth_consumer_key' = $AuthorizationParams.OAuthSettings.ApiKey;
				'oauth_nonce' = $OauthNonce;
				'oauth_signature_method' = 'HMAC-SHA1';
				'oauth_timestamp' = $OauthTimestamp;
				'oauth_token' = $AuthorizationParams.OAuthSettings.AccessToken;
				'oauth_version' = '1.0';
			}
	        $AuthorizationParams.Params.Keys | % { $SignatureParams.Add($_ , [System.Net.WebUtility]::UrlEncode($AuthorizationParams.Params.Item($_)).Replace('+','%20'))}
		 
			## Create a string called $SignatureBase that joins all URL encoded 'Key=Value' elements with a &
			## Remove the URL encoded & at the end and prepend the necessary 'POST&' verb to the front
			$SignatureParams.GetEnumerator() | sort name | foreach { $SignatureBase += [System.Uri]::EscapeDataString("$($_.Key)=$($_.Value)&") }

            $SignatureBase = $SignatureBase.Substring(0,$SignatureBase.Length-1)
            $SignatureBase = $SignatureBase.Substring(0,$SignatureBase.Length-1)
            $SignatureBase = $SignatureBase.Substring(0,$SignatureBase.Length-1)
			$SignatureBase = $AuthorizationParams.RESTVerb+'&' + $SignatureBase
			
			## Create the hashed string from the base signature
			$SignatureKey = [System.Uri]::EscapeDataString($AuthorizationParams.OAuthSettings.ApiSecret) + "&" + [System.Uri]::EscapeDataString($AuthorizationParams.OAuthSettings.AccessTokenSecret);
			
			$hmacsha1 = new-object System.Security.Cryptography.HMACSHA1;
			$hmacsha1.Key = [System.Text.Encoding]::ASCII.GetBytes($SignatureKey);
			$OauthSignature = [System.Convert]::ToBase64String($hmacsha1.ComputeHash([System.Text.Encoding]::ASCII.GetBytes($SignatureBase)));
			
			## Build the authorization headers using most of the signature headers elements.  This is joining all of the 'Key=Value' elements again
			## and only URL encoding the Values this time while including non-URL encoded double quotes around each value
			$AuthorizationParams = $SignatureParams
			$AuthorizationParams.Add('oauth_signature', $OauthSignature)
		
			$AuthorizationString = 'OAuth '
			$AuthorizationParams.GetEnumerator() | sort name | foreach { $AuthorizationString += $_.Key + '="' + [System.Uri]::EscapeDataString($_.Value) + '", ' }
			$AuthorizationString = $AuthorizationString.TrimEnd(', ')
            Write-Verbose "Using authorization string '$AuthorizationString'"			
			$AuthorizationString
        }
        catch {
			Write-Error $_.Exception.Message
		}
     }
}

function Invoke-TwitterRestMethod {
<#
          .SYNOPSIS
           This function sends a POST or GET message to the Twitter API and returns the JSON response. 

          .PARAMETER ResourceURL
           The desired twitter resource url [REST APIs can be found here: https://dev.twitter.com/rest/public]
           
          .PARAMETER RestVerb
           Either 'GET' or 'POST' depending on the resource URL

           .PARAMETER  Parameters
           A hashtable containing the rest parameters (key value pairs) associated that resource url. Pass empty hash if no paramters needed.

           .PARAMETER OAuthSettings 
           A hashtable that must contain only the following keys and their values (Generate here: https://dev.twitter.com/oauth)
                       ApiKey 
                       ApiSecret 
		               AccessToken
	                   AccessTokenSecret

           .EXAMPLE
            $OAuth = @{'ApiKey' = 'yourapikey'; 'ApiSecret' = 'yourapisecretkey';'AccessToken' = 'yourapiaccesstoken';'AccessTokenSecret' = 'yourapitokensecret'}
            Invoke-TwitterRestMethod -ResourceURL 'https://api.twitter.com/1.1/statuses/mentions_timeline.json' -RestVerb 'GET' -Parameters @{} -OAuthSettings $OAuth 
            Invoke-TwitterRestMethod -ResourceURL 'https://api.twitter.com/1.1/statuses/user_timeline.json' -RestVerb 'GET' -Parameters @{'count' = '1'} -OAuthSettings $OAuth 
            Invoke-TwitterRestMethod -ResourceURL 'https://api.twitter.com/1.1/statuses/home_timeline.json' -RestVerb 'GET' -Parameters @{'count' = '1'} -OAuthSettings $OAuth 
            Invoke-TwitterRestMethod -ResourceURL 'https://api.twitter.com/1.1/statuses/retweets_of_me.json' -RestVerb 'GET' -Parameters @{} -OAuthSettings $OAuth 
            Invoke-TwitterRestMethod -ResourceURL 'https://api.twitter.com/1.1/search/tweets.json' -RestVerb 'GET' -Parameters @{'q'='powershell';'count' = '1'}} -OAuthSettings $OAuth
            Invoke-TwitterRestMethod -ResourceURL 'https://api.twitter.com/1.1/account/settings.json' -RestVerb 'POST' -Parameters @{'lang'='tr'} -OAuthSettings $OAuth 
            Invoke-TwitterRestMethod -ResourceURL 'https://api.twitter.com/1.1/statuses/retweets/509457288717819904.json' -RestVerb 'GET' -Parameters @{} -OAuthSettings $OAuth
            Invoke-TwitterRestMethod -ResourceURL 'https://api.twitter.com/1.1/statuses/show.json' -RestVerb 'GET' -Parameters @{'id'='123'} -OAuthSettings $OAuth 
            Invoke-TwitterRestMethod -ResourceURL 'https://api.twitter.com/1.1/statuses/destroy/240854986559455234.json' -RestVerb 'GET' -Parameters @{} -OAuthSettings $OAuth 
            Invoke-TwitterRestMethod -ResourceURL 'https://api.twitter.com/1.1/statuses/update.json' -RestVerb 'POST' -Parameters @{'status'='@FollowBot'} -OAuthSettings $OAuth 
            Invoke-TwitterRestMethod -ResourceURL 'https://api.twitter.com/1.1/direct_messages.json' -RestVerb 'GET' -Parameters @{} -OAuthSettings $OAuth 
            Invoke-TwitterRestMethod -ResourceURL 'https://api.twitter.com/1.1/direct_messages/destroy.json' -RestVerb 'POST' -Parameters @{'id' = '559298305029844992'} -OAuthSettings $OAuth 
            Invoke-TwitterRestMethod -ResourceURL 'https://api.twitter.com/1.1/direct_messages/new.json' -RestVerb 'POST' -Parameters @{'text' = 'hello, there'; 'screen_name' = 'ruminaterumi' } -OAuthSettings $OAuth 
            $mediaId = Invoke-TwitterMEdiaUpload -MediaFilePath 'C:\Books\pic.png' -ResourceURL 'https://upload.twitter.com/1.1/media/upload.json' -OAuthSettings $OAuth 
            Invoke-TwitterRestMethod -ResourceURL 'https://api.twitter.com/1.1/statuses/update.json' -RestVerb 'POST' -Parameters @{'status'='FollowBot'; 'media_ids' = $mediaId } -OAuthSettings $OAuth 

     #>
         [CmdletBinding()]
	     [OutputType('System.Management.Automation.PSCustomObject')]
         Param(
                [Parameter(Mandatory)]
                [string]$ResourceURL,
                [Parameter(Mandatory)]
                [string]$RestVerb,
                [Parameter(Mandatory)]
                $Parameters,
                [Parameter(Mandatory)]
                $OAuthSettings

                )

          process{
              try{

                    $AuthParams = @{}
                    $AuthParams.Add('HttpEndPoint', $ResourceURL)
                    $AuthParams.Add('RESTVerb', $RestVerb)
                    $AuthParams.Add('Params', $Parameters)
                    $AuthParams.Add('OAuthSettings', $OAuthSettings)
                    $AuthorizationString = Get-OAuth -AuthorizationParams $AuthParams                 
                    $HTTPEndpoint= $ResourceURL
                    if($Parameters.Count -gt 0)
                    {
                        $HTTPEndpoint = $HTTPEndpoint + '?'
                        $Parameters.Keys | % { $HTTPEndpoint = $HTTPEndpoint + $_  +'='+ [URI]::ESCAPEDATASTRING($PARAMETERs.Item($_)).Replace('+','%20') + '&'}
                        $HTTPEndpoint = $HTTPEndpoint.Substring(0,$HTTPEndpoint.Length-1)
  
                    }
                    Invoke-RestMethod -URI $HTTPEndpoint -Method $RestVerb -Headers @{ 'Authorization' = $AuthorizationString } -ContentType "application/x-www-form-urlencoded" 
                  }
                  catch{
                    Write-Error $_.Exception.Message
                  }
            }
}

$twitterAccounts = @(
    'cakebuildnet', 'cakecontrib'
);

$batched    = [System.DateTimeOffset]::Now
$date       = Get-Date -format 'yyyy-MM-dd_HHmmss'
$ctx        = New-AzureStorageContext -ConnectionString $env:AzureWebJobsStorage
$container  = Get-AzureStorageContainer –Name 'twitterstats' -Context $ctx -ErrorAction Ignore

if ($container -eq $null)
{
    $container = New-AzureStorageContainer -Name 'twitterstats' -Context $ctx
}

$containerName = $container.Name

$OAuth = @{
    'ApiKey' = $env:TWITTER_CONSUMER_KEY;
    'ApiSecret' = $env:TWITTER_CONSUMER_KEY_SECRET;
    'AccessToken' = $env:TWITTER_ACCESS_TOKEN;
    'AccessTokenSecret' = $env:TWITTER_ACCESS_TOKEN_SECRET;
}

$twitterAccountsString = $twitterAccounts -Join ","

"Begin $twitterData $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$partitionKey           = [Guid]::NewGuid().ToString("n")
$twitterData            = Invoke-TwitterRestMethod -ResourceURL 'https://api.twitter.com/1.1/users/lookup.json' -RestVerb 'GET' -Parameters @{'screen_name' = $twitterAccountsString } -OAuthSettings $OAuth `
                            | ForEach-Object { $_ } `
                                | ForEach-Object {
                                    [PSCustomObject][Ordered]@{
                                        'FileType'          = 'twitter'
                                        'RowKey'            = $_.id_str
                                        'PartitionKey'      = $partitionKey
                                        'Batched'           = $batched
                                        'Exported'          = [System.DateTimeOffset]::Now
                                        'ScreenName'        = $_.screen_name
                                        'Followers'         = $_.followers_count
                                        'Friends'           = $_.friends_count
                                        'Listed'            = $_.listed_count
                                        'Favourites'        = $_.favourites_count
                                        'Tweets'            = $_.statuses_count
                                    }}

if ($twitterData -eq $null)
{
    $twitterData = ("No Twitter data found for $twitterAccount")
}

$file = "$($ENV:TEMP)\twitter-$date.csv"
$blob = "twitter-$date.csv"
$twitterData | Export-Csv -Path $file -NoTypeInformation -Encoding UTF8
Set-AzureStorageBlobContent -Container $containerName -Context $ctx -File $file -Blob $blob | Out-Null
Remove-Item $file
"End $twitterData $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"