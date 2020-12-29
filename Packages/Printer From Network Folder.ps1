#1
#networkshare  \\print  Please select a printer

$returnCodes = $args[9]
Invoke-Expression $returnCodes

$printer = $args[0]
$printerPath = "\\print\$printer"

status connected

function Test-PrintUIPrinter
{
    param
    (
        [parameter(Mandatory=$true)]
        [string]$PrinterName
    )

    $path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Connections'
    if (!(Test-Path $path)) { throw "Print UI registry path not found" }
    foreach ($printer in (Get-ChildItem $path))
    {
        if (($printer | Get-ItemProperty).printer -like $PrinterName) { return $true }
    }
    return $false
}

start-sleep 1
status "Checking installed printers"
Start-Sleep 1
if (Test-PrintUIPrinter -PrinterName $printerPath) { customMessage "'$printer' was already installed" }
else
{
    status installing
    Start-Sleep 1
    printui.exe /ga /n "$printerPath"
    status verifying
    Start-Sleep 5
    if (Test-PrintUIPrinter -PrinterName $printerPath) { customMessage "Successfully installed '$printer'. User will need to re-login to apply changes" }
    else { error verErr "installation could not be verified" }
}