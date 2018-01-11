Import-Module Azure.Storage

$packages = @(
    'Cake',                         'Cake.Core',                        'Cake.Common',                  'Cake.CoreCLR'
    'Cake.Testing',                 'Cake.NuGet',                       'Cake.Frosting.Template',       'Cake.Bakery',
    'Cake.Scripting.Abstractions',  'Cake.Scripting.Transport',         
    'Cake.ActiveDirectory',         'Cake.AliaSql',                     'Cake.Android.Adb',             'Cake.Android.SdkManager',
    'Cake.AndroidAppManifest',      'Cake.ArtifactDrop',                'Cake.Apigee',                  'Cake.AppleSimulator',
    'Cake.AppPackager',             'Cake.Apprenda',                    'Cake.AppVeyor',                'Cake.APT.Module',
    'Cake.ArgumentHelpers',         'Cake.ArtifactDrop',                'Cake.AssemblyInfoReflector',   'Cake.AutoRest',
    'Cake.AWS.CloudFront',          'Cake.AWS.CodeDeploy',              'Cake.AWS.EC2',                 'Cake.Aws.ElasticBeanstalk',
    'Cake.AWS.ElasticLoadBalancing','Cake.AWS.Lambda',                  'Cake.AWS.Route53',             'Cake.AWS.S3',
    'Cake.AzCopy',                  'Cake.Azure',                       'Cake.AzureBlobStorage',        'Cake.AzureStorage',
    'Cake.Bower',                   'Cake.BuildSystems.Module',         'Cake.Bumpy',
    'Cake.CachedNpm',               'Cake.CakeBoss',                    'Cake.CakeMail',                'Cake.Chocolatey.Module',
    'Cake.Chutzpah',                'Cake.ClickTwice',                  'Cake.CMake',                   'Cake.CodeAnalysisReporting',
    'Cake.Codecov',                 'Cake.Compression',                 'Cake.Coveralls',               'Cake.CsvHelper',
    'Cake.Curl',
    'Cake.DeployParams',            'Cake.Dialog',                      'Cake.DNF.Module',              'Cake.DocCreator',
    'Cake.DocFx',                   'Cake.Docker',                      'Cake.DocumentDb',              'Cake.DoInDirectory',
    'Cake.DotNetCoreEf',
    'Cake.Email',                   'Cake.Ember',                       'Cake.Endpoint',                'Cake.EntityFramework',
    'Cake.EnvXmlTransform',         'Cake.ExtendedNuGet',               'Cake.Extensions',
    'Cake.Fastlane',                'Cake.Figlet',                      'Cake.FileHelpers',             'Cake.FileSet',
    'Cake.FluentMigrator',          'Cake.Flyway',                      'Cake.Ftp',
    'Cake.Gem',                     'Cake.Genymotion',                  'Cake.Git',                     'Cake.GithubUtility',
    'Cake.GitPackager',             'Cake.Gitter',                      'Cake.Gradle',                  'Cake.Graph',
    'Cake.Grunt',                   'Cake.Gulp',
    'Cake.Handlebars',              'Cake.Hg',                          'Cake.HipChat',                 'Cake.HockeyApp',
    'Cake.Hosts',                   'Cake.Http',
    'Cake.IIS',                     'Cake.ImageOptimizer',              'Cake.Incubator',               'Cake.Intellisense',
    'Cake.Intellisense.Core',       'Cake.IntellisenseGenerator',       'Cake.ISO',                     'Cake.Issues',
    'Cake.Issues.DocFx',            'Cake.Issues.EsLint',               'Cake.Issues.InspectCode',      'Cake.Issues.Markdownlint',
    'Cake.Issues.MsBuild',          'Cake.Issues.PullRequests',         'Cake.Issues.PullRequests.Tfs', 'Cake.Issues.Reporting',
    'Cake.Issues.Reporting.Generic','Cake.Issues.Testing',
    'Cake.JMeter',                  'Cake.Json',
    'Cake.KeePass',                 'Cake.Kudu',
    'Cake.Liquibase',               'Cake.LongPath.Module',
    'Cake.Mage',                    'Cake.Markdown-Pdf',                'Cake.MarkdownToPdf',           'Cake.Microsoft.Extensions.Configuration',
    'Cake.MicrosoftTeams',          'Cake.MobileCenter',                'Cake.MonoApiTools',            'Cake.MSBuildTask',
    'Cake.MsDeploy',
    'Cake.NDepend',                 'Cake.Netlify',                     'Cake.Newman',                  'Cake.NewRelic',
    'Cake.Npm',                     'Cake.NSpec',                       'Cake.NSwag',                   'Cake.NSwag.Console',
    'Cake.Nuget.Versioning',
    'Cake.OctoDeploy',              'Cake.OctoVariapus',                'Cake.Openshift',               'Cake.Orchard',
    'Cake.Packages',                'Cake.Paket',                       'Cake.Paket.Module',            'Cake.Parallel.Module',
    'Cake.Path',                    'Cake.PinNuGetDependency',          'Cake.Plist',                   'Cake.Powershell',
    'Cake.Prca',                    'Cake.Prca.Issues.DocFx',           'Cake.Prca.Issues.EsLint',      'Cake.Prca.Issues.InspectCode',
    'Cake.Prca.Issues.Markdownlint','Cake.Prca.Issues.MsBuild',         'Cake.Prca.PullRequests.Tfs',   'Cake.ProGet',
    'Cake.ProjHelpers',             'Cake.ProtobufTools',               'Cake.Putty',
    'Cake.Raygun',                  'Cake.Recipe',                      'Cake.ReSharperReports',        'Cake.ResxConverter',
    'Cake.ScheduledTasks',          'Cake.Scripty',                     'Cake.SemVer',                  'Cake.SemVer.FromAssembly',
    'Cake.SemVer.FromBinary',       'Cake.SendGrid',                    'Cake.ServiceOrchestration',    'Cake.Services',
    'Cake.SimpleHTTPServer',        'Cake.SimpleVersionIncrement',      'Cake.Slack',                   'Cake.Sonar',
    'Cake.SonarScanner',            'Cake.SqlPackage',                  'Cake.SqlServer',               'Cake.SqlServerPackager',
    'Cake.SqlTools',                'Cake.SquareLogo',                  'Cake.Squirrel',                'Cake.SSRS',
    'Cake.Storyteller',             'Cake.StrongNameTool',              'Cake.StyleCop',                'Cake.Svn',
    'Cake.SynVer',
    'Cake.Talend',                  'Cake.Terraform',                   'Cake.Tfs.AutoMerge',           'Cake.Tfs.Build.Variables',
    'Cake.Tfx',                     'Cake.Topshelf',                    'Cake.Transifex',               'Cake.Twitter',
    'Cake.UncUtils',                'Cake.UrlLoadDirective.Module',     'Cake.Utility',                 'Cake.UServer',
    'Cake.Vagrant',                 'Cake.VersionReader',               'Cake.ViewCompiler',            'Cake.VsCode',
    'Cake.VSforMac',                'Cake.VsixSignTool',                'Cake.VsMetrics',
    'Cake.Watch',                   'Cake.WebDeploy',                   'Cake.Webpack',                 'Cake.WinSCP',
    'Cake.Wyam',                    'Cake.Wyam.Recipe',
    'Cake.Xamarin',                 'Cake.Xamarin.Build',               'Cake.XCode',                   'Cake.XComponent',
    'Cake.XdtTransform',            'Cake.XmlConfigStructureBuilder',
    'Cake.Yaml',                    'Cake.Yarn',                        'Cake.Yeoman',
    'SemVer.FromAssembly'
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
