Import-Module Azure.Storage

$packages = @(
    'Cake',                             'Cake.Core',                        'Cake.Common',                  'Cake.CoreCLR',
    'Cake.Testing',                     'Cake.Frosting.Template',           'Cake.FileHelpers',             'Cake.Npm',
    'Cake.AutoRest',                    'Cake.Json',                        'Cake.Powershell',              'Cake.Git',
    'Cake.Xamarin',                     'Cake.Gulp',                        'Cake.Coveralls',               'Cake.Slack',
    'Cake.CMake',                       'Cake.Compression',                 'Cake.WebDeploy',               'Cake.Wyam',
    'Cake.Yaml',                        'Cake.SqlServer',                   'Cake.AWS.S3',                  'Cake.Gitter',
    'Cake.Plist',                       'Cake.XCode',                       'Cake.AndroidAppManifest',      'Cake.Services',
    'Cake.Twitter',                     'Cake.XdtTransform',                'Cake.IIS',                     'Cake.AzureStorage',
    'Cake.Figlet',                      'Cake.DocFx',                       'Cake.Kudu',                    'Cake.ReSharperReports',
    'Cake.Docker',                      'Cake.AppVeyor',                    'Cake.ExtendedNuGet',           'Cake.SemVer',
    'Cake.Sonar',                       'Cake.AliaSql',                     'Cake.NSwag',                   'Cake.Squirrel',
    'Cake.AWS.ElasticLoadBalancing',    'Cake.HockeyApp',                   'Cake.Vagrant',                 'Cake.Incubator',
    'Cake.Http',                        'Cake.VersionReader',               'Cake.MsDeploy',                'Cake.DoInDirectory',
    'Cake.Yarn',                        'Cake.Curl',                        'Cake.VsCode',                  'Cake.Webpack',
    'Cake.Tfx',                         'Cake.MonoApiTools',                'Cake.Watch',                   'Cake.FluentMigrator',
    'Cake.AWS.EC2',                     'Cake.MicrosoftTeams',              'Cake.Gem',                     'Cake.ProjHelpers',
    'Cake.StyleCop',                    'Cake.HipChat',                     'Cake.Paket',                   'Cake.AppleSimulator',
    'Cake.Raygun',                      'Cake.EnvXmlTransform',             'Cake.Orchard',                 'Cake.Genymotion',
    'Cake.StrongNameTool',              'Cake.Putty',                       'Cake.Extensions',              'Cake.CakeMail',
    'Cake.AWS.Route53',                 'Cake.Email',                       'Cake.Newman',                  'Cake.SendGrid',
    'Cake.SimpleHTTPServer',            'Cake.Topshelf',                    'Cake.NewRelic',                'Cake.SqlServerPackager',
    'Cake.WinSCP',                      'Cake.AWS.CloudFront',              'Cake.Ftp',                     'Cake.CakeBoss',
    'Cake.GitPackager',                 'Cake.Prca',                        'Cake.Paket.Module',            'Cake.AppPackager',
    'Cake.ServiceOrchestration',        'Cake.Storyteller',                 'Cake.SquareLogo',              'Cake.Aws.ElasticBeanstalk',
    'Cake.Path',                        'Cake.SqlTools',                    'Cake.JMeter',                  'Cake.VsMetrics',
    'Cake.NSpec',                       'Cake.Android.SdkManager',          'Cake.Prca.PullRequests.Tfs',   'Cake.Android.Adb',
    'Cake.LongPath.Module',             'Cake.Prca.Issues.MsBuild',         'Cake.UServer',                 'Cake.OctoDeploy',
    'Cake.Terraform',                   'Cake.Prca.Issues.InspectCode',     'Cake.Apigee',                  'Cake.ActiveDirectory',
    'Cake.GithubUtility',               'Cake.Recipe',                      'Cake.AssemblyInfoReflector',   'Cake.Chutzpah',
    'Cake.Mage',                        'Cake.Scripty',                     'Cake.CsvHelper',               'Cake.DotNetCoreEf',
    'Cake.Transifex',                   'Cake.Dialog',                      'Cake.Gradle',                  'Cake.Chocolatey.Module',
    'Cake.Grunt',                       'Cake.Prca.Issues.Markdownlint',    'Cake.CodeAnalysisReporting',   'Cake.ViewCompiler',
    'Cake.ImageOptimizer',              'Cake.AWS.CodeDeploy',              'Cake.MSBuildTask',             'Cake.ResxConverter',
    'Cake.UncUtils',                    'Cake.VsixSignTool'                 'Cake.EntityFramework',         'Cake.Netlify',
    'Cake.Azure',                       'SemVer.FromAssembly',              'Cake.SemVer.FromAssembly',     'Cake.SemVer.FromBinary',
    'Cake.SynVer',                      'Cake.DeployParams',                'Cake.DocCreator',              'Cake.BuildSystems.Module',
    'Cake.DNF.Module',                  'Cake.SqlPackage',                  'Cake.Ember',                   'Cake.ClickTwice',
    'Cake.Nswag.Console',               'Cake.Yeoman',                      'Cake.Prca.Issues.EsLint',      'Cake.Prca.Issues.DocFx'
)

$batched    = [System.DateTimeOffset]::Now
$date       = Get-Date -format 'yyyy-MM-dd_HHmmss'
$ctx        = New-AzureStorageContext -ConnectionString $env:AzureWebJobsStorage
$container  = Get-AzureStorageContainer –Name 'nugetstats' -Context $ctx -ErrorAction Ignore

if ($container -eq $null)
{
    $container = New-AzureStorageContainer -Name 'nugetstats' -Context $ctx
}
$containerName = $container.Name

foreach ($package in $packages)
{
    "Begin $package $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $partitionKey   = [Guid]::NewGuid().ToString("n")
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
                                'FileType'                  = 'nuget'
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
