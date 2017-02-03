Function Get-TemplateVarList {

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

Function Test-TemplateVarList {

param(

[hashtable]$Varlist)

Process {
$Varlist.Keys | ForEach-Object {  
     
     [PSCustomObject] @{Variable = $_; Exists =  (Get-Variable $_ -EA SilentlyContinue) -ne $null }
    }
}

}