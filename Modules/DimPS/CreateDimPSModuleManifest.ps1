$NestedModules = Get-ChildItem -Filter *.psm1
$psd1= Join-Path $PSScriptRoot 'DimPS.psd1'
$me = "1Dimitri"
$mver = "0.1"
$originalGUID ='f8ca7ae7-3ccf-4b90-8f04-7e8c0c5e2e4b'
$description =@"
Useful bits of Powershell collected over time from various sources
"@
New-ModuleManifest -Author $me -NestedModules $NestedModules -Copyright $me -ModuleVersion $mver -CompanyName $me -Path $psd1 -description $description -GUID $originalGUID