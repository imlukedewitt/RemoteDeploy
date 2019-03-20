#1
#Enter a URL to send:

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

$webCommand = "Start-Process $($args[0])"
$taskname = "OpenWebLink"
$taskdescription = "Open default browser to specified URL"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $webCommand
$trigger = New-ScheduledTaskTrigger -Once -At 1am
$currentUser = ((Get-WMIObject -class Win32_ComputerSystem -ErrorAction Stop).username).substring(9)
$principal = New-ScheduledTaskPrincipal -UserId $currentUser
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskname -Description $taskdescription -Principal $principal | Out-Null
Start-ScheduledTask -TaskName $taskname
Unregister-ScheduledTask -TaskName $taskname -Confirm:$false

Write-Output $completed