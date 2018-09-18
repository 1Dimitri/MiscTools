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
            "## $($obj.DomainRole_Desc)"
            "$($obj.MachineUse_Desc)"

            "### Operating System"
            "$($obj.OperatingSystem_Desc)"

            "### Hardware"
            "RAM: $($obj.PhysicalMemoryGB) GB"
            ""
            "CPU (Log./Phy.): $($obj.LogicalProcessors)/$($obj.PhysicalProcessors)"
            ""
            "$($obj.Manufacturer) $($obj.Model) [$(if ($obj.isVM) {'Virtual'} else {'Physical'}) Machine]"
            
            "### Storage"

            "### Network"
            foreach ($IP in $obj.IPList) {
                "- $($IP.ToString())"                
            }

            "### Software"
            foreach ($prd in ($obj.Products | Sort-Object -Property Name)) {
                "- $($prd.Name) $($prd.Version)"                
            }

        }
    }
    
    end {

    }
}