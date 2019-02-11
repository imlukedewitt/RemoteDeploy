#get credentials

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

$program           = "Firefox"
$installFile       = "c:\remotedeploy\Firefox Setup 64.0.exe"
$version           = "64.0"
$parameters        = "-ms"
$tempFolderPresent = $true

Write-Output $connected
Start-Sleep 1


if ( (Test-Path "C:\Program Files\Mozilla Firefox\firefox.exe") -and ((Get-Item "C:\Program Files\Mozilla Firefox\firefox.exe").VersionInfo.FileVersion -like "*$version*") )
{
    Write-Output $customMsg, "$program $version already installed"
    return 0
}


if ( Test-Path "C:\Program Files (x86)\Mozilla Firefox\firefox.exe" )
{
    Write-Output $customMsg, "Uninstalling 32bit version", "continue"
    Start-Sleep 1
    try { Start-Process "C:\Program Files (x86)\Mozilla Firefox\uninstall\helper.exe" -ArgumentList "/S" -Wait }
    catch { Write-Output $customMsg, "Could not uninstall 32bit version! Error message:`n$_"; return 1}
}


Write-Output $copying
$cred = $args[0]
.{ 
    try
    {
        # using Out-Null on folder operations to avoid sending unwanted returns to remote-deploy
        if (Test-Path $installFile) {return} # Exit the dotted code block
        if (!(Test-Path "C:\RemoteDeploy")) {New-Item -ItemType Directory -Path "C:\RemoteDeploy" | Out-Null; $tempFolderPresent = $false}
        New-PSDrive -name "Z" -PSProvider FileSystem -Root "\\ConfigMgrDistro.mssu.edu\Software\Applications\CampusWide\Firefox\64.0" -Persist -Credential $cred | Out-Null
        Start-Sleep 1
        if (!(Test-Path Z:\)) {Write-Output $copyErr, "Credential error! Please check `nusername/password and try again" ; return}
        Copy-Item -Path "Z:\$($installFile.Split('\')[-1])" -Destination $installFile -Force
        Remove-PSDrive -Name "Z" | Out-Null
    }
    catch { Write-Output $copyErr, $_; return 1}
}


Write-Output $installing
Start-Sleep 1
try { Start-Process $installFile -ArgumentList $parameters -Wait }
catch { Write-Output $installErr, $_; return 1}


Write-Output $verifying
Start-Sleep 1
$x86 = ((Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall") |
    Where-Object { $_.GetValue( "DisplayName" ) -like "*$program*" -and $_.GetValue( "DisplayVersion" ) -like "*$version*"} ).Length -gt 0;
$x64 = ((Get-ChildItem "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall") |
    Where-Object { $_.GetValue( "DisplayName" ) -like "*$program*" -and $_.GetValue( "DisplayVersion" ) -like "*$version*" } ).Length -gt 0;
if ($x86 -or $x64) { Write-Output $completed}
else { Write-Output $verErr; return 1 }

if (!($tempFolderPresent)) { Remove-Item "C:\Remotedeploy" -Recurse }
return 0