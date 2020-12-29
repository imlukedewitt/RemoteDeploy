$returnCodes = $args[9]
Invoke-Expression $returnCodes

Status connected

$currentUser = $null
# Check if someone is logged in. Probably don't need this in a try/catch but you never know
try {$currentUser = (Get-WMIObject -class Win32_ComputerSystem -ErrorAction Stop).username }
catch {customMessage "Device is online`r`nUnable to check user/state status"; return}

if ($currentUser)
{
    try
    {
        # If the computer is locked, logonui.exe will be running
        Get-Process logonui -ErrorAction Stop | Out-Null
        customMessage "Device is online`r`nCurrent user : $currentUser`r`nDevice state : Locked"
        return
    }
    catch
    {
        customMessage "Device is online`r`nCurrent user : $currentUser`r`nDevice state : Unlocked"
        return
    }
}

customMessage "Device is online`r`nCurrent user : None`r`nDevice state : Locked"