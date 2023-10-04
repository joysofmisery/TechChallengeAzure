#On the Windows VM to read data

$data = Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET -Proxy $Null -Uri "http://169.254.169.254/metadata/instance?api-version=2021-01-01"
$JSON = $data | ConvertTo-Json -Depth 64

#Linux
curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2020-09-01" | jq


# Bonus point answer

#Compute only,
Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET -Proxy $Null -Uri "http://169.254.169.254/metadata/instance/compute?api-version=2021-01-01" | ConvertTo-Json -Depth 64

# only single key
Write-Output "VM size - $($data.compute.vmSize)"
