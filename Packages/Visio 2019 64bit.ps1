#2
#msgbox  WARNING: This package will force-close any running Microsoft Office applications. If 32-bit Office products are installed, the deployment will fail.
#get credentials

## install Visio 2019

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

$application = 'Microsoft Visio 2019'
$installFile = "~Visio64 setup.bat"
$cred        = $args[1]

function cleanup
{
    Remove-PSDrive -Name "Z" | Out-Null
}

Write-Output $connected
Start-Sleep 1

Write-Output $customMsg, "Force closing Office apps", "continue"
Start-Sleep 1
get-process | Where-Object {$_.path -like "*microsoft office*"}  | stop-process -force

Write-Output $copying
start-sleep 1
try
{
    # using Out-Null on directory operations to avoid sending unwanted output to RemoteDeploy.ps1
    New-PSDrive -name "Z" -PSProvider FileSystem -Root "\\ConfigMgrDistro\Software\Applications\CampusWide\Office\2019" -Persist -Credential $cred | Out-Null
    Start-Sleep 1
    if (!(Test-Path Z:\)) {Write-Output $copyErr, "Credential error! Please check `nusername/password and try again" ; return}
}
catch {Write-Output $copyErr, $_; cleanup; return}

Write-Output $installing
Start-Sleep 1
Write-Output $customMsg, "Installing`nThis can take a while", "continue"
try {Start-Process -FilePath "Z:\$installFile" -Wait}
catch {Write-Output $installErr, $_; cleanup; return}

Write-Output $verifying
Start-Sleep 1
if (test-path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\VisioPro2019Volume - en-us") {Write-Output $completed; cleanup}
else {Write-Output $verErr; cleanup; return}

$messageToUser = {C:\windows\system32\msg.exe * "Message from IT:`n`n$application was successfully installed. Please restart your computer at your convenience."}
$messageToUser | Invoke-Expression