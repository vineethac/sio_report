[CmdletBinding()]
param(
    $gateway,
    $ScaleIOAuthHeaders
)
Process { 
    #Disk health
    $all_disk_health = (Invoke-RestMethod -Uri "https://100.98.22.59:443/api/types/Device/instances " -Method Get -Headers $ScaleIOAuthHeaders) | select sdsId, storagePoolId, name, deviceCurrentPathName, errorState, deviceState, ssdEndOfLifeState, temperatureState, aggregatedState  | sort sdsId 
    Return $all_disk_health;
}
