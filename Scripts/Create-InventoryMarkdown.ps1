function ConvertTo-InventoryMarkdown {
    [CmdletBinding()]
    param (
        # Parameter help description
       [Parameter(Mandatory=$true,Position=0)]
        [Object[]]
        $Objects
        
       
    )
    
    begin {
    }
    
    process {
       foreach ($obj in $Objects) {
            Write-Verbose "Importing $($obj.ComputerName)"

            "# $($obj.ComputerName)"
            ""
            if (-not $obj.Pingable) {
                "This computer didn't respond to connection attempt on _$($obj.CollectedOn.ToString('dd-MMM-yyyy HH:mm'))_"
                "----"
                ""
                continue
            }

            if ($o.isPartOfDomain) {
                "## $($obj.DomainRole_Desc) in $($obj.DomainWorkgroupName)"                
            } else {
                "## $($obj.DomainRole_Desc)"
            }
            ""
            "**$($obj.MachineUse_Desc)**"
            ""
            "### Operating System"
            "$($obj.OperatingSystem_Desc)"
            ""
            "### Hardware"
            "RAM: $($obj.PhysicalMemoryGB) GB"
            ""
            "CPU (Log./Phy.): $($obj.LogicalProcessors)/$($obj.PhysicalProcessors)"
            ""
            "Kind: $($obj.Manufacturer) $($obj.Model) [$(if ($obj.isVM) {'Virtual'} else {'Physical'}) Machine]"
            ""
            "### Storage"
            ""
            "Drive | Type | Capacity (GB) | Free (GB) | Used (GB) | % Used"
            "-|-|-|-|-|-"
            $totalCapacity = 0
            $totalUsed = 0

            foreach ($vol in $obj.Volumes) {
                if ($vol.CapacityGB -eq 0) {
                    $volCapa = 'N/A'
                    $volUsed='N/A'
                    $volFree='N/A'
                    $volPercentUsed = 'N/A'
                } else {
                    $volCapa = $vol.CapacityGB
                    $volFree = $vol.FreeGB
                    $volUsed = $volCapa - $volFree
                    $volPercentUsed = [Math]::Round($volUsed / $volCapa * 100,1)
                    $totalCapacity += $volCapa
                    $totalUsed += $volUsed
                }
                "$($vol.Letter)|$($vol.Type_Desc)|$volCapa|$volFree|$volUsed|$volPercentUsed"

            }
            "Total| N/A | $totalCapacity | N/A | $totalUsed | N/A "
            ""
            "### Network"
            foreach ($IP in $obj.IPList) {
                "- $($IP.ToString())"                
            }
            ""
            ""
            "### Updates and hotfixes"
            ""
            "KB Number | Installed On"
            "-|-"
            foreach ($update in $obj.Hotfixes) {
                "$($update.HotfixID) | $($update.InstalledOn.ToString('dd-MMM-yyyy'))"
            }
            ""
            "### Software"
            ""
            "Name | Version"
            "-|-"
            foreach ($prd in ($obj.Products | Sort-Object -Property Name)) {
                "$($prd.Name) |  $($prd.Version)"                
            }

            ""
            "### SQL Server"
            ""
            if ($obj.isSQLServerInstalled) {
                "#### List of instances"
                ""
                "Name | Version | Edition "
                "-|-|-"
                foreach ($instance in $obj.SQLInstances) {
                    "$($instance.InstanceName)|$($instance.SQLVersion_desc)|$($instance.SQLEdition)"
                }
                ""
                "#### Databases per instance"
                ""
                "Instance | Database |data files(MB) | log files(MB) | data+log(MB)"
                "-|-|-|-|-"
                foreach ($instance in $obj.SQLInstances) {
                   
                    foreach ($db in $instance.Databases) {
                        $mdfMB = [math]::round($db.MDFSizeKB/1024)
                        $ldfMB = [math]::round($db.LDFSizeKB/1024)
                        "$($instance.InstanceName) | $($db.DBName) | $($mdfMB) | $($ldfMB) | $($mdfMB+$ldfMB)"
                    }
                }

            } else {
                "SQL Server was not detected on this machine"
            }
            ""
            "Data gathered on: _$($obj.CollectedOn.ToString('dd-MMM-yyyy HH:mm'))_"
            "----"
            ""
        }

    }
    
    end {

    }
}