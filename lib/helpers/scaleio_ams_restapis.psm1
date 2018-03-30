#This gets MDM cluster info
Function MDM_Cluster_Stats {
    [CmdletBinding()]
    param(
        $gateway,
        $ScaleIOAuthHeaders
    )
    Process { 
        $param1 = @'
        {
            "properties":["id", "name", "clusterMode", "master", "slaves", "tieBreakers", "standbyMDMs", "clusterState", "virtualIps"]

        }
'@
        $MDM_cluster_stats = (Invoke-RestMethod -Uri "https://$($gateway):443/api/instances/System/queryMdmCluster " -Body $param1 -ContentType "application/json" -Headers $ScaleIOAuthHeaders -Method Post)
      
        $mdm_props =[ordered] @{

        'Cluster name'      = ($MDM_cluster_stats).name
        'Mode'              = ($MDM_cluster_stats).clusterMode
        'Cluster state'     = ($MDM_cluster_stats).clusterState
        'Master MDM IP'     = ($MDM_cluster_stats.master).managementIPs[0]
        'Cluster VIP01'     = ($MDM_cluster_stats).virtualIps[0]
        'Cluster VIP02'     = ($MDM_cluster_stats).virtualIps[1]
        }
        Return $mdm_props ;
    }
}

#This gets System overall capacity and objects
Function System_Capacity_Objects {
    [CmdletBinding()]
    param(
        $gateway,
        $ScaleIOAuthHeaders
    )
    Process {
        $param2 = @'
        {
            "properties":["maxCapacityInKb", "capacityInUseInKb", "spareCapacityInKb", "failedCapacityInKb", "degradedFailedCapacityInKb", "numOfSds", "numOfSdc", "numOfProtectionDomains", "numOfStoragePools", "numOfVolumes","numOfFaultSets", "numOfSnapshots" ]

        }
'@
        $system_overall_stats = (Invoke-RestMethod -uri "https://$($gateway):443/api/types/System/instances/action/querySelectedStatistics " -Body $param2 -ContentType "application/json" -Headers $ScaleIOAuthHeaders -Method Post)
            
        $system_capacity_objects = [ordered]@{

            "System max capacity (TB)" = (($system_overall_stats.maxCapacityInKb)/1024/1024/1024)
            "System capacity in use (TB)" = (($system_overall_stats.capacityInUseInKb)/1024/1024/1024)
            "System spare capacity (TB)" = (($system_overall_stats.spareCapacityInKb)/1024/1024/1024)
            "System failed capacity (TB)" = (($system_overall_stats.failedCapacityInKb)/1024/1024/1024)
            "System degraded failed capacity (TB)" = (($system_overall_stats.degradedFailedCapacityInKb)/1024/1024/1024)

            "Protection Domains" = $system_overall_stats.numOfProtectionDomains
            "Storage Pools" = $system_overall_stats.numOfStoragePools
            "Volumes" = $system_overall_stats.numOfVolumes
            "Fault Sets" = $system_overall_stats.numOfFaultSets
            "Snapshots" = $system_overall_stats.numOfSnapshots
            "SDSs" = $system_overall_stats.numOfSds
            "SDCs" = $system_overall_stats.numOfSdc

        }
        Return $system_capacity_objects;
    }
}

#This gets all system alerts
Function System_Alerts {
    [CmdletBinding()]
    param(
        $gateway,
        $ScaleIOAuthHeaders
    )
    Process { 
        $all_alerts = (Invoke-RestMethod -Uri "https://$($gateway):443/api/types/Alert/instances/" -Method Get -Headers $ScaleIOAuthHeaders) | select severity, alertType, startTime, lastObserved | sort severity
        Return $all_alerts;
    }
}

#This gets all disk health info in the cluster
Function Disk_Health {
    [CmdletBinding()]
    param(
        $gateway,
        $ScaleIOAuthHeaders
    )
    Process { 
        $all_disk_health = (Invoke-RestMethod -Uri "https://$($gateway):443/api/types/Device/instances " -Method Get -Headers $ScaleIOAuthHeaders) | select sdsId, storagePoolId, name, deviceCurrentPathName, errorState, deviceState, ssdEndOfLifeState, temperatureState, aggregatedState  | sort sdsId 
        Return $all_disk_health;
    }
}
