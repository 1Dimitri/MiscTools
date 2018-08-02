function convert-ToMarkdownTable {
    [cmdletbinding()]
    Param(            
        [parameter(mandatory=$true, ValueFromPipeline=$true, ParameterSetName="Default")]
        [object]$inputObject

    )
 
  
    #Get properties name from first object
    if ($inputobject -is [array]) {
        $properties = ( Get-Member -InputObject $inputObject[0] -MemberType NoteProperty,Property).Name
    } else {

        $properties = ( Get-Member -InputObject $inputObject -MemberType NoteProperty,Property).Name 
    }
    
    $lengths = New-Object int[] $properties.Count
 
    0..($properties.Count-1) | ForEach-Object {
        $prop = $properties[$_]
        # Doesn't f** work
        # $lengths[$_] = (Measure-Object -InputObject $inputObject -Property $properties[$_] -Maximum).Maximum
        $lenprop = 0
        $inputObject | ForEach-Object {
            $lencurrent = $_.$prop.ToString().Length
            if ($lencurrent -gt $lenprop) {
                $lenprop = $lencurrent
            }
        }
        $lengths[$_]=$lenprop
    }
    
   
    $headerfooter = "+"
    $lengths | ForEach-Object { $headerfooter += '-'*($_+2)+"+"}

    $headerfooter
    $line = '|'
    0..($properties.Count-1) | ForEach-Object {
        $line += " {0,-$($lengths[$_])} |" -f $properties[$_]
    }
    $line
    $headerfooter

    $inputObject | ForEach-Object {
        $o = $_
        $line = '|'
        0..($properties.Count-1) | ForEach-Object {
            $line += " {0,-$($lengths[$_])} |" -f $o.($properties[$_]).ToString()
        }
        $line
        $headerfooter
    }
    
    
}

function Convert-ToMarkdown {
    [CmdletBinding()]
    param (
        # XML of servers
        [Parameter(Mandatory=$true)]
        $data
    )
    


    foreach ($machine in $data) {
        $name = $machine.Computername
        $OSDescription = $machine.Win32_OperatingSystem.Caption
        $OSBuild = $machine.Win32_OperatingSystem.BuildNumber
        $OSText = $OSDescription
        if ($null -ne $OSBuild) {
            $OSText = $OSText + "(Build: $OSBuild)"
        }

        $softwareList = [System.Collections.ArrayList]@()
         $machine.Win32_Product | ForEach-Object {
             $softwareList.Add("$($_.Name) $($_.Version)") | Out-Null
         }

        ""
        "# $name"
        ""
        "***Operating System:*** $OSText"
        ""
        "***List of installed software packages using Windows Installer***"
        "" 
    #    $softwareList | ForEach-Object {
    #        "- $_"
    #    }

        $products = $machine.Win32_Product | Select-Object Name, Version | Sort-Object -Property Name
        convert-ToMarkdownTable -inputObject $products

        ""
        "***Logical Disks***"
        ""
        $ldisks = $machine.Win32_LogicalDisk | Select-Object Name, 
        @{Name='Label';Expression={if ($null -eq $_.VolumeName){'(No label)'} else { $_.VolumeName}}}, Description, 
        @{Name='Free_GB';Expression={if ($null -ne $_.Freespace){ "{0:N1}" -f ($_.Freespace/1GB) } else {"N/A"} } },        
        @{Name='Size_GB';Expression={if ($null -ne $_.Size){"{0:N1}" -f ($_.Size/1GB) } else {"N/A"} } },
        @{Name='%';Expression={if ($null -ne $_.Size){"{0:p0}" -f ($_.Freespace/$_.Size)} else {"N/A"} } } `
        | Sort-Object -Property Name
        convert-ToMarkdownTable -inputObject $ldisks
        ""
        "***List of updates***"
        ""
        $qfe = $machine.Win32_QuickFixEngineering | Select-Object `
            @{Name='Update';Expression={$_.HotfixID -replace '^(KB)?([0-9]+)','[$2](https://support.microsoft.com/en-us/help/$2)'}},`
            @{Name='Date';Expression={$_.InstalledOn.ToString('dd/MM/yyyy')}} `
            | Sort-Object -Property Date, Update
        convert-ToMarkdownTable -inputObject $qfe
        ""
        "***Network Configuration***"
        ""
        $netips = [array]($machine.Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled })
 
        $netprops = $netips | Select-Object MACAddress, DNSDomain, 
             @{Name='Card';Expression={$_.Description}},
             @{Name='IP'; Expression = {if (-not $_.DHCPEnabled) {$_.IPAddress -join ', '} else {'DHCP'}}},
             @{Name='GW'; Expression = {if (-not $_.DHCPEnabled) {$_.DefaultIPGateway -join ', '} else {'DHCP'}}},
             @{Name='Subnet'; Expression = {if (-not $_.DHCPEnabled) {$_.IPSubnet -join ', '} else {'DHCP'}}}
             # @{Name='Suffixes'; Expression = { $_.DNSDomainSuffixSearchOrder -join "," } }

            convert-ToMarkdownTable -inputObject $netprops
        
            ""
            "DNS Suffixes search list:"
            ""
            $netips | Select-Object -Expand DNSDomainSuffixSearchOrder | ForEach-Object {
                "1. $_"
            }
            ""
        
    }
        
}

function New-MarkdownFromDirectory {
    [CmdletBinding()]
    param (
        # Parameter help description

        [String]
        $Path,
        [string]
        $OutputFile
    )

    $xmlfiles = GEt-ChildItem -Path $Path -Filter '*.xml'
@"
% Computer Inventory
% Managed Services
% $(Get-Date)

"@ | Set-Content $OutputFile -Force

    $xmlfiles | ForEach-Object {
        $xmlonefile = Import-Clixml $_.FullName
        Convert-ToMarkdown -Data $xmlonefile | Add-Content $Outputfile
    }
}

New-MarkdownFromDirectory -Path 'C:\temp2' -OutputFile 'test.md'