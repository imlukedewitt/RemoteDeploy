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

Write-Output $customMsg, "Checking for VNC installation", "continue"
Start-Sleep 1
if(!(Test-Path "C:\Program Files\TightVNC\tvnserver.exe")) {write-output $custommsg, "VNC not found on target computer!"; return}

Write-output $custommsg, "Starting service...", "continue"
start-sleep 1
while (!(Get-Process tvnserver -ErrorAction SilentlyContinue))
{
    try   { net start tvnserver | Out-Null }
    catch { Write-Output $customMsg, "Error! Could not start service. Error message:`n`n$_"; return }
}
Write-Output $completed