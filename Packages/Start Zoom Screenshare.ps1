# Exit codes
$completed   =  0,"."
$connected   = -1,"."
$copying     = -2,"."
$installing  = -3,"."
$verifying   = -4,"."
$customMsg   = 1
$copyErr     = 2
$installErr  = 3
$verErr      = 4,"."

Write-Output $connected
Start-Sleep 1

if (!(test-path('C:\Program Files (x86)\Zoom\Bin\Zoom.exe')))
{
    write-output $customMsg, "Error: Zoom not found in the default install location."
    return
}

$taskname = "StartZoomSession"
$taskdescription = "Open Zoom with arguments"
$action = New-ScheduledTaskAction -Execute 'C:\Program Files (x86)\Zoom\Bin\Zoom.exe' -Argument '--url=https://zoom.us/j/3580345094'
$trigger = New-ScheduledTaskTrigger -Once -At 1am
$currentUser = ((Get-WMIObject -class Win32_ComputerSystem -ErrorAction Stop).username).substring(9)
$principal = New-ScheduledTaskPrincipal -UserId $currentUser
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskname -Description $taskdescription -Principal $principal | Out-Null
Start-ScheduledTask -TaskName $taskname
Unregister-ScheduledTask -TaskName $taskname -Confirm:$false


Start-Sleep 3
Write-Output $completed