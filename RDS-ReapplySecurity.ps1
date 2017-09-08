## First Release 08 Sep 2017
## Warren Carrigan
## This script reapplies the User Groups to a Remote Desktop Session Collection in a Highly Available Connection Broker environment. 
## This is necessary when leveraging a great deal of group nesting, especially across AD forests, as Server Manager tends to fall apart on itself.
## This has only been tested when one security group is assigned to the Session Collection.  YMMV
Import-Module RemoteDesktop
## Declare connection brokers
$rdcb1 = "FQDN.connectionbroker1.com"
$rdcb2 = "FQDN.connectionbroker2.com"
## Ensuring that at least connection broker is reachable.
try {$rdcb = Get-RDConnectionBrokerHighAvailability -ConnectionBroker $rdcb1}
catch  {Write-Host "The first Connection Broker was unreachable"}
finally {$rdcb = Get-RDConnectionBrokerHighAvailability -ConnectionBroker $rdcb2}

## Gets known session collections
$rdsessioncollections = Get-RDSessionCollection -ConnectionBroker $rdcb.ActiveManagementServer
## Gets known hosts of session collections
$rdsessionhosts = $rdsessioncollections | ForEach-Object -Process {Get-RDSessionHost -ConnectionBroker $rdcb.ActiveManagementServer -CollectionName $_.CollectionName}
## Gets known user groups of session collections
$rdsgroups = $rdsessioncollections | ForEach-Object -Process {Get-RDSessionCollectionConfiguration -CollectionName $_.CollectionName -UserGroup -ConnectionBroker $rdsha.ActiveManagementServer}

## Display collected information
$rdsgroups | select CollectionName,@{Name="UserGroups";Expression={[string]$_.UserGroup}} | Format-Table -AutoSize
$rdsessionhosts | Format-Table -AutoSize

## Uncomment below to execute the process.
## $rdsgroups | ForEach-Object -Begin {}-Process {Set-RDSessionCollectionConfiguration -CollectionName $_.CollectionName -ConnectionBroker $rdsha.ActiveManagementServer -UserGroup ([string]$_.UserGroup)} -End {}
