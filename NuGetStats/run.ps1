Import-Module Azure.Storage

function Get-WebRequestTable
{
    # Gratefully borrowed from here: http://www.leeholmes.com/blog/2015/01/05/extracting-tables-from-powershells-invoke-webrequest/
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.PowerShell.Commands.HtmlWebResponseObject] $WebRequest,
        [Parameter(Mandatory = $true)]
        [int] $TableNumber
    )

    ## Extract the tables out of the web request
    $tables = @($WebRequest.ParsedHtml.getElementsByTagName("TABLE"))
    $table = $tables[$TableNumber]
    $titles = @()
    $rows = @($table.Rows)

    ## Go through all of the rows in the table
    foreach($row in $rows)
    {
        $cells = @($row.Cells)

        ## If we've found a table header, remember its titles
        if($cells[0].tagName -eq "TH")
        {
            $titles = @($cells | % { ("" + $_.InnerText).Trim() })
            continue
        }

        ## If we haven't found any table headers, make up names "P1", "P2", etc.
        if(-not $titles)
        {
            $titles = @(1..($cells.Count + 2) | % { "P$_" })
        }

        ## Now go through the cells in the the row. For each, try to find the
        ## title that represents that column and create a hashtable mapping those
        ## titles to content
        $resultObject = [Ordered] @{}

        for($counter = 0; $counter -lt $cells.Count; $counter++)
        {
            $title = $titles[$counter]
            if(-not $title) { continue }
            $resultObject[$title] = ("" + $cells[$counter].InnerText).Trim()
        }

        ## And finally cast that hashtable to a PSCustomObject
        [PSCustomObject] $resultObject
    }
}

$packages = @(
                "Cake",
                "Cake.Core",
                "Cake.Common",
                "Cake.CoreCLR",
                "Cake.Testing",
                "Cake.Frosting.Template",
                "Cake.FileHelpers",
                "Cake.Npm",
                "Cake.AutoRest",
                "Cake.Json",
                "Cake.PowerShell",
                "Cake.Git",
                "Cake.Xamarin",
                "Cake.Gulp",
                "Cake.Coveralls",
                "Cake.Slack",
                "Cake.CMake",
                "Cake.WebDeploy",
                "Cake.Yaml",
                "Cake.Compression",
                "Cake.AWS.S3",
                "Cake.XCode",
                "Cake.Services",
                "Cake.SqlServer",
                "Cake.Gitter",
                "Cake.XdtTransform",
                "Cake.Plist",
                "Cake.Twitter",
                "Cake.IIS",
                "Cake.AndroidAppManifest",
                "Cake.Figlet",
                "Cake.DocFx",
                "Cake.AzureStorage",
                "Cake.ReSharperReports",
                "Cake.Docker",
                "Cake.Kudu",
                "Cake.AppVeyor",
                "Cake.ExtendedNuGet",
                "Cake.SemVer",
                "Cake.AliaSql",
                "Cake.NSwag",
                "Cake.Squirrel",
                "Cake.AWS.ElasticLoadBalancing",
                "Cake.Vagrant",
                "Cake.HockeyApp",
                "Cake.VersionReader",
                "Cake.Sonar",
                "Cake.DoInDirectory",
                "Cake.MsDeploy",
                "Cake.Incubator",
                "Cake.VsCode",
                "Cake.Yarn",
                "Cake.Tfx",
                "Cake.Webpack",
                "Cake.Watch",
                "Cake.MonoApiTools",
                "Cake.FluentMigrator",
                "Cake.AWS.EC2",
                "Cake.Http",
                "Cake.Gem",
                "Cake.MicrosoftTeams",
                "Cake.ProjHelpers",
                "Cake.StyleCop",
                "Cake.HipChat",
                "Cake.Paket",
                "Cake.Raygun",
                "Cake.AppleSimulator",
                "Cake.Orchard",
                "Cake.EnvXmlTransform",
                "Cake.GenyMotion",
                "Cake.Curl",
                "Cake.Extensions",
                "Cake.StrongNameTool",
                "Cake.Putty",
                "Cake.CakeMail",
                "Cake.AWS.Route53",
                "Cake.Email",
                "Cake.SimpleHTTPServer",
                "Cake.SendGrid",
                "Cake.Newman",
                "Cake.NewRelic",
                "Cake.TopShelf",
                "Cake.SqlServerPackager",
                "Cake.WinSCP",
                "Cake.CakeBoss",
                "Cake.AWS.CloudFront",
                "Cake.Ftp",
                "Cake.GitPackager",
                "Cake.AppPackager",
                "Cake.Paket.Module",
                "Cake.ServiceOrchestration",
                "Cake.Prca",
                "Cake.Storyteller",
                "Cake.SquareLogo",
                "Cake.AWS.ElasticBeanstalk",
                "Cake.Path",
                "Cake.SqlTools",
                "Cake.JMeter",
                "Cake.NSpec",
                "Cake.VsMetrics",
                "Cake.Android.SdkManager",
                "Cake.Android.Adb",
                "Cake.LongPath.Module",
                "Cake.UServer",
                "Cake.OctoDeploy",
                "Cake.Prca.PullRequests.Tfs",
                "Cake.Prca.Issues.MsBuild",
                "Cake.GithubUtility",
                "Cake.Recipe",
                "Cake.Prca.Issues.InspectCode",
                "Cake.Chutzpah",
                "Cake.AssemblyInfoReflector",
                "Cake.Terraform",
                "Cake.ActiveDirectory",
                "Cake.Mage",
                "Cake.DotNetCoreEf",
                "Cake.Transifex",
                "Cake.Dialog",
                "Cake.Gradle",
                "Cake.CsvHelper",
                "Cake.Chocolatey.Module",
                "Cake.Grunt"
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
    $url = "https://www.nuget.org/packages/$package"
    $request = Invoke-WebRequest $url
    $file = "$ENV:TEMP\$package-$date.csv"
    $blob = "$package/$package-$date.csv".ToLower()
    Get-WebRequestTable -WebRequest $request -TableNumber 0 | Export-Csv -Path $file
    Set-AzureStorageBlobContent -Container $containerName -Context $ctx -File $file -Blob $blob | Out-Null
    Remove-Item $file
}