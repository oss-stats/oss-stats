Import-Module Azure.Storage

$packages = @(
    'Cake',                     'Cake.Core',                    'Cake.Common',                  'Cake.CoreCLR',
    'Cake.Testing',             'Cake.Frosting.Template',       'Cake.FileHelpers',             'Cake.Npm',
    'Cake.AutoRest',            'Cake.Json',                    'Cake.PowerShell',              'Cake.Git',
    'Cake.Xamarin',             'Cake.Gulp',                    'Cake.Coveralls',               'Cake.Slack',
    'Cake.CMake',               'Cake.WebDeploy',               'Cake.Yaml',                    'Cake.Compression',
    'Cake.AWS.S3',              'Cake.XCode',                   'Cake.Services',                'Cake.SqlServer',
    'Cake.Gitter',              'Cake.XdtTransform',            'Cake.Plist',                   'Cake.Twitter',
    'Cake.IIS',                 'Cake.AndroidAppManifest',      'Cake.Figlet',                  'Cake.DocFx',
    'Cake.AzureStorage',        'Cake.ReSharperReports',        'Cake.Docker',                  'Cake.Kudu',
    'Cake.AppVeyor',            'Cake.ExtendedNuGet',           'Cake.SemVer',                  'Cake.AliaSql',
    'Cake.NSwag',               'Cake.Squirrel',                'Cake.AWS.ElasticLoadBalancing','Cake.Vagrant',
    'Cake.HockeyApp',           'Cake.VersionReader',           'Cake.Sonar',                   'Cake.DoInDirectory',
    'Cake.MsDeploy',            'Cake.Incubator',               'Cake.VsCode',                  'Cake.Yarn',
    'Cake.Tfx',                 'Cake.Webpack',                 'Cake.Watch',                   'Cake.MonoApiTools',
    'Cake.FluentMigrator',      'Cake.AWS.EC2',                 'Cake.Http',                    'Cake.Gem',
    'Cake.MicrosoftTeams',      'Cake.ProjHelpers',             'Cake.StyleCop',                'Cake.HipChat',
    'Cake.Paket',               'Cake.Raygun',                  'Cake.AppleSimulator',          'Cake.Orchard',
    'Cake.EnvXmlTransform',     'Cake.GenyMotion',              'Cake.Curl',                    'Cake.Extensions',
    'Cake.StrongNameTool',      'Cake.Putty',                   'Cake.CakeMail',                'Cake.AWS.Route53',
    'Cake.Email',               'Cake.SimpleHTTPServer',        'Cake.SendGrid',                'Cake.Newman',
    'Cake.NewRelic',            'Cake.TopShelf',                'Cake.SqlServerPackager',       'Cake.WinSCP',
    'Cake.CakeBoss',            'Cake.AWS.CloudFront',          'Cake.Ftp',                     'Cake.GitPackager',
    'Cake.AppPackager',         'Cake.Paket.Module',            'Cake.ServiceOrchestration',    'Cake.Prca',
    'Cake.Storyteller',         'Cake.SquareLogo',              'Cake.AWS.ElasticBeanstalk',    'Cake.Path',
    'Cake.SqlTools',            'Cake.JMeter',                  'Cake.NSpec',                   'Cake.VsMetrics',
    'Cake.Android.SdkManager',  'Cake.Android.Adb',             'Cake.LongPath.Module',         'Cake.UServer',
    'Cake.OctoDeploy',          'Cake.Prca.PullRequests.Tfs',   'Cake.Prca.Issues.MsBuild',     'Cake.GithubUtility',
    'Cake.Recipe',              'Cake.Prca.Issues.InspectCode', 'Cake.Chutzpah',                'Cake.AssemblyInfoReflector',
    'Cake.Terraform',           'Cake.ActiveDirectory',         'Cake.Mage',                    'Cake.DotNetCoreEf',
    'Cake.Transifex',           'Cake.Dialog',                  'Cake.Gradle',                  'Cake.CsvHelper',
    'Cake.Chocolatey.Module',   'Cake.Grunt'
)

$date = Get-Date -format 'yyyy-MM-dd_HHmmss'
$ctx = New-AzureStorageContext -ConnectionString $env:AzureWebJobsStorage
$container = Get-AzureStorageContainer –Name 'nugetstats' -Context $ctx -ErrorAction Ignore
if ($container -eq $null)
{
    $container = New-AzureStorageContainer -Name 'nugetstats' -Context $ctx
}
$containerName = $container.Name

foreach ($package in $packages)
{
    "Begin $package $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $packageName    = $package.ToLower()
    $url            = "https://nuget.org/api/v2/FindPackagesById()?Id='$package'"
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