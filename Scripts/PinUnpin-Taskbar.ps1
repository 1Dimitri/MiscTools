# http://stackoverflow.com/questions/9739772/how-to-pin-to-taskbar-using-powershell#9739830
#does not work in Windows 10 / Server 2016

# The order results in a left to right ordering
# $PinnedItems = @(
    'C:\Program Files\Microsoft\Web Platform Installer\WebPlatformInstaller.exe'
    'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
)

# Removing each item and adding it again results in an idempotent ordering
# of the items. If order doesn't matter, there is no need to uninstall the
# item first.
#foreach($Item in $PinnedItems) {
#    Uninstall-TaskBarPinnedItem -Item $Item
#    Install-TaskBarPinnedItem   -Item $Item
#}


function Get-ComFolderItem() {
    [CMDLetBinding()]
    param(
        [Parameter(Mandatory=$true)] $Path
    )

    $ShellApp = New-Object -ComObject 'Shell.Application'

    $Item = Get-Item $Path -ErrorAction Stop

    if ($Item -is [System.IO.FileInfo]) {
        $ComFolderItem = $ShellApp.Namespace($Item.Directory.FullName).ParseName($Item.Name)
    } elseif ($Item -is [System.IO.DirectoryInfo]) {
        $ComFolderItem = $ShellApp.Namespace($Item.Parent.FullName).ParseName($Item.Name)
    } else {
        throw "Path is not a file nor a directory"
    }

    return $ComFolderItem
}

function Install-TaskBarPinnedItem() {
    [CMDLetBinding()]
    param(
        [Parameter(Mandatory=$true)] [System.IO.FileInfo] $Item
    )

    $Pinned = Get-ComFolderItem -Path $Item

    $Pinned.invokeverb('taskbarpin')
}

function Uninstall-TaskBarPinnedItem() {
    [CMDLetBinding()]
    param(
        [Parameter(Mandatory=$true)] [System.IO.FileInfo] $Item
    )

    $Pinned = Get-ComFolderItem -Path $Item

    $Pinned.invokeverb('taskbarunpin')
}