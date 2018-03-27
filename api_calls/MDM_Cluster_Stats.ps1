[CmdletBinding()]
param(
    $gateway,
    $ScaleIOAuthHeaders
)
Process { 
    #MDM cluster info collection
    $param1 = @'
    {
            "properties":["id", "name", "clusterMode", "master", "slaves", "tieBreakers", "standbyMDMs", "clusterState", "virtualIps"]

    }
'@
    $MDM_cluster_stats = (Invoke-RestMethod -Uri "https://$($gateway):443/api/instances/System/queryMdmCluster " -Body $param1 -ContentType "application/json" -Headers $ScaleIOAuthHeaders -Method Post)
    #Write-Host "reached here!"

    #MDM cluster details
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
