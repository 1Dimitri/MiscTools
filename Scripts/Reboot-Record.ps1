param(
[string]$TimeCreated,
[string]$ShutdownOK,
[string]$BootOK
)
   "TIME: $TimeCreated" | Add-Content 'C:\test\test.log' 
   "S_OK: $ShutdownOK"  | Add-Content 'C:\test\test.log' 
   "B_OK: $BootOK"  | Add-Content 'C:\test\test.log' 
  
