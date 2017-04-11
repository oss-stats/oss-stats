Import-Module Azure.Storage

$packages = @(
    'cake.portable',
    'cake-bootstrapper',
    'vscode-cake'
)

$batched    = [System.DateTimeOffset]::Now
$date       = Get-Date -format 'yyyy-MM-dd_HHmmss'
$ctx        = New-AzureStorageContext -ConnectionString $env:AzureWebJobsStorage
$container  = Get-AzureStorageContainer –Name 'chocolateystats' -Context $ctx -ErrorAction Ignore

if ($container -eq $null)
{
    $container = New-AzureStorageContainer -Name 'chocolateystats' -Context $ctx
}
$containerName = $container.Name

foreach ($package in $packages)
{
    "Begin $package $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $partitionKey   = [Guid]::NewGuid().ToString("n")
    $packageName    = $package.ToLower()
    $url            = "https://chocolatey.org/api/v2/FindPackagesById()?Id='$package'"
    $packageData    = Invoke-RestMethod `
                        -Uri $url `
                        -ErrorAction SilentlyContinue `
                        | ForEach-Object properties `
                        | ForEach-Object {
                            [string] $packageVersion                    = ''
                            [string] $packageDownloads                  = ''
                            [string] $packageTotalDownloads             = ''
                            [string] $packageSize                       = ''
                            [string] $packageIsLatestVersion            = ''
                            [string] $packageAbsoluteIsLatestVersion    = ''
                            [string] $packageIsPreRelease               = ''
                            [string] $packageLastUpdated                = ''
                            [string] $packagePublished                  = ''
                            [string] $packageLastEdited                 = ''
                            [string] $packageMinClientVersion           = ''
                            [string] $packageHash                       = ''
                            [string] $packageHashAlgorithm              = ''

                            $packageVersion                 = $_`
                                                                | ForEach-Object Version

                            $packageDownloads               = $_`
                                                                | ForEach-Object VersionDownloadCount `
                                                                | ForEach-Object '#text'

                            $packageTotalDownloads          = $_`
                                                                | ForEach-Object DownloadCount `
                                                                | ForEach-Object '#text'

                            $packageSize                    = $_`
                                                                | ForEach-Object PackageSize `
                                                                | ForEach-Object '#text'

                            $packageIsLatestVersion         = $_`
                                                                | ForEach-Object IsLatestVersion `
                                                                | ForEach-Object '#text'

                            $packageAbsoluteIsLatestVersion = $_`
                                                                | ForEach-Object IsAbsoluteLatestVersion `
                                                                | ForEach-Object '#text'

                            $packageIsPreRelease            = $_`
                                                                | ForEach-Object IsPrerelease  `
                                                                | ForEach-Object '#text'

                            $packageLastUpdated             = $_`
                                                                | ForEach-Object LastUpdated `
                                                                | ForEach-Object '#text'

                            $packagePublished               = $_`
                                                                | ForEach-Object Published `
                                                                | ForEach-Object '#text'

                            $packageHash                    = $_`
                                                                | ForEach-Object PackageHash

                            $packageHashAlgorithm           = $_`
                                                                | ForEach-Object PackageHashAlgorithm

                            $packageMinClientVersion        = $_`
                                                                | ForEach-Object MinClientVersion `
                                                                | ForEach-Object '#text'

                            [PSCustomObject][Ordered]@{
                                'FileType'                  = 'chocolatey'
                                'RowKey'                    = [Guid]::NewGuid().ToString("n")
                                'PartitionKey'              = $partitionKey
                                'Batched'                   = $batched
                                'Exported'                  = [System.DateTimeOffset]::Now
                                'Name'                      = $package
                                'Version'                   = $packageVersion
                                'Downloads'                 = $packageDownloads
                                'Totaldownloads'            = $packageTotalDownloads
                                'Size'                      = $packageSize
                                'IsLatestVersion'           = $packageIsLatestVersion
                                'IsAbsoluteLatestVersion'   = $packageAbsoluteIsLatestVersion
                                'IsPrerelease'              = $packageIsPreRelease
                                'LastUpdated'               = $packageLastUpdated
                                'Published'                 = $packagePublished
                                'Hash'                      = $packageHash
                                'HashAlgorithm'             = $packageHashAlgorithm
                                'MinClientVersion'          = $packageMinClientVersion
                            }
                        }
    
    if ($packageData -eq $null)
    {
        $packageData = ("No package data found for $package")
        $packageData
    }

    $file = "$($ENV:TEMP)\$packageName-$date.csv"
    $blob = "$packageName/$packageName-$date.csv"
    $packageData | Export-Csv -Path $file -NoTypeInformation -Encoding UTF8
    Set-AzureStorageBlobContent -Container $containerName -Context $ctx -File $file -Blob $blob | Out-Null
    Remove-Item $file
    "End $package $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}