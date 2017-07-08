Import-Module Azure.Storage

$packages = @(
    'Cake',                             'Cake.Core',                        'Cake.Common',                      'Cake.CoreCLR',                    
    'Cake.Testing',                     'Cake.NuGet',                       'Cake.Frosting.Template',           'Cake.FileHelpers',                
    'Cake.Json',                        'Cake.Npm',                         'Cake.Git',                         'Cake.Powershell',                 
    'Cake.AutoRest',                    'Cake.Xamarin',                     'Cake.Gulp',                        'Cake.Coveralls',                  
    'Cake.Plist',                       'Cake.Http',                        'Cake.Compression',                 'Cake.Slack',                      
    'Cake.XdtTransform',                'Cake.Incubator',                   'Cake.SqlServer',                   'Cake.AndroidAppManifest',         
    'Cake.Sonar',                       'Cake.ReSharperReports',            'Cake.Docker',                      'Cake.WebDeploy',                  
    'Cake.Curl',                        'Cake.Wyam',                        'Cake.IIS',                         'Cake.ExtendedNuGet',              
    'Cake.Yarn',                        'Cake.AWS.S3',                      'Cake.MsDeploy',                    'Cake.Services',                   
    'Cake.DocFx',                       'Cake.VersionReader',               'Cake.CMake',                       'Cake.DoInDirectory',              
    'Cake.Gitter',                      'Cake.AzureStorage',                'Cake.Yaml',                        'Cake.Twitter',                    
    'Cake.Kudu',                        'Cake.Figlet',                      'Cake.XCode',                       'Cake.SemVer',                     
    'Cake.Squirrel',                    'Cake.NSwag',                       'Cake.Codecov',                     'Cake.LongPath.Module',            
    'Cake.HockeyApp',                   'Cake.AppVeyor',                    'Cake.BuildSystems.Module',         'Cake.AliaSql',                    
    'Cake.MSBuildTask',                 'Cake.Putty',                       'Cake.MicrosoftTeams',              'Cake.Azure',                      
    'Cake.SqlTools',                    'Cake.StyleCop',                    'Cake.Vagrant',                     'Cake.AWS.ElasticLoadBalancing',   
    'Cake.FluentMigrator',              'Cake.Watch',                       'Cake.Terraform',                   'Cake.Paket',                      
    'Cake.AppPackager',                 'Cake.Ftp',                         'Cake.Webpack',                     'Cake.DocCreator',                 
    'Cake.Email',                       'Cake.Newman',                      'Cake.VsCode',                      'Cake.AWS.Route53',                
    'Cake.Storyteller',                 'Cake.MonoApiTools',                'Cake.Tfx',                         'Cake.AWS.EC2',                    
    'Cake.Prca',                        'Cake.Topshelf',                    'Cake.ProjHelpers',                 'Cake.Gem',                        
    'Cake.StrongNameTool',              'Cake.AWS.CodeDeploy',              'Cake.Raygun',                      'Cake.NewRelic',                   
    'Cake.EntityFramework',             'Cake.HipChat',                     'Cake.EnvXmlTransform',             'Cake.CakeMail',                   
    'Cake.AppleSimulator',              'Cake.SendGrid',                    'Cake.CodeAnalysisReporting',       'Cake.Orchard',                    
    'Cake.Genymotion',                  'Cake.Prca.PullRequests.Tfs',       'Cake.Extensions',                  'Cake.SimpleHTTPServer',           
    'Cake.SemVer.FromAssembly',         'Cake.AWS.CloudFront',              'SemVer.FromAssembly',              'Cake.SqlServerPackager',          
    'Cake.Paket.Module',                'Cake.WinSCP',                      'Cake.Prca.Issues.MsBuild',         'Cake.AssemblyInfoReflector',      
    'Cake.XComponent',                  'Cake.GitPackager',                 'Cake.Prca.Issues.InspectCode',     'Cake.Path',                       
    'Cake.CakeBoss',                    'Cake.Aws.ElasticBeanstalk',        'Cake.OctoDeploy',                  'Cake.ServiceOrchestration',       
    'Cake.Apigee',                      'Cake.JMeter',                      'Cake.ImageOptimizer',              'Cake.VsMetrics',                  
    'Cake.Prca.Issues.Markdownlint',    'Cake.ActiveDirectory',             'Cake.Android.Adb',                 'Cake.SquareLogo',                 
    'Cake.DeployParams',                'Cake.Android.SdkManager',          'Cake.Mage',                        'Cake.Scripty',                    
    'Cake.Grunt',                       'Cake.CsvHelper',                   'Cake.NSpec',                       'Cake.DotNetCoreEf',               
    'Cake.ClickTwice',                  'Cake.Prca.Issues.EsLint',          'Cake.Prca.Issues.DocFx',           'Cake.Transifex',                  
    'Cake.Chutzpah',                    'Cake.SynVer',                      'Cake.ResxConverter',               'Cake.OctoVariapus',               
    'Cake.SemVer.FromBinary',           'Cake.UServer',                     'Cake.ViewCompiler',                'Cake.DNF.Module',                 
    'Cake.GithubUtility',               'Cake.Recipe',                      'Cake.Dialog',                      'Cake.VsixSignTool',               
    'Cake.NSwag.Console',               'Cake.APT.Module',                  'Cake.Ember',                       'Cake.SqlPackage',                 
    'Cake.FileSet',                     'Cake.PinNuGetDependency',          'Cake.Yeoman',                      'Cake.Wyam.Recipe',                
    'Cake.Gradle',                      'Cake.Netlify',                     'Cake.UncUtils',                    'Cake.AzCopy',                     
    'Cake.Chocolatey.Module',           'Cake.Hosts',                       'Cake.KeePass',                     'Cake.SonarScanner',               
    'Cake.Parallel.Module'
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
