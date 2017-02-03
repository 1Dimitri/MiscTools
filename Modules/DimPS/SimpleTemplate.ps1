<#
.Synopsis
   Get a list of variables
.DESCRIPTION
   Get a list of the variables this template contains in the form !!variable!! or !!variable:help text!!
.EXAMPLE
   Get-Content 'C:\temp\file.txt' | Get-QuickTemplateVariableList
.INPUTS
  Pipeline is text of the template
#>
Function Get-QuickTemplateVariableList {

Begin  {
  $varlist = @{}
}

Process {
 if ($_ -match '!!(?<VariableName>[\w\d]+)(:(?<Purpose>.+?))?!!') {
        $varname = $matches['VariableName'] ;
        $purpose = ($matches['Purpose'],'' -ne $null)[0] ;

        $previouscontents = ($varlist[$varname],'' -ne $null)[0]

        $varlist[$varname]=$previouscontents+$purpose;
        }
  
}

End {
$varlist 

}

}

<#
.Synopsis
   Check if variables exist
.DESCRIPTION
   Check if the variables obtained by Get-QuickTemplateVariableList do exist
.EXAMPLE
   Get-Content 'C:\temp\file.txt' | Get-QuickTemplateVariableList |  Test-QuickTemplateVariableList
.INPUTS
  Pipeline is text of the template
#>
Function Test-QuickTemplateVariableList {

param(
[Parameter(Mandatory=$true,ValueFromPipeLine=$true)]
[hashtable]$Varlist)

Process {
$Varlist.Keys | ForEach-Object {  
     
     [PSCustomObject] @{Variable = $_; Purpose=$varlist[$_]; Exists =  (Get-Variable $_ -EA SilentlyContinue) -ne $null }
    }
}

}

<#
.Synopsis
   Expands the template
.DESCRIPTION
   Replace the variable placeholders by their contents
.EXAMPLE
   Get-Content 'C:\temp\file.txt' | Expand-QuickTemplate
.INPUTS
  Pipeline is text of the template
#>

Function Expand-QuickTemplate {

Begin  {

}

Process {
 [RegEx]::replace($_,'!!(?<VariableName>[\w\d]+)(:(?<Purpose>.+?))?!!',{param($Match) $v=$Match.Groups['VariableName'].Value; if (Test-Path Variable:$($v)) { Get-Variable $v -ValueOnly } else { Write-Verbose "$v doesn't exist but is used"; "!!$v!!" } } ) 

  
}

End {


}

}