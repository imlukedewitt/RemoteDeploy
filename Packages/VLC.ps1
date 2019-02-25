#1
#get credentials
## install VLC 3.0.6

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

$installFile = "c:\remotedeploy\vlc-3.0.6-win64.msi"
$version     = "3.0.6"
$parameters  = "/I $installFile /quiet /norestart"
$parameters  = $parameters.Split(' ')
$cred        = $args[0]

Write-Output $connected
Start-Sleep 1

Write-Output $copying
start-sleep 1
.{
    try
    {
        # using Out-Null on directory operations to avoid sending unwanted output to RemoteDeploy.ps1
        if (Test-Path $installFile) {return}
        
        if (!(Test-Path "C:\RemoteDeploy")) {New-Item -ItemType Directory -Path "C:\RemoteDeploy" | Out-Null}
        New-PSDrive -name "Z" -PSProvider FileSystem -Root "\\ConfigMgrDistro\Software\Applications\CampusWide\VLC\3.0.6" -Persist -Credential $cred | Out-Null
        Start-Sleep 1
        if (!(Test-Path Z:\)) {Write-Output $copyErr, "Credential error! Please check `nusername/password and try again" ; return}
        Copy-Item -Path "Z:\$($installFile.Split('\')[-1])" -Destination $installFile -Force
        Remove-PSDrive -Name "Z" | Out-Null
    }
    catch {Write-Output $copyErr, $_; return 1}
}


# Check for 32-bit version. MSI will overwrite old 64 bit versions but not uninstall 32
if (Test-Path 'C:\Program Files (x86)\VideoLAN\VLC\uninstall.exe')
{
    try
    {
        Write-Output $customMsg, "Uninstalling 32-bit version", 'continue'
        Start-Process "C:\Program Files (x86)\VideoLAN\VLC\uninstall.exe" -ArgumentList '/S' -Wait
    }
    catch {Write-Output $customMsg, "Could not uninstall 32-bit version. Error message:`n$_"; return}
}

# Install
Write-Output $installing
Try
{
    Start-Process "msiexec.exe" -ArgumentList $parameters -Wait
}
Catch {Write-Output $msiErr, $_; return}

# Verify
Write-Output $verifying
start-sleep 3
if ((Test-Path 'HKLM:\SOFTWARE\VideoLAN\VLC') -and ((Get-Item 'C:\Program Files\VideoLAN\VLC\vlc.exe').VersionInfo.FileVersion -eq $version))
{
    Write-Output $completed
    Remove-Item "C:\RemoteDeploy" -Recurse
}
else {Write-Output $verErr; return}