#creates the array to store the server objects
$ServerArray = @()

foreach ($L in get-adcomputer -filter * -searchbase "OU=Computers,DC=Domain,DC=com" -properties * | select CN,DNSHostName,CanonicalName,OperatingSystem,OperatingSystemServicePack,IPv4Address) 
            {
           $SVRObject = $null
           $SVRObject = New-Object system.Object
           $SVRObject | Add-Member -type NoteProperty -Name "CN" -Value $L.CanonicalName
           $SVRObject | Add-Member -type NoteProperty -Name "FQDN" -Value $L.DNSHostName
           $SVRObject | Add-Member -type NoteProperty -Name "Server" -Value $L.CN
           $SVRObject | Add-Member -type NoteProperty -Name "OS" -Value ($L.OperatingSystem +' '+$L.OperatingSystemServicePack)
           $SVRObject | Add-Member -type NoteProperty -Name "IP" -Value $L.IPv4Address
           #sets the error checking variable
           $error1 = 0
           try{
           #opens registry on remote server, using "try" so that errors are caught
           $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $SVRObject.FQDN)
           #checks for DNS server service key
           $DNS = $Reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Services\\DNS")
           #checks for WINS server service key
           $WINS = $Reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Services\\WINS")
           #checks for DHCP server service key
           $DHCP = $Reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Services\\DHCPServer")}
           ## Error catching and exception management
             catch [System.Management.Automation.MethodInvocationException]
             {
             write-host "Exception Server: $SVRObject.FQDN" -ForegroundColor Red
             write-host “Exception Type: $($_.Exception.GetType().FullName)” -ForegroundColor Red
             write-host “Exception Message: $($_.Exception.Message)” -ForegroundColor Red
             $errtype = $($_.Exception.GetType().FullName)
             $errmess = $($_.Exception.Message)
             $error1 = 1
             }
             catch [Management.Automation.RuntimeException]
             {
             write-host "Exception Server: $SVRObject.FQDN" -ForegroundColor Red
             write-host “Exception Type: $($_.Exception.GetType().FullName)” -ForegroundColor Red
             write-host “Exception Message: $($_.Exception.Message)” -ForegroundColor Red
             $errmess = $($_.Exception.Message)
             $error1 = 1
             }
           ## Sets value to yes/no for DNS Server Services         
           If (!$DNS) {$SVRObject | Add-Member -type NoteProperty -Name "DNS" -Value "No"} Else {$SVRObject | Add-Member -type NoteProperty -Name "DNS" -Value "Yes"}
           ## Sets value to yes/no for WINS Server Services
           If (!$WINS) {$SVRObject | Add-Member -type NoteProperty -Name "WINS" -Value  "No"} Else {$SVRObject | Add-Member -type NoteProperty -Name "WINS" -Value "Yes"}
           ## Sets value to yes/no for DHCP Server Services
           If (!$DHCP) {$SVRObject | Add-Member -type NoteProperty -Name "DHCP" -Value "No"} Else {$SVRObject | Add-Member -type NoteProperty -Name "DHCP" -Value "Yes"}
           ## Checks for Certificate Services Registry Key, if found provides the name of the Certificate Provider
           $CertSvc = $Reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Services\\CertSvc\\Configuration")
           If (!$CertSvc) {$SVRObject | Add-Member -type NoteProperty -Name "CertSvc" -Value "No"} Else {$CertSvc = ([string]$CertSvc.GetValue("Active"));$SVRObject | Add-Member -type NoteProperty -Name "CertSvc" -Value $CertSvc}
           ## Checks for the three character designation for Active Directory Site
           $ADsite = $Reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Services\\netlogon\\Parameters")
           $ADsite = ([string]$ADsite.GetValue("DynamicSiteName") -replace '(.{4}).+','$1')
           $SVRObject | Add-Member -type NoteProperty -Name "ADsite" -Value $ADsite
           ## Error Handling messaging
           If ($error1 -eq 1) {$SVRObject | Add-Member -type NoteProperty -Name "ErrorMessage" -Value $errmess} Else {$SVRObject | Add-Member -type NoteProperty -Name "ErrorMessage" -Value "No"}
           $ServerArray +=  $SVRObject
          }
           
# you can change the where statement to meet any identification requirements
# if you want to perform an action, then change the 'select' statement to some other cmdlet
foreach($server in $ServerArray){$server | where {$_.DNS -like "*"} | select *}  #| export-csv d:\w\server_discovery.csv -NoTypeInformation
