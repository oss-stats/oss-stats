Import-Module Azure.Storage

$individuals = @(
);

$organisations = @(
    'cake-build',
    'cake-contrib'
);

$batched    = [System.DateTimeOffset]::Now
$date       = Get-Date -format 'yyyy-MM-dd_HHmmss'
$ctx        = New-AzureStorageContext -ConnectionString $env:AzureWebJobsStorage
$container  = Get-AzureStorageContainer –Name 'githubstats' -Context $ctx -ErrorAction Ignor

if ($container -eq $null)
{
    $container = New-AzureStorageContainer -Name 'githubstats' -Context $ctx
}
$containerName = $container.Name

$Token = "$env:GITHUB_USERNAME:$env:GITHUB_PASSWORD"
$Base64Token = [System.Convert]::ToBase64String([char[]]$Token)

$Headers = @{
    Authorization = 'Basic {0}' -f $Base64Token
};

foreach ($individual in $individuals)
{
    "Begin $individual $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $individualName = $individual.ToLower()

    $repositories = Invoke-RestMethod -Headers $Headers -Uri "https://api.github.com/users/$individual/repos?per_page=100" -Method GET `
        | ForEach-Object { $_ } `
            | ForEach-Object {
                [PSCustomObject][Ordered]@{
                    'FileType'          = 'github'
                    'RowKey'            = $_.id
                    'PartitionKey'      = $individualName
                    'Batched'           = $batched
                    'Exported'          = [System.DateTimeOffset]::Now
                    'FullName'          = $_.full_name
                    'ForksCount'        = $_.forks_count
                    'StargazersCount'   = $_.stargazers_count
                    'WatchersCount'     = $_.watchers_count
                    'OpenIssuesCount'   = $_.open_issues_count
            }}

    if ($repositories -eq $null)
    {
        $repositories = ("No repository data found for $individual")
    }

    $file = "$($ENV:TEMP)\$individualName-$date.csv"
    $blob = "$individualName/$individualName-$date.csv"
    $repositories | Export-Csv -Path $file -NoTypeInformation -Encoding UTF8
    Set-AzureStorageBlobContent -Container $containerName -Context $ctx -File $file -Blob $blob | Out-Null
    Remove-Item $file
    "End $individual $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}

foreach ($organisation in $organisations)
{
    "Begin $organisation $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $organisationName = $organisation.ToLower()

    $repositories = Invoke-RestMethod -Headers $Headers -Uri "https://api.github.com/orgs/$organisation/repos?per_page=100" -Method GET `
        | ForEach-Object { $_ } `
            | ForEach-Object {
                [PSCustomObject][Ordered]@{
                    'FileType'          = 'github'
                    'RowKey'            = $_.id
                    'PartitionKey'      = $organisationName
                    'Batched'           = $batched
                    'Exported'          = [System.DateTimeOffset]::Now
                    'FullName'          = $_.full_name
                    'ForksCount'        = $_.forks_count
                    'StargazersCount'   = $_.stargazers_count
                    'WatchersCount'     = $_.watchers_count
                    'OpenIssuesCount'   = $_.open_issues_count
            }}

    if ($repositories -eq $null)
    {
        $repositories = ("No repository data found for $organisation")
        $repositories
    }

    $file = "$($ENV:TEMP)\$organisationName-$date.csv"
    $blob = "$organisationName/$organisationName-$date.csv"
    $repositories | Export-Csv -Path $file -NoTypeInformation -Encoding UTF8
    Set-AzureStorageBlobContent -Container $containerName -Context $ctx -File $file -Blob $blob | Out-Null
    Remove-Item $file
    "End $organisation $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}