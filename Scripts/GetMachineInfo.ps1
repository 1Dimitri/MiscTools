#requires -version 4.0

Function Get-SafeWMIResult {
    <#
   
   .SYNOPSIS
   
   
   Get-SafeWMIResult [-Class] <string> [[-Property] <string[]>] [-Filter <string>] [-Amended] [-DirectRead] [-AsJob] [-Impersonation <ImpersonationLevel>] [-Authentication <AuthenticationLevel>] [-Locale <string>] [-EnableAllPrivileges] [-Authority <string>] [-Credential <pscredential>] [-ThrottleLimit <int>] [-ComputerName <string[]>] [-Namespace <string>] [<CommonParameters>]
   
   Get-SafeWMIResult [[-Class] <string>] [-Recurse] [-Amended] [-List] [-AsJob] [-Impersonation <ImpersonationLevel>] [-Authentication <AuthenticationLevel>] [-Locale <string>] [-EnableAllPrivileges] [-Authority <string>] [-Credential <pscredential>] [-ThrottleLimit <int>] [-ComputerName <string[]>] [-Namespace <string>] [<CommonParameters>]
   
   Get-SafeWMIResult -Query <string> [-Amended] [-DirectRead] [-AsJob] [-Impersonation <ImpersonationLevel>] [-Authentication <AuthenticationLevel>] [-Locale <string>] [-EnableAllPrivileges] [-Authority <string>] [-Credential <pscredential>] [-ThrottleLimit <int>] [-ComputerName <string[]>] [-Namespace <string>] [<CommonParameters>]
   
   Get-SafeWMIResult [-Amended] [-AsJob] [-Impersonation <ImpersonationLevel>] [-Authentication <AuthenticationLevel>] [-Locale <string>] [-EnableAllPrivileges] [-Authority <string>] [-Credential <pscredential>] [-ThrottleLimit <int>] [-ComputerName <string[]>] [-Namespace <string>] [<CommonParameters>]
   
   Get-SafeWMIResult [-Amended] [-AsJob] [-Impersonation <ImpersonationLevel>] [-Authentication <AuthenticationLevel>] [-Locale <string>] [-EnableAllPrivileges] [-Authority <string>] [-Credential <pscredential>] [-ThrottleLimit <int>] [-ComputerName <string[]>] [-Namespace <string>] [<CommonParameters>]
   
   .NOTES
    
    This is a wrapper around Get-WMIObject
    It adds a "isValid" boolean flag to know if the result is OK, If it is not an Exception field holds the error message

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
                    TimeStamp = $StartTime
                    ComputerName = $MachineName
                    Pingable = $isPingable
                    LocalHost = $isLocal
                    InvalidData = [System.Collections.ArrayList]@()
                }
        
            if (-not $isPingable) {
                return [PSCustomObject] $ReturnProperties
            }

            $creds = $null
        
            if ($hasCredentialCallback) {
                Write-Verbose "Retrieving credentials"
                [pscredential] $creds = Invoke-Command $CredentialCallback -ArgumentList $MachineName
            }
            Write-Verbose "Getting WMI Properties"
        
            $WMIClasses = @('Win32_ComputerSystem','Win32_OperatingSystem','Win32_Product','Win32_LogicalDisk','Win32_Volume','Win32_DiskDrive','Win32_NetworkAdapterConfiguration','Win32_QuickFixEngineering')
            

            foreach ($WMIClass in $WMIClasses) {
                Write-Verbose "WMI Class: $wmiclass"
                $WMIParameters = @{
                    'class'= $WMIClass
                }
                if (-not $isLocal) {
                    $WMIParameters['ComputerName'] = $MachineName                    
                        
                    if ($null -ne $creds) {
                        $WMIParameters.Add('Credential',$creds)
                        Write-Verbose "Credentials retrieved = $creds"
                    }
                           
                }
                    # Queries
                $wmiresult = Get-SafeWMIResult @WMIParameters

                Write-Verbose "Finished W"
                if ($wmiresult.isValid) {
                    Write-Verbose "${MachineName}: $WMIclass -> OK"
                    $ReturnProperties.Add($WMIClass,$wmiresult)
                } else {
                 -Credential  Write-Verbose "${MachineMame}: $WMIClass -> error"
                    $ReturnProperties["InvalidData"].Add($WMIClass)
                }

            } # foreach WMIClass
            [PSCustomObject] $ReturnProperties

        } # foreach MachineName
    

    }
    
}
