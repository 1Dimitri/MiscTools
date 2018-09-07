#requires -version 4.0

Function Get-SafeWMIResult {
    <#
   .SYNOPSIS
   Get-SafeWMIResult [-Class] <string> [[-Property] <string[]>] [-Filter <string>] [-Amended] [-DirectRead] [-AsJob] [-Impersonation <ImpersonationLevel>] [-Authentication <AuthenticationLevel>] [-Locale <string>] [-EnableAllPrivileges] [-Authority <string>] [-Credential <pscredential>] [-ThrottleLimit <int>] [-ComputerName <string[]>] [-Namespace <string>] [<CommonParameters>]
   Get-SafeWMIResult [[-Class] <string>] [-Recurse] [-Amended] [-List] [-AsJob] [-Impersonation <ImpersonationLevel>] [-Authentication <AuthenticationLevel>] [-Locale <string>] [-EnableAllPrivileges] [-Authority <string>] [-Credential <pscredential>] [-ThrottleLimit <int>] [-ComputerName <string[]>] [-Namespace <string>] [<CommonParameters>]
   Get-SafeWMIResult -Query <string> [-Amended] [-DirectRead] [-AsJob] [-Impersonation <ImpersonationLevel>] [-Authentication <AuthenticationLevel>] [-Locale <string>] [-EnableAllPrivileges] [-Authority <string>] [-Credential <pscredential>] [-ThrottleLimit <int>] [-ComputerName <string[]>] [-Namespace <string>] [<CommonParameters>]
   Get-SafeWMIResult [-Amended] [-AsJob] [-Impersonation <ImpersonationLevel>] [-Authentication <AuthenticationLevel>] [-Locale <string>] [-EnableAllPrivileges] [-Authority <string>] [-Credential <pscredential>] [-ThrottleLimit <int>] [-ComputerName <string[]>] [-Namespace <string>] [<CommonParameters]   
   Get-SafeWMIResult [-Amended] [-AsJob] [-Impersonation <ImpersonationLevel>] [-Authentication <AuthenticationLevel>] [-Locale <string>] [-EnableAllPrivileges] [-Authority <string>] [-Credential <pscredential>] [-ThrottleLimit <int>] [-ComputerName <string[]>] [-Namespace <string>] [<CommonParameters>]
   
   .NOTES 
    This is a wrapper around Get-WMIObject
    It adds a "isValid" boolean flag to know if the result is OK, if it is not an Exception field holds the error message

   #>
    [CmdletBinding(DefaultParameterSetName='query', RemotingCapability='OwnedByCommand')] 
   Param(
   
       [Parameter(ParameterSetName='query', Mandatory=$true, Position=0)]
       [Parameter(ParameterSetName='list', Position=1)]
       [Alias('ClassName')]
       [string]$Class,
   
       [Parameter(ParameterSetName='list')]
       [switch]$Recurse,
   
       [Parameter(ParameterSetName='query', Position=1)]
       [string[]]$Property,
   
       [Parameter(ParameterSetName='query')]
       [string]$Filter,
   
       [switch]$Amended,
   
       [Parameter(ParameterSetName='WQLQuery')]
       [Parameter(ParameterSetName='query')]
       [switch]$DirectRead,
   
       [Parameter(ParameterSetName='list')]
       [switch]$List,
   
       [Parameter(ParameterSetName='WQLQuery', Mandatory=$true)]
       [string]$Query,
   
       [switch]$AsJob,
   
       [Parameter(ParameterSetName='list')]
       [Parameter(ParameterSetName='class')]
       [Parameter(ParameterSetName='WQLQuery')]
       [Parameter(ParameterSetName='query')]
       [Parameter(ParameterSetName='path')]
       [System.Management.ImpersonationLevel]$Impersonation,
   
       [Parameter(ParameterSetName='path')]
       [Parameter(ParameterSetName='class')]
       [Parameter(ParameterSetName='WQLQuery')]
       [Parameter(ParameterSetName='query')]
       [Parameter(ParameterSetName='list')]
       [System.Management.AuthenticationLevel]$Authentication,
   
       [Parameter(ParameterSetName='query')]
       [Parameter(ParameterSetName='class')]
       [Parameter(ParameterSetName='WQLQuery')]
       [Parameter(ParameterSetName='path')]
       [Parameter(ParameterSetName='list')]
       [string]$Locale,
   
       [Parameter(ParameterSetName='query')]
       [Parameter(ParameterSetName='class')]
       [Parameter(ParameterSetName='WQLQuery')]
       [Parameter(ParameterSetName='path')]
       [Parameter(ParameterSetName='list')]
       [switch]$EnableAllPrivileges,
   
       [Parameter(ParameterSetName='path')]
       [Parameter(ParameterSetName='class')]
       [Parameter(ParameterSetName='WQLQuery')]
       [Parameter(ParameterSetName='query')]
       [Parameter(ParameterSetName='list')]
       [string]$Authority,
   
       [Parameter(ParameterSetName='query')]
       [Parameter(ParameterSetName='class')]
       [Parameter(ParameterSetName='WQLQuery')]
       [Parameter(ParameterSetName='path')]
       [Parameter(ParameterSetName='list')]
       [pscredential]
       [System.Management.Automation.CredentialAttribute()]$Credential,
   
       [int]$ThrottleLimit,
   
       [Parameter(ParameterSetName='path')]
       [Parameter(ParameterSetName='class')]
       [Parameter(ParameterSetName='WQLQuery')]
       [Parameter(ParameterSetName='query')]
       [Parameter(ParameterSetName='list')]
       [Alias('Cn')]
       [ValidateNotNullOrEmpty()]
       [string[]]$ComputerName,
   
       [Parameter(ParameterSetName='class')]
       [Parameter(ParameterSetName='path')]
       [Parameter(ParameterSetName='WQLQuery')]
       [Parameter(ParameterSetName='query')]
       [Parameter(ParameterSetName='list')]
       [Alias('NS')]
       [string]$Namespace
   )
    
   Begin {
    
       Write-Verbose "Starting $($MyInvocation.Mycommand)"
       Write-Verbose "Using parameter set $($PSCmdlet.ParameterSetName)"
       Write-Verbose ($PSBoundParameters | out-string)
     
       Write-Verbose "Forcing ErrorAction"
       if ($PSBoundParameters.ContainsKey('ErrorAction')) {
           $errorAction = $PSBoundParameters['ErrorAction']
           Write-Verbose "erroraction was $ErrorACtion"
           $PSBoundParameters.Remove('ErrorAction')
       }
   } #begin
    
   Process {
    
        $result = @{}
       # Add a try block so we always get a valid flag
        try {
               $result = Get-WmiObject @PSBoundParameters -ErrorAction Stop
               $result | Add-Member -MemberType NoteProperty -Name isValid -Value $true 
               Write-VErbose "WMI Query successful"
            
            }
        catch {
              $result = @{
                 isValid = $false
                 exception = $_                 
                }   
             Write-Verbose "error while retrieving..."
        }

        Write-Verbose "Returning $result"
        [PSCustomObject] $result
   } #process
    
   End {
      
       Write-Verbose "Ending $($MyInvocation.Mycommand)"
     
   } #end
     
   } #end function Get-SafeWMIResult
   
function Get-SafeWMIFullClass {
    [CmdletBinding()]
    param (
        [parameter(mandatory=$true, position=0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Classes,
        [parameter(mandatory=$false, position=1, ValueFromRemainingArguments=$true)]
        [Hashtable]$WMICommonParameters      
    )
    
    begin {
        $ReturnProperties = @{'_InvalidData'=  [System.Collections.ArrayList]@()}
    }
    
    process {     
        foreach ($WMIClass in $Classes) {
            Write-Verbose "WMI Class: $wmiclass"
 
            # Queries
            if ($null -ne $WMICommonParameters) {
                $wmiresult = Get-SafeWMIResult -Class $WMIClass @WMICommonParameters
            }
            else {
                $wmiresult = Get-SafeWMIResult -Class $WMIClass 
            }

            Write-Verbose "Finished WMI Query for $WMIClass "
            if ($wmiresult.isValid) {
                Write-Verbose "${MachineName}: $WMIclass -> OK"
                $ReturnProperties.Add($WMIClass,$wmiresult)
            } else {
                Write-Verbose "${MachineMame}: $WMIClass -> error"
                $ReturnProperties["_InvalidData"].Add($WMIClass)
            }
        } # foreach WMIClass
    }
    
    end {
        $ReturnProperties
    }
}

function Add-SafeMember {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [Hashtable]
        $InputObject,
        [Hashtable]
        $Member,
        [String]
        $Prefix
    )
    
    
    foreach ($k in $Member.Keys)    {
        if ('_InvalidData' -ne $k) {
                if ($PSBoundParameters.ContainsKey('Prefix')) {
                    $Keyname = "$Prefix_$k"
                } else {
                $Keyname = $k
                 }
                 $InputObject.Add($keyname,$InputObject[$k])
     
        } else {
            $newdata = [System.Collections.ArrayList]@()
            foreach ($k in $InputObject[$k]) { if ($null -ne $Prefix) { $newdata.Add("$prefix_$k") } else { $newdata.Add($k)} }  
            $InputObject.Add('_InvalidData',$InputObject[$k])
        }
    }
    
}
Function Get-WmiNamespace ($Path = 'root')
{
    foreach ($Namespace in (Get-WmiObject -Namespace $Path -Class __Namespace))
    {
        $FullPath = $Path + "/" + $Namespace.Name
        Write-Output $FullPath
        Get-WmiNamespace -Path $FullPath
     }
} 

Function Test-SafeWMINamespace {
    [CmdletBinding()]
    param(
    [parameter(mandatory=$true, position=0)]
    [ValidateNotNullOrEmpty()]
    [string]$Namespace,
    [parameter(mandatory=$false, position=1, ValueFromRemainingArguments=$true)]$WMICommonParameters      
    )

    if ($null -ne $WMICommonParameters) {
        $result = Get-SafeWMIResult -Class __Namespace -Namespace $Namespace @WMICommonParameters
    } else {        
        $result = Get-SafeWMIResult -Class __Namespace -Namespace $Namespace
    }
    $result.isValid
}
function Get-InventoryData {
    [CmdletBinding()]
    param (
        [Alias('Cn')]
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline)]
        [string[]]$ComputerName=$Env:COMPUTERNAME,
        [scriptblock]$CredentialCallback
    )

    begin
        {
            Write-Verbose "Getting the same initial time for every computer"
            $StartTimeAll = Get-Date
            $hasCredentialCallback = $PSBoundParameters.ContainsKey('CredentialCallback')
            Write-Verbose "Testing if a credential callback function is here: $hasCredentialCallback"

        }
    process {
        foreach ($MachineName in $Computername)
        {
            Write-Verbose "Gathering data for $MachineName"
        
            Write-Verbose "Testing if we are on the machine we try to access"
            $isLocal = ($null -eq $MachineName) -or ($MachineName.ToUpper() -in ('','LOCALHOST','127.0.0.1','::1',${Env:COMPUTERNAME}.ToUpper()))
            Write-Verbose "Testing connectivity"
            if ($isLocal) {
                $PingMachineName = "LOCALHOST"
            }
            else {
                $PingMachineName = $MachineName
            }
            $isPingable = Test-Connection -ComputerName $PingMachineName -Quiet
        
            $ReturnProperties = @{
                    TimeStamp = $StartTimeAll
                    _CompatibilityLevel = '1.0'
                    _BuildVersion = '20180906.0'
                    ComputerName = $MachineName
                    Pingable = $isPingable
                    LocalHost = $isLocal
                   # InvalidData = [System.Collections.ArrayList]@()
                }
        
            if (-not $isPingable) {
                return [PSCustomObject] $ReturnProperties
            }

            $creds = $null
        
            if ($hasCredentialCallback) {
                Write-Verbose "Retrieving credentials"
                [pscredential] $creds = Invoke-Command $CredentialCallback -ArgumentList $MachineName
            }

            $WMICommonParameters = @{}
            if (-not $isLocal) {
                $WMICommonParameters['ComputerName'] = $MachineName                    
                    
                if ($null -ne $creds) {
                    $WMICommonParameters.Add('Credential',$creds)
                    Write-Verbose "Credentials retrieved = $creds"
                }
                       
            }

            # Classes we try to get every time
            Write-Verbose "Getting Standard WMI Properties for $MachineName"        
            $WMIClasses = @('Win32_ComputerSystem','Win32_OperatingSystem','Win32_Product','Win32_LogicalDisk','Win32_Volume','Win32_DiskDrive','Win32_NetworkAdapterConfiguration','Win32_QuickFixEngineering')
            $WMIBasicProperties = Get-SafeWMIFullClass -Classes $WMIClasses @WMICommonParameters

            $ReturnProperties += $WMIBasicProperties

            Write-Verbose "Trying to get SQL Server Information"
            $SQLServerNamespace = 'root/Microsoft/SqlServer'
            $isSQLServerInstalled = Test-SafeWMINamespace -Namespace $SQLServerNamespace @WMICommonParameters
            $ReturnProperties.Add('isSQLServerInstalled',$isSQLServerInstalled)
            if ($isSQLServerInstalled) {

                $sqlclasses = Get-SafeWMIResult -Class __NAMESPACE -Namespace $SQLServerNamespace
                $isSSRSInstalled = $sqlclasses | Where-Object { $_.Name -eq 'ReportServer'}
                $dbEngineVersions = [array] $sqlclasses | Where-Object { $_.Name -like 'ComputerManagement*'}
                foreach($dbVersion in $dbEngineVersions) {
                    $namespaceToQuery = $SQLServerNamespace +'/'+ $dbVersion.Name 
                    $WMISQLClasses = @('ServerSettings','SqlService','SqlServiceAdvancedProperty')
                    $sqlresult = Get-SafeWMIFullClass -Classes $WMISQLClasses @WMICommonParameters -Namespace $namespaceToQuery
                    $ReturnProperties = Add-SafeMember -InputObject $ReturnProperties -Member $sqlresult
                }

                $instanceNames = [System.Collections.ArrayList]@()
                $perfClasses = Get-SafeWMIResult -List -Class 'Win32_PerfFormattedData_*_SQLServerDatabases'
                foreach ($perfInstance in $perfClasses) {
                    $ReturnProperties.Add($perfInstance.__CLASS,$perfInstance)
                    $instanceNames.Add($perfInstance.__CLASS -replace 'Win32_PerfFormattedData_(.+)_SQLServerDatabases','$1')
                }
            }

            $ReturnProperties.Add('SQLServerInstanceNames',$instanceNames)
            $ReturnProperties.Add('isSSRSInstalled',$isSSRSInstalled)
            [PSCustomObject] $ReturnProperties

        } # foreach MachineName
    

    }
    
}
