#1
#get credentials
## install iTunes

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

$installFile = "c:\remotedeploy\iTunes64Setup.exe"
$version     = "12.9.1.4"
$parameters  = "/qn /norestart"
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
        if ($cred -eq 'pdq')
        {
            Write-Output "deployment from PDQ"
            Copy-Item -Path "\\ConfigMgrDistro\Software\Applications\Specialty\iTunes\$version\$($installFile.Split('\')[-1])" -Destination $installFile -Force
        }
        else
        {
            New-PSDrive -name "Z" -PSProvider FileSystem -Root "\\ConfigMgrDistro\Software\Applications\Specialty\iTunes\$version" -Persist -Credential $cred | Out-Null
            Start-Sleep 1
            if (!(Test-Path Z:\)) {Write-Output $copyErr, "Credential error! Please check `nusername/password and try again" ; return}
            Copy-Item -Path "Z:\$($installFile.Split('\')[-1])" -Destination $installFile -Force
            Remove-PSDrive -Name "Z" | Out-Null
        }
    }
    catch {Write-Output $copyErr, $_; return}
}

# Stop iTunes
get-process itunes -ea silentlycontinue | stop-process
get-process ituneshelper -ea silentlycontinue | stop-process
get-process quicktimeplayer -ea silentlycontinue | stop-process

# Install
Write-Output $installing
Start-Sleep 1
Try
{
    Start-Process $installFile -ArgumentList $parameters -Wait
}
Catch {Write-Output $msiErr, $_; return}

Write-Output $completed

# # Verify
# Write-Output $verifying
# start-sleep 3
# if ((Test-Path 'HKLM:\SOFTWARE\VideoLAN\VLC') -and ((Get-Item 'C:\Program Files\VideoLAN\VLC\vlc.exe').VersionInfo.FileVersion -eq $version))
# {
#     Write-Output $completed
#     Remove-Item "C:\RemoteDeploy" -Recurse
#     # return 0
# }
# else {Write-Output $verErr; return}