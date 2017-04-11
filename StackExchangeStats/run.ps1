Import-Module Azure.Storage

#constants
[DateTimeOffset] $unixStart = New-Object -TypeName 'DateTimeOffset' -ArgumentList 1970,01,01,0,0,0,([TimeSpan]::Zero)
[DateTimeOffset] $utcNow = [System.DateTimeOffset]::UtcNow

#functions
function UnixToDateTimeOffset
{
    [OutputType([DateTimeOffset])]
    Param([string] $unixDateTimeString)

    [double] $seconds = [double]::Parse($unixDateTimeString)
    $unixStart.AddSeconds($seconds)
}

function ParseQuestion
{
    Param(
        [parameter(ValueFromPipeline=$True)]
        $question
    )

    $question `
        | ForEach-Object items `
        | ForEach-Object {
            [PSCustomObject][Ordered]@{
                'Id' = [long]::Parse($_.question_id)
                'Created' = UnixToDateTimeOffset($_.creation_date)
                'LastActivity' = UnixToDateTimeOffset($_.last_activity_date)
                'IsAnswered' = [bool]::Parse($_.is_answered)
                'Title' = $_.title
            }
    }
}

$appKey     = $ENV:STACKEXCHANGE_APP_KEY
$tags       = @(
                    [PSCustomObject][Ordered]@{
                        'Site'  = 'StackOverflow'
                        'Tag'   = 'CakeBuild'
                    }
              )
$batched    = [System.DateTimeOffset]::Now
$date       = Get-Date -format 'yyyy-MM-dd_HHmmss'
$ctx        = New-AzureStorageContext -ConnectionString $env:AzureWebJobsStorage
$container  = Get-AzureStorageContainer –Name 'stackexchangestats' -Context $ctx -ErrorAction Ignore

if ($container -eq $null)
{
    $container = New-AzureStorageContainer -Name 'stackexchangestats' -Context $ctx
}
$containerName = $container.Name

foreach ($tag in $tags)
{
    "Begin $tag $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    [System.Collections.Specialized.StringCollection] $names = New-Object 'System.Collections.Specialized.StringCollection'
    [int] $tagQuestions             = 0
    [int] $unansweredQuestionCount  = 0;
    [int] $page                     = 1
    $partitionKey                   = [Guid]::NewGuid().ToString("n")
    $tagName                        = $tag.Tag
    $siteName                       = $tag.Site
    $tagInfoUrl                     = "https://api.stackexchange.com/2.2/tags/$tagName/info?site=$siteName&key=$appKey"
    $tagInfo                        = Invoke-RestMethod $tagInfoUrl
    
    $tagInfo `
        | ForEach-Object items `
        | ForEach-Object {
            $names.Add($_.name)|Out-Null
            $questions+=$_.count
        }

    while(($page -eq 1 -or $unansweredQUestions.has_more -eq 'True') -and $page -le 100)
    {
        $unansweredQUestionsUrl     = "https://api.stackexchange.com/2.2/questions/unanswered?page=$page&pagesize=100&order=desc&sort=activity&tagged=$tagName&site=$siteName&key=$appKey"
        $unansweredQUestions        = Invoke-RestMethod $unansweredQUestionsUrl
        $unansweredQUestionCount    +=$unansweredQUestions.items.Count
        $page++
    }

    $lastCreatedQuestionUrl = "https://api.stackexchange.com/2.2/questions?pagesize=1&order=desc&sort=creation&tagged=$tagName&site=$siteName&key=$appKey"
    $lastCreatedQuestion = (Invoke-RestMethod $lastCreatedQuestionUrl) | ParseQuestion

    $lastActiveQuestionUrl = "https://api.stackexchange.com/2.2/questions?pagesize=1&order=desc&sort=activity&tagged=$tagName&site=$siteName&key=$appKey"
    $lastActiveQuestion = (Invoke-RestMethod $lastActiveQuestionUrl) | ParseQuestion

    $tagData    =  [PSCustomObject][Ordered]@{
                                'FileType'                  = 'stackexchange'
                                'RowKey'                    = [Guid]::NewGuid().ToString("n")
                                'PartitionKey'              = $partitionKey
                                'Batched'                   = $batched
                                'Exported'                  = [System.DateTimeOffset]::Now
                                'Site'                      = $siteName
                                'Tag'                       = $tagName
                                'Questions'                 = $questions
                                'Unanswered Questions'      = $unansweredQUestionCount
                                'Last Created Id'           = $lastCreatedQuestion.Id
                                'Last Activity Id'          = $lastActiveQuestion.Id
                                'Last Created'              = $lastCreatedQuestion.Created
                                'Last Activity'             = $lastActiveQuestion.LastActivity
                                'Last Created Answered'     = $lastCreatedQuestion.IsAnswered
                                'Last Activity Answered'    = $lastActiveQuestion.IsAnswered
                                'Last Created Title'        = $lastCreatedQuestion.Title
                                'Last Activity Title'       = $lastActiveQuestion.Title
                            }

    if ($tagData -eq $null)
    {
        $tagData = ("No Stack Exchange data found for $tag")
        $tagData
    }

    $file = "$($ENV:TEMP)\$tagName-$date.csv"
    $blob = "$tagName/$tagName-$date.csv"
    $tagData | Export-Csv -Path $file -NoTypeInformation -Encoding UTF8
    Set-AzureStorageBlobContent -Container $containerName -Context $ctx -File $file -Blob $blob | Out-Null
    Remove-Item $file
    "End $tag $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}