function New-InventoryBusinessObject {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='directory')]
        [String]
        $SourcePath,
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='xmlarray')]
        [Object[]]
        $Objects
        
        # [Parameter(Mandatory=$true,Position=1)]
        # [String]
        # $DestinationPath
        
    )
    
    begin {
        if ($PSCmdlet.ParameterSetName -eq 'directory') {
            $xmlfiles = Get-ChildItem -Recurse -Filter '*.xml' -Path $SourcePath
            $myxml = foreach ($xmlfile in $xmlfiles) {
                Import-CliXml $xmlfile
            }
    } else {
        $myxml = $Objects
    }
      #  Test-CreateNewDirectory -Path $DestinationPath
        $NotRespondingMachines = [System.Collections.ArrayList]@()
        $SyntaxErrorFiles = [System.Collections.ArrayList]@()

    }
    
    process {
     #  foreach ($xmlfile in $xmlfiles) {
            Write-Verbose "Importing $($xmlfile.Fullname)"
            # $myxml = Import-Clixml $xmlfile.FullName
            foreach ($machine in [array]$myxml) {
                $ComputerName = $Machine.ComputerName
                if ([String]::IsNullOrEmpty($ComputerName)) {
                    Write-Verbose "Found incorrect snippet"
                    $SyntaxErrorFiles.Add($fileinfo.Fullname) | Out-Null
                    continue
                }
                Write-Verbose "Working on $ComputerName"
                $isPingable = $Machine.Pingable
                if (!($isPingable)) {
                    Write-Verbose "$ComputerName didn't respond to ping"
                    $NotRespondingMachines.Add($ComputerName) | Out-Null
                    [PSCustomObject]@{
                        ComputerName = $Computername
                        CollectedOn = if ($null -ne $machine.TimeStamp) {
                            $machine.TimeStamp
                        } else {
                            Get-Date
                        }
                        Pingable = $false
                        InternalVersion = if ($null -ne $ComputerName._BuildVersion) {
                            $ComputerName._BuildVersion
                        } else {
                            '19700101.0'
                        }
                    }
                    continue
                }

                # Computer name
                $ComputerShortname = $machine.Win32_ComputerSystem.DNSHostName
                $Model = $machine.Win32_ComputerSystem.Model
                $Manufacturer = $machine.Win32_ComputerSystem.Manufacturer

                #Metadata
                $DataFreshnessTimestamp = $machine.Timestamp
                $InternalVersion = $machine._BuildVersion

                # TODO: Add HyperV, VirtualBox, etc.
                $isVM = $Model.StartsWith('VMware')

                # CPU
                $LogicalProcessors = $machine.Win32_ComputerSystem.NumberOfLogicalProcessors
                $PhysicalProcessors = $machine.Win32_ComputerSystem.NumberOfProcessors

                # RAM
                $RAM_GB = [Math]::Round($machine.Win32_ComputerSystem.TotalPhysicalMemory / 1GB)

                # Domain or Workgroup and role
                $isPartOfDomain = $machine.Win32_ComputerSystem.PartOfDomain

                $DomainRole_desc_array = @('Standalone Workstation', 'Member Workstation', 'Standalone Server', 'Member Server', 'Domain Controller', 'Domain Controller (PDC Emulator)')
                $DomainRole = $machine.Win32_ComputerSystem.DomainRole

                if (($null -ne $DomainRole) -and ($null -ne ($DomainRole -as [int]))) {
                    $DomainRoleDesc = $DomainRole_desc_array[$DomainRole]
                } else {
                    $DomainRoleDesc = "Domain Role Value is: $DomainRole"
                }
                if ($isPartOfDomain) {
                    $DomainWorkgroup = $machine.Win32_ComputerSystem.Domain
                } else {
                    $DomainWorkgroup = $machine.Win32_ComputerSystem.Workgroup
                }

                # Operating System
                $HumanPurposeDescription = $machine.Win32_OperatingSystem.description
                $OS_Generation_Edition_Desc = $machine.Win32_OperatingSystem.Caption
                $OS_SP_Desc = $machine.Win32_OperatingSystem.CSDVersion # may be null
                $OS_Build = $machine.Win32_OperatingSystem.BuildNumber
                $OSArchitecture = $machine.Win32_OperatingSystem.OSArchitecture
                $OSFriendlyName = (@($OS_Generation_Edition_Desc,$OS_SP_Desc) -join ' ').trim() + " $OSArchitecture ($OS_Build)"
                $OSFriendlyName = $OSFriendlyName -replace '  ',' '
                # KB
                $hotfixes = [System.Collections.ArrayList]@()
                foreach ($hotfix in $machine.Win32_QuickFixEngineering) {
                    # Keep number and installation date
                    $isnuminKB = $hotfix.HotfixID -match '\d+'
                    if ($isnuminKB) {
                        $hfname = $Matches[0]
                    } else {
                        $hfname = $hotfix.HotfixID
                    }
                    $hotfixes.Add([PSCustomObject]@{
                        HotfixID = $hfname
                        InstalledOn = $hotfix.InstalledOn
                    }) | Out-Null
                }

                # Software
                $Products = [System.Collections.ArrayList]@()
                foreach ($product in $machine.Win32_Product) {
                    $products.Add([PSCustomObject]@{
                        Name = $product.Caption
                        Version = $product.Version
                    }) | Out-Null
                }

                # Storage                
                $Volumes = [System.Collections.ArrayList]@()
                foreach ($Volume in $machine.Win32_LogicalDisk) {
                    $letter = $Volume.Caption
                    $disktype_desc = $Volume.description
                    $disktype = $Volume.DriveType                    
                    $totalspace = [Math]::Round($Volume.Size/1GB)
                    $freespace = [Math]::Round($Volume.FreeSpace /1GB,2)
                    $Volumes.Add([PSCustomObject]@{
                        Letter = $letter
                        "Type" = $disktype
                        "Type_Desc" = $disktype_desc
                        CapacityGB = $totalspace
                        FreeGB = $freespace
                    }) | Out-Null         
                }
                
                # IP Addresses
                $IPlist = [System.Collections.ArrayList]@()
                # $IPgw = [System.Collections.ArrayList]@()
                $IPs = $machine.Win32_NetworkAdapterConfiguration | Where-Object{ $_.IPEnabled  }
                foreach ($IPAdapter in $IPs) {
                    foreach ($ip in $IPAdapter.IPAddress) {
                        try {
                            $IPObj = [System.Net.IPAddress] $ip
                            $IPlist.Add($IPObj) | Out-Null
                        } catch {

                        }

                        # $IPList.Add([System.Net.IPAddress]::TryParse($ip)) # | Out-Null
                    }
                    # to do: Gateway and Subnet mask
                }

                # SQL
                # work around bugs in version where $machine.isSQLServerInstalled was returned as array of boolean instead of boolean
                $isSQLServerInstalled = $machine.isSQLServerInstalled | Sort-Object -Unique
                if ($isSQLServerInstalled) {
                    $instances = [System.Collections.ArrayList]@()
                    # Get the Service Advanced properties
                    $dbEnginesProperties = $machine.SqlServiceAdvancedProperty | Where-Object { $_.SqlServiceType -eq 1 }
                    $serviceNames = $dbEnginesProperties | Group-Object -Property ServiceName 

                    foreach ($servicename in $serviceNames) {
                        $hashTablebySqlServiceProp = @{}
                        foreach ($SQLSvcProp in $servicename.Group) {
                            $hashTablebySqlServiceProp[$SQLSvcProp.PropertyName]=$SQLSvcProp
                        }
                    

                    $InstanceID = $hashTablebySqlServiceProp['INSTANCEID'].PropertyStrValue
                    # TO DO: Not valid for clustered code
                    $InstanceName = $InstanceID -replace '^MSSQL(\d)+\.',''
                    $SQLInstanceNameInPerfCounter = $InstanceID -replace '(^MSSQL)\d+\.(.+)','$1$2'
                        #Write-VErbose "***$SQLInstanceNameInPerfCounter***"
                    if ($InstanceName -eq 'MSSQLSERVER') {
                        $InstanceName = $ComputerShortname
                    } else {
                        $InstanceName = $ComputerShortname + '\' + $InstanceName
                    }
                    $InstanceName = $InstanceName.ToUpper()

                    $SQLEdition = $hashTablebySqlServiceProp['SKUNAME'].PropertyStrValue
                    $SQLVersion = $hashTablebySqlServiceProp['VERSION'].PropertyStrValue
                    $SQLVersionParts = $SQLVersion -split '\.'

                    $sqlMajorVersion = switch ([int] $SQLVersionParts[0]) {
                        8 { '2000'; break;  }
                        9 { '2005'; break;  }
                        10{ 
                            if ([int] $SQLVersionParts[1] -ge 50 ) {
                                '2008 R2'
                            } else {
                                '2008'
                            }
                            break;  }
                        11 { '2012'; break;  }
                        12 { '2014'; break;  }
                        13 { '2016'; break;  }
                        14 { '2017'; break; }
                        Default { 'Internal Number '+$SQLVersionParts[0]}
                    }
                    $sqlServicePack = ([int] $SQLVersionParts[1]) % 50
                    

                    $SQLVersion_Desc = "SQL Server $sqlMajorVersion " 
                    if ($sqlServicePack -ne 0) {
                        $SQLVersion_Desc += "SP $sqlServicePack"
                    } else {
                        $SQLVersion_Desc += "RTM"
                    }

                    # Try to get the database names and size through PerfData
                    # SQLCounter name is Win32_PerfFormattedData_MSSQL<InstanceName>_MSSQL<InstanceNAme>Databases (!)
                    $SQLCounterName = "Win32_PerfFormattedData_${SQLInstanceNameInPerfCounter}_${SQLInstanceNameInPerfCounter}Databases"
                    $databases = [System.Collections.ArrayList]@()
                    $machine.$SQLCounterName | ForEach-Object {
                        $databases.Add([PSCustomObject]@{
                            DBName = $_.Name
                            MDFSizeKB = $_.DataFilesSizeKB
                            LDFSizeKB = $_.LogFilesSizeKB 
                            LDFInUseKB = $_.LogFilesUsedSizeKB 
                        }) | Out-Null
                    }

                    $instances.Add([PSCustomObject]@{
                        SQLVersion = $SQLVersion
                        SQLEdition = $SQLEdition
                        SQLVersion_Desc = $SQLVersion_Desc
                        InstanceName = $InstanceName
                        Databases = $databases
                    }) | Out-Null

                }
                }


                # Return the full monty

                [PSCustomObject]@{
                    ComputerName = $ComputerShortname     
                    
                    # Membership

                    DomainRole = $DomainRole
                    DomainWorkgroupName = $DomainWorkgroup
                    
                    # Hardware
                    Manufacturer = $Manufacturer
                    Model = $Model

                    IPList = $IPlist
                    PhysicalMemoryGB = $RAM_GB
                    LogicalProcessors = $LogicalProcessors
                    PhysicalProcessors = $PhysicalProcessors
                    OSBuild = $OS_Build
                    Volumes = $Volumes

                    # Software
                    Products = $Products
                    Hotfixes = $hotfixes

                    # SQL
                    isSQLServerInstalled = $isSQLServerInstalled
                    SQLInstances = $instances

                    # Metadata
                    CollectedOn = $DataFreshnessTimestamp
                    InternalVersion = $InternalVersion
                    Pingable = $true

                    # Friendly properties / calculated properties

                    DomainRole_Desc = $DomainRoleDesc
                    MachineUse_Desc = $HumanPurposeDescription
                    isVM = $isVM
                    isPartOfDomain = $isPartOfDomain
                    OperatingSystem_Desc = $OSFriendlyName       
                }
            }
        #}
    }
    
    end {

    }
}