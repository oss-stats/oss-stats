$requestBody = Get-Content $req -Raw | ConvertFrom-Json


$packages = $requestBody `
    | ForEach-Object owners `
    | ForEach-Object {
            $owner = $_
            Invoke-RestMethod "https://www.nuget.org/profiles/$($owner)?showAllPackages=true" `
                | Select-String -Pattern '<a\s+(?:[^>]*?\s+)?href="/packages/([^"]*)/"' -AllMatches `
                | ForEach-Object Matches `
                | ForEach-Object {
                    $_.Groups[1].Value
                } `
                | Group-Object -NoElement `
                | ForEach-Object Name `
                | ForEach-Object {
                    [PSCustomObject][Ordered]@{
                        'owner' = $owner
                        'packageId' = $_
                    }
                  }
      } `
    

$result = [PSCustomObject][Ordered]@{
    'Status'    = 200
    'Headers'   = [PSCustomObject][Ordered]@{
                    'content-type' = 'application/json'
                  }
    'Body'      =  $packages 
} | ConvertTo-Json -Depth 5

$result | Out-File -Encoding utf8 -FilePath $res
#if ($req_query_name) 
#{
#    $name = $req_query_name 
#}

#Out-File -Encoding Ascii -FilePath $res -inputObject "Hello $name"