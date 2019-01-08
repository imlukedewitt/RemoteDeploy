#\\ConfigMgrDistro.mssu.edu\Software\Applications\CampusWide\Google Earth\7.3.2.5495\8ff707e.msi
# ^^^ Installer path

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

$program           = "Google Earth"
$installFile       = "c:\remotedeploy\8ff707e.msi"
$version           = "7.3.2"
$parameters  = "/I $installFile /quiet /norestart"
$parameters  = $parameters.Split(' ')
$tempFolderPresent = $true

function Is-Installed()
{
    $x86 = ((Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall") |
        Where-Object { $_.GetValue( "DisplayName" ) -like "*$program*" -and $_.GetValue( "DisplayVersion" ) -like "*$version*"} ).Length -gt 0;
    $x64 = ((Get-ChildItem "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall") |
        Where-Object { $_.GetValue( "DisplayName" ) -like "*$program*" -and $_.GetValue( "DisplayVersion" ) -like "*$version*" } ).Length -gt 0;
    return $x86 -or $x64;
}

Write-Output $connected
Start-Sleep 1

if (Is-Installed) {Write-Output $customMsg, "$program $version is already installed"; return 0}

Write-Output $copying
Start-Sleep 1
$cred = $args[0]
.{
    try
    {
        # using Out-Null on folder operations to avoid sending unwanted returns to remote-deploy
        if (Test-Path $installFile) {return} # Exit the dotted code block
        if (!(Test-Path "C:\RemoteDeploy")) {New-Item -ItemType Directory -Path "C:\RemoteDeploy" | Out-Null; $tempFolderPresent = $false}
        New-PSDrive -name "Z" -PSProvider FileSystem -Root "\\ConfigMgrDistro.mssu.edu\Software\Applications\CampusWide\Google Earth\7.3.2.5495" -Persist -Credential $cred | Out-Null
        Start-Sleep 1
        if (!(Test-Path Z:\)) {Write-Output $copyErr, "Credential error! Please check `nusername/password and try again" ; return}
        Copy-Item -Path "Z:\$($installFile.Split('\')[-1])" -Destination $installFile -Force
        Remove-PSDrive -Name "Z" | Out-Null
    }
    catch { Write-Output $copyErr, $_; return 1}
}


Write-Output $installing
Start-Sleep 1
try { Start-Process "msiexec.exe" -ArgumentList $parameters -Wait }
catch { Write-Output $installErr, $_; return 1}


Write-Output $verifying
Start-Sleep 1
if (Is-Installed) {Write-Output $completed}
else {Write-Output $verErr; return 1}

if (!($tempFolderPresent)) { Remove-Item "C:\Remotedeploy" -Recurse }
return 0