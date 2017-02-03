Function Get-QuickTemplateVarList {

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

Function Test-QuickTemplateVariableList {

param(

[hashtable]$Varlist)

Process {
$Varlist.Keys | ForEach-Object {  
     
     [PSCustomObject] @{Variable = $_; Purpose=$varlist[$_]; Exists =  (Get-Variable $_ -EA SilentlyContinue) -ne $null }
    }
}

}

Function Expand-QuickTemplate {

Begin  {

}

Process {
 [RegEx]::replace($_,'!!(?<VariableName>[\w\d]+)(:(?<Purpose>.+?))?!!',{param($Match) $v=$Match.Groups['VariableName'].Value; if (Test-Path Variable:$($v)) { Get-Variable $v -ValueOnly } else { Write-Verbose "$v doesn't exist but is used"; "!!$v!!" } } ) 

  
}

End {


}

}