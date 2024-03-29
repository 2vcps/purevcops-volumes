cls
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
$FlashArrayName = @('pure1','pure2','pure3','pure4')

$AuthAction = @{
    password = "pass"
    username = "user"
}




# will ignore SSL or TLS warnings when connecting to the site
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$pass = cat C:\temp\cred.txt | ConvertTo-SecureString
$mycred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist "admin",$pass

# function to perform the HTTP Post web request
function post-vcops ($custval,$custval2,$custval3,$custval4)
{
# url for the vCOps UI VM. Should be the IP, NETBIOS name or FQDN
$url = "<vcops ip or name>"
#write-host "Enter in the admin account for vCenter Operations"

# prompts for admin credentials for vCOps. If running as scheduled task replace with static credentials
$cred = $mycred

# sets resource name
$resname = $custval

# sets adapter kind
$adaptkind = "Http Post"
$reskind = "Flash Volumes"

# sets resource description
$resdesc = $custval4

# sets the metric name
$metname = $custval2

# sets the alarm level
$alrmlev = "0"

# sets the alarm message
$alrmmsg = "alarm message"

# sets the time in epoch and in milliseconds
#This is setting us 7 hours behind
$epoch = [decimal]::Round((New-TimeSpan -Start (get-date -date "01/01/1970") -End (get-date)).TotalMilliseconds)

# takes the above values and combines them to set the body for the Http Post request
# these are comma separated and because they are positional, extra commas exist as place holders for
# parameters we didn't specify
$body = "$resname,$adaptkind,$reskind,,$resdesc`n$metname,$alrmlev,$alrmmsg,$epoch,$custval3"

# executes the Http Post Request
Invoke-WebRequest -Uri "https://$url/HttpPostAdapter/OpenAPIServlet" -Credential $cred -Method Post -Body $body

write-host $custval,$custval2,$custval3
}


ForEach($element in $FlashArrayName)
{
$faName = $element.ToString()
$ApiToken = Invoke-RestMethod -Method Post -Uri "https://${faName}/api/1.1/auth/apitoken" -Body $AuthAction

$SessionAction = @{
    api_token = $ApiToken.api_token
}
Invoke-RestMethod -Method Post -Uri "https://${faName}/api/1.1/auth/session" -Body $SessionAction -SessionVariable Session
 
 $PureStats = Invoke-RestMethod -Method Get -Uri "https://${faName}/api/1.1/array?action=monitor" -WebSession $Session
 $PureVolStats = Invoke-RestMethod -Method Get -Uri "https://${faName}/api/1.1/volume?space=true" -WebSession $Session
ForEach($Volume in $PureVolStats) {
   #$Volume.data_reduction
   #$Volume.name
   #$Volume.volumes
   #$Volume.shared_space
   #$Volume.system
   #$Volume.total
   #$Volume.total_reduction
   #$Volume.snapshots
   $adjVolumeSize = ($Volume.Size /1024)/1024/1024
   #$Volume.thin_provisioning
   
    post-vcops($Volume.Name)("Volume Size")($adjVolumeSize)($faName)
    post-vcops($Volume.Name)("Volume Data Reduction")($Volume.data_reduction)($faName)
    post-vcops($Volume.Name)("Volumes")($Volume.volumes)($faName)
    post-vcops($Volume.Name)("Shared Space")($Volume.shared_space)($faName)
    post-vcops($Volume.Name)("System")($Volume.system)($faName)
    post-vcops($Volume.Name)("Total")($Volume.total)($faName)
    post-vcops($Volume.Name)("Total Reduction")($Volume.total_reduction)($faName)
    post-vcops($Volume.Name)("Thin Provisioning")($Volume.thin_provisioning)($faName)
    post-vcops($Volume.Name)("Snapshots")($Volume.snapshots)($faName)
 
    

}


 } 