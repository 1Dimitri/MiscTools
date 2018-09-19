function ConvertTo-InventoryMSummary {
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

 



            $totalCapacity = 0
            $totalUsed = 0

            foreach ($vol in $obj.Volumes) {
                if ($vol.CapacityGB -eq 0) {
                } else {
                    $volCapa = $vol.CapacityGB
                    $volFree = $vol.FreeGB
                    $volUsed = $volCapa - $volFree
                    $totalCapacity += $volCapa
                    $totalUsed += $volUsed
                }


            }
 

            $AggregateHotfixes = @{}
            
            $obj.Hotfixes | Measure-Object -Maximum -Property InstalledOn,HotfixID | ForEach-Object {
                $AggregateHotfixes[$_.Property]=$_.Maximum
            }
            $LatestHFInstalledOn = $AggregateHotfixes['InstalledOn']
            if ($null -$LatestHFInstalledOn) {
                $LatestHFInstalledOn = $LatestHFInstalledOn.ToString('dd/MM/yyyy')
            }

            $HighestNumberHotfix= $AggregateHotfixes['HotfixID']

            $SystemDrive = $obj.Volumes | Where-Object { $_.Letter -eq 'C:' }

            $SystemDrive_CapacityGB= $SystemDrive.CapacityGB
            $SystemDrive_FreeGB = $SystemDrive.FreeGB

            $mdfMB = 0
            $ldfMB = 0
            $SQLVersions = ''
            if ($obj.isSQLServerInstalled) {
                foreach ($instance in $obj.SQLInstances) {
                    $db =  $instance.Databases | Where-Object { $_.DBName -eq '_Total' }
                        $mdfMB += [math]::round($db.MDFSizeKB/1024)
                        $ldfMB += [math]::round($db.LDFSizeKB/1024)
                    $SQLVersions += "$($obj.SQLVersion_Desc) $($obj.SQLEdition) "
                }
            $SQLNumberOfInstances = $obj.SQLInstances.Count
            } 

            $IPv4 = $obj.IPList | Where-Object { $_.AddressFamily -eq 'InterNetwork'} 
            if ($iPv4.Length -gt 0) {
                $FirstIPv4 = $IPv4[0]
            } else {
                $FirstIPv4 = 'N/A'
            }
            

            [PSCustomObject]@{
                ComputerName = $obj.ComputerName
                Domain = $obj.DomainWorkgroupName
                DomainRole_desc = $obj.DomainRole_desc
                Description = $obj.MachineUse_Desc
                OperatingSystem_Desc = $obj.OperatingSystem_Desc
                VirtualMachine = $obj.isVM                
                RespondToPing = $obj.Pingable
                PhysicalMemoryGB = $obj.PhysicalMemoryGB
                PhysicalProcessors = $obj.PhysicalProcessors
                LogicalProcessors = $obj.LogicalProcessors
                DataFrom = $obj.CollectedOn.ToString('dd/MM/yyyy')
                FirstIPv4 = $FirstIPv4
                DiskC_FreeGB = $SystemDrive_FreeGB
                DiskC_CapacityGB = $SystemDrive_CapacityGB
                DiskAll_capacityGB = $totalCapacity
                LatestHotfixInstalledOn = $LatestHFInstalledOn
                HighestHotfixID = $HighestNumberHotfix
                SQLServer = $obj.isSQLServerInstalled
                NUmberOfInstances = $SQLNumberOfInstances 
                SQLDataFileSMB = $mdfMB
                SQLLogFilesMB =  $ldfMB
                SQLVersions = $SQLVersions
                
                
            }
        }

    }
    
    end {

    }
}