    <#
    .Synopsis
       Performs a join of all properties from two objects
    .Description
       Joins the properties of two or more objects together to produce a single custom object
       Support scriptblock evaluation, and joining objects from the pipeline
    .Example
       ls | Join-Object { $_ | Select BaseName }  { $_.LastWriteTime }
	.Notes
		Downloaded from: http://poshcode.org/6599
    #>
     

    function Join-Object {
    [CmdletBinding(DefaultParameterSetName="OneTwo")]
       PARAM(
          [Parameter(Position=0, Mandatory=$false)]
          $First
       ,
          [Parameter(Position=1, Mandatory=$false)]
          $Second
       ,
          [Parameter(ValueFromPipeline=$true, Mandatory = $true, ParameterSetName="FromPipeline")]
          $InputObject
       ,
          [Switch]$Quiet
       )
       BEGIN {
          if($First -and $First -isnot [ScriptBlock]) {
             Write-Verbose "Setting Output = $First"
             $Out1 = $First
             [string[]] $p1 = $First | gm -type Properties | select -expand Name
             $Output = $Out1 | Select $p1
          } else {
             $Output = $null
          }
       }
       PROCESS {
          if(!$InputObject -and $Second) {
             $Out2 = $Second
          } elseif($Second -is [ScriptBlock]) {
             $Out2 = $InputObject | &$Second
          } elseif(!$Second) {
             $Out2 = $InputObject
          }
         
          if($First -is [ScriptBlock]){
             $Out1 = $InputObject | &$First
             [string[]] $p1 = $Out1 | gm -type Properties | select -expand Name
             $Output = $Out1 | Select $p1
          } elseif($First) {
             [string[]] $p1 = $First | gm -type Properties | select -expand Name
             $Output = $First | Select $p1
          } elseif(!$Output) {
             Write-Verbose "Initializing Output From Pipeline = $InputObject"
             [string[]] $p1 = $InputObject | gm -type Properties | select -expand Name
             $Output = $InputObject | Select $p1
             return
          } else {
             ## ToDo: this is lazy. Chache it.
             [string[]] $p1 = $Output | gm -type Properties | select -expand Name
          }
         
          if($Out2) {
             $p2 = @($Out2 | gm -type Properties | Where { $p1 -notcontains $_.Name } | select -expand Name)
             Write-Verbose "Merging $($p2.Count) into the output (which already has $(($Output | gm -type NoteProperty).Count) properties)."
             if(!$Quiet) {
                [string[]]$ignored = $Out2 | gm -type Properties | Where { $p1 -contains $_.Name } | select -expand Name
                if($Ignored) {
                   Write-Warning "Ignoring $($ignored.Count) values which are already present:`n$($out2 | fl -Property $ignored | out-string)"
                }
             }
             
             foreach($p in $p2) {
                $Output = Add-Member -in $Output -type NoteProperty -name $p -value $Out2.$p -Passthru
             }
          }
       }
       END {
          $Output
       }
    }
