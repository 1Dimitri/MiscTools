Function Get-NetFrameworkVersion{
<#
.SYNOPSIS
Get the .Net Framework 4.5. version

.DESCRIPTION
Retrieves the


.OUTPUTS
String

.EXAMPLE
Get-NetFrameworkVersion


.LINK
https://msdn.microsoft.com/en-us/library/hh925568(v=vs.110).aspx

.NOTES
Author:	1Dimitri

#>
	[CmdletBinding()]
	Param(
	)
	
	$key45 = (Get-ItemProperty "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full" -Name Release).Release
	
	switch ($key45) {
	   378389 { "4.5.0" }
	   378675 { "4.5.1" }
	   378758 { "4.5.1" }
	   379893 { "4.5.2" }
	   393295 { "4.6.0" }
	   393297 { "4.6.0" }
	   394254 { "4.6.1" }
	   394271 { "4.6.1" }
	   394802 { "4.6.2" }
	   394806 { "4.6.2" }
	   460798 { "4.7.0" }
	   460805 { "4.7.0" }
	   461308 { "4.7.1" }
	   461310 { "4.7.1" }
	   
	   default { "0.0.0" }
	}
}
