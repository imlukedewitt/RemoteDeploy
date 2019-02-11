#1
#networkshare  \\print  Please select a printer

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

$printer = $args[1]
$printerPath = "\\print\$printer"

Write-Output $connected
Start-Sleep 1

Write-Output $installing
Start-Sleep 1
try
{   
    cmd.exe /c "RUNDLL32 PRINTUI.DLL, PrintUIEntry /ga /u /n`"$printerPath`"" 
    Write-Output $completed
}
catch
{
    Write-Output $installErr, $_
}

