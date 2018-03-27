[CmdletBinding()]
param(
    $gateway,
    $ScaleIOAuthHeaders
)
Process {
    #system overall capacity info collection
    [hashtable]$return = @{}
    $param2 = @'
    {
        "properties":["maxCapacityInKb", "capacityInUseInKb", "spareCapacityInKb", "failedCapacityInKb", "degradedFailedCapacityInKb", "numOfSds", "numOfSdc", "numOfProtectionDomains", "numOfStoragePools", "numOfVolumes","numOfFaultSets", "numOfSnapshots" ]

    }
'@
    $system_overall_stats = (Invoke-RestMethod -uri "https://$($gateway):443/api/types/System/instances/action/querySelectedStatistics " -Body $param2 -ContentType "application/json" -Headers $ScaleIOAuthHeaders -Method Post)
    
    #system overall capacity details
    $system_capacity_objects = [ordered]@{

        "System max capacity (TB)" = (($system_overall_stats.maxCapacityInKb)/1024/1024/1024)
        "System capacity in use (TB)" = (($system_overall_stats.capacityInUseInKb)/1024/1024/1024)
        "System spare capacity (TB)" = (($system_overall_stats.spareCapacityInKb)/1024/1024/1024)
        "System failed capacity (TB)" = (($system_overall_stats.failedCapacityInKb)/1024/1024/1024)
        "System degraded failed capacity (TB)" = (($system_overall_stats.degradedFailedCapacityInKb)/1024/1024/1024)

        "PDs" = $system_overall_stats.numOfProtectionDomains
        "Storage Pools" = $system_overall_stats.numOfStoragePools
        "Volumes" = $system_overall_stats.numOfVolumes
        "Fault Sets" = $system_overall_stats.numOfFaultSets
        "Snapshots" = $system_overall_stats.numOfSnapshots
        "SDSs" = $system_overall_stats.numOfSds
        "SDCs" = $system_overall_stats.numOfSdc

    }
   
    #$return.capacity = $system_capacity_props
    #$return.objects = $sio_components_props
    
    #Return $return | Format-Table -AutoSize;
    Return $system_capacity_objects;
}
