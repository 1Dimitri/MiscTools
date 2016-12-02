

<#
.Synopsis
   WAit for a service to be up
.DESCRIPTION
   Long description
.EXAMPLE
   Wait-ServiceUp 'DNS'
#>
function Wait-ServiceUp
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Name of the service
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String]
        $ServiceName

    )

    {
    (Get-Service $ServiceName).WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Running)
    }
}

$eventxml = @"
<QueryList>
  <Query Id="0" Path="System">
    <Select Path="System">*[System[Provider[@Name='Microsoft-Windows-Kernel-Boot'] and (EventID=20)]]</Select>
  </Query>
</QueryList>
"@

$evts = Get-WinEvent -FilterXml $eventxml -Oldest
$evt = $evts[-1]
if ($evt.count -gt 0) {
   Write-VErbose 'Retrieving boot event'
    $evt = $evts[-1]
    $machinename = $evt.MachineName
    $rebootat = $evt.TimeCreated
    $msg = $evt.Message
    Write-Verbose "Message found: $rebootat $msg"
    $msgpattern = "The last shutdown's success status was (?<shutdown>[\d\w]+)\. The last boot's success status was (?<reboot>[\d\w]+)."
    if ($msg -match $msgpattern) {
       Write-Verbose "Message has expected format [$msgpattern], retrieving success/failure codes"
       $shutdownok=$matches['shutdown']
       $rebootok=$matches['reboot']
       $details = "$shutdownok,$rebootok"
       if (($shutdownok -ne "true") -or ($rebootok -ne 'true')) 
         { $detailsinfo='=> Dirty' }
       else { $detailsinfo = 'Clean' }

       Write-Verbose "Was the shutdown dirty?: $detailedinfo"
    }
    else {
       Write-Verbose "Message has unexpected wording, not matching $msgpattern, just using plain message"
    }

   
    $fn = Join-Path $PSScriptRoot 'reboot.log'
    Write-Verbose "Writing in $fn"
    if (!(Test-Path $fn)) {
      Add-Content -Path $fn -Value "MACHINENAME,REBOOTAT,MESSAGE,SHUTDOWN_OK,BOOT_OK"
    }

    $rebootatroundtrip = Get-Date $rebootat -Format 'o'
    Add-Content -Path $fn -Value "$machinename,$rebootatroundtrip,$msg,$details"








}
