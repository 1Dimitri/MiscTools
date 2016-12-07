
$folder = 'C:\Test\logs' # Enter the root path you want to monitor.
$filter = '*.log' # You can enter a wildcard filter here.
$recurse = $true # sub directories?

# In the following line, you can change 'IncludeSubdirectories to $true if required.
$fsw = New-Object IO.FileSystemWatcher $folder, $filter -Property @{IncludeSubdirectories = $recurse;NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'}

Register-ObjectEvent $fsw Changed -SourceIdentifier LogMonitor -Action {

$path = $Event.SourceEventArgs.FullPath
$changeType = $Event.SourceEventArgs.ChangeType
$timeStamp = $Event.TimeGenerated
Write-VErbose "[$timeStamp] $changeType $path"
if ($fileptr -eq $null) {
 $fileptr=@{}
}
$fs = New-Object System.IO.FileStream($path,"Open","Read","ReadWrite",8,"None")
#ReadWrite as 4th parameter -> do not block file
$sr = New-Object System.IO.StreamReader($fs)
$pos = $fileptr[$path]

if ($pos) {
  Write-Verbose "This file was already read until $pos"
  $sr.BaseStream.Seek($pos,"Begin")

  
}
 Write-Verbose 'Reading lines'
  $line = $sr.ReadLine()
  WRite-Verbose "Line: [$line]"
  
  while ($line -ne $null) {
  $found = $line | Select-String 'ERROR' -SimpleMatch -Quiet
  if ($found) {
      # Send Alert for each pattern found
	  Write-Verbose 'Pattern found'
	  #change source as appropriate, otherwise you'll get error
	  Write-EventLog -LogName Application -Source WatchDogSript -Message "pattern found in $path at position $($sr.BaseStream.Position)" -EventId 777 -EntryType information
	}
	else {
	 Write-Verbose 'Pattern not found'
	}
	  $line = $sr.ReadLine()
  }
  
  $fileptr[$path]=$sr.BaseStream.Position
  $sr.Close()
  $fs.Close()
}

# To stop the monitoring, run the following commands:
# Unregister-Event LogMonitor