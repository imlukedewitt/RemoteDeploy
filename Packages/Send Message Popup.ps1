#1
#Enter message to send to all users:

$returnCodes = $args[9]
Invoke-Expression $returnCodes

Status connected
Status "Sending popup"

msg.exe * $args[0]

status completed