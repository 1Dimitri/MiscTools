# TODO: SQL Installed loop
# Round GB


# function Test-CreateNewDirectory {
#     param (
#         [Parameter(Mandatory=true,Position=0)]
#         [String]$Path
#     )
#     if (!(Test-Path $Path)) {
#         Write-Verbose "Creating Destination Directory $Path"
#         New-Item -ItemType Directory -Path $Path -Force | Out-Null
#     } 
# }
function New-BusinessObject {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory=$true,Position=0)]
        [String]
        $SourcePath
        # [Parameter(Mandatory=$true,Position=1)]
        # [String]
        # $DestinationPath
        
    )
    
    begin {
        $xmlfiles = Get-ChildItem -Recurse -Filter '*.xml' -Path $SourcePath
      #  Test-CreateNewDirectory -Path $DestinationPath
        $NotRespondingMachines = [System.Collections.ArrayList]@()
        $SyntaxErrorFiles = [System.Collections.ArrayList]@()

    }
    
    process {
        foreach ($xmlfile in $xmlfiles) {
            Write-Verbose "Importing $($xmlfile.Fullname)"
            $myxml = Import-Clixml $xmlfile.FullName
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
                $RAM_GB = $machine.Win32_ComputerSystem.TotalPhysicalMemory / 1GB

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
                $OS_SP_Desc = $machine.Win32_OperatingSystem.CSDVersion
                $OS_Build = $machine.Win32_OperatingSystem.BuildNumber
                $OSArchitecture = $machine.Win32_OperatingSystem.OSArchitecture
                $OSFriendlyName = (@($OS_Generation_Edition_Desc,$OS_SP_Desc) -join ' ').trim() + " $OSArchitecture ($OS_Build)"

                # KB
                $hotfixes = [System.Collections.ArrayList]@()
                foreach ($hotfix in $machine.Win32_QuickFixEngineering) {
                    # Keep number and installation date
                    $isnuminKB = $hotfix.HotfixID -match '\d+'
                    if ($isnuminKB) {
                        $hfname = $Matches[0].Value
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
                    $totalspace = $Volume.Size/1GB
                    $freespace = $Volume.FreeSpace /1GB
                    $Volumes.Add([PSCustomObject]@{
                        Letter = $letter
                        "Type" = $disktype
                        "TypeDesc" = $disktype_desc
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
                $isSQLServerInstalled = $machine.isSQLServerInstalled
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
                    if ($InstanceName -eq 'MSSQLSERVER') {
                        $InstanceName = $ComputerShortname
                    } else {
                        $InstanceName = $ComputerShortname + '\' + $InstanceName
                    }

                    $SQLEdition = $hashTablebySqlServiceProp['SKUNAME'].PropertyStrValue
                    $SQLVersion = $hashTablebySqlServiceProp['VERSION'].PropertyStrValue
                    $SQLVersionParts = $SQLVersion -split '\.'

                    $sqlMajorVersion = switch ([int] $SQLVersionParts[0]) {
                        8 { '2000'; break;  }
                        9 { '2005'; break;  }
                        10{ 
                            if ([int] $SQLVersionParts[1] -gt 50 ) {
                                '2008 R2'
                            } else {
                                '2008'
                            }
                            break;  }
                        11 { '2012'; break;  }
                        12 { '2014'; break;  }
                        13 { '2016'; break;  }
                        14 { '2017'; break}
                        Default { 'Internal Number '+$SQLVersionParts[0]}
                    }
                    $sqlServicePack = ([int] $SQLVersionParts[1]) % 50
                    

                    $SQLVersion_Desc = "SQL Server $sqlMajorVersion " 
                    if ($sqlServicePack -ne 0) {
                        $SQLVersion_Desc += "SP $sqlServicePack"
                    } else {
                        $SQLVersion_Desc += "RTM"
                    }

                    $instances.Add([PSCustomObject]@{
                        SQLVersion = $SQLVersion
                        SQLEdition = $SQLEdition
                        SQLVersion_Desc = $SQLVersion_Desc
                        InstanceName = $InstanceName
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
        }
    }
    
    end {

    }
}