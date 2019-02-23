#1
#gimme some information

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
Write-Output $copying
Start-Sleep 1
Write-Output $installing
Start-Sleep 1
Write-Output $customMsg, "Tested connection successfully"