$iss = [System.Management.Automation.Runspaces.InitialSessionState]::Create()
$iss.ApartmentState = [System.Threading.ApartmentState]::STA
$iss.LanguageMode = [System.Management.Automation.PSLanguageMode]::FullLanguage
$iss.DisableFormatUpdates = $true
$runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($iss)
$runspace.Open()
# if ($destinationAbsolutePath) {
#     $runspace.SessionStateProxy.Path.SetLocation($destinationAbsolutePath) > $null
# }
$powershell = [PowerShell]::Create()
$powershell.Runspace = $runspace
# $expression='5+5'
$expression = '"Hello World"'
$powershell.AddScript($Expression) #  > $null
$res = $powershell.Invoke()
$res


