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

Start-Sleep 1
Write-Output $connected
Start-Sleep 1

$currentUser = $null
try {$currentUser = (Get-WMIObject -class Win32_ComputerSystem -ErrorAction Stop).username }
catch {Write-Output $customMsg, "Device is online`nUnable to check user/state status"; return}

if ($currentUser)
{
    try
    {
        Get-Process logonui -ErrorAction Stop | Out-Null
        # Write-Output $completed
        Write-Output $customMsg, "Device is online`nCurrent user : $currentUser`nDevice state : Locked"
        return
    }
    catch
    {
        Write-Output ($customMsg, "Device is online`nCurrent user : $currentUser`nDevice state : Unlocked")
        # Write-Output $completed
        return
    }
}
else
{
    Write-Output $customMsg, "Device is online`nCurrent user : None`nDevice state : Locked"
    return
}

Write-Output $customMsg, "Device is online`nUnable to check user/state status"