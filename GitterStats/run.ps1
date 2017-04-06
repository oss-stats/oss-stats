Import-Module Azure.Storage

# These should really be moved out into some form of configuration
$rooms = @(
);

$groups = @(
    '57542ccdc43b8c6019776af0'
);

$batched        = [System.DateTimeOffset]::Now
$date           = Get-Date -format 'yyyy-MM-dd_HHmmss'
$ctx            = New-AzureStorageContext -ConnectionString $env:AzureWebJobsStorage
$container      = Get-AzureStorageContainer –Name 'gitterstats' -Context $ctx -ErrorAction Ignore
$partitionKey   = [Guid]::NewGuid().ToString("n")

if ($container -eq $null)
{
    $container = New-AzureStorageContainer -Name 'gitterstats' -Context $ctx
}

$containerName = $container.Name

$headers = @{
    'Content-Type' = 'application\json'
    'Accept' = 'application\json'
    'Authorization' = "Bearer $env:GITTER_TOKEN"
}

foreach($room in $rooms) {
    "Begin $room $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    $gitterData = Invoke-RestMethod -Uri "https://api.gitter.im/v1/users/$room/rooms" -ErrorAction SilentlyContinue -Headers $headers `
        | ForEach-Object { $_ } `
            | ForEach-Object {
                [PSCustomObject][Ordered]@{
                    'FileType'      = 'gitter'
                    'RowKey'        = $_.id
                    'PartitionKey'  = $_.groupId
                    'Batched'       = $batched
                    'Exported'      = [System.DateTimeOffset]::Now
                    'Name'          = $_.name
                    'UserCount'     = $_.userCount
                    'Favourite'     = $_.favourite
                    'public'        = $_.public
            }}

    if ($gitterData -eq $null)
    {
        $gitterData = ("No room data found for gitter room")
        $gitterData
    }

    $file = "$($ENV:TEMP)\$room-$date.csv"
    $blob = "$room/$room-$date.csv"
    $gitterData | Export-Csv -Path $file -NoTypeInformation -Encoding UTF8
    Set-AzureStorageBlobContent -Container $containerName -Context $ctx -File $file -Blob $blob | Out-Null
    Remove-Item $file
    "End $room $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}

foreach($group in $groups) {
    "Begin $group $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    $gitterData = Invoke-RestMethod -Uri "https://api.gitter.im/v1/groups/$group/rooms" -ErrorAction SilentlyContinue -Headers $headers `
        | ForEach-Object { $_ } `
            | ForEach-Object {
                [PSCustomObject][Ordered]@{
                    'FileType'      = 'gitter'
                    'RowKey'        = $_.id
                    'PartitionKey'  = $_.groupId
                    'Batched'       = $batched
                    'Exported'      = [System.DateTimeOffset]::Now
                    'Name'          = $_.name
                    'UserCount'     = $_.userCount
                    'Favourite'     = $_.favourite
                    'public'        = $_.public
            }}

    if ($gitterData -eq $null)
    {
        $gitterData = ("No group data found for gitter group")
        $gitterData
    }

    $file = "$($ENV:TEMP)\$group-$date.csv"
    $blob = "$group/$group-$date.csv"
    $gitterData | Export-Csv -Path $file -NoTypeInformation -Encoding UTF8
    Set-AzureStorageBlobContent -Container $containerName -Context $ctx -File $file -Blob $blob | Out-Null
    Remove-Item $file
    "End $group $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}