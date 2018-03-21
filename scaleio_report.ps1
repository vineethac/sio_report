#to fix the connection issues to rest api
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11

#authentication step with AMS server and token generation
$User = Read-Host -Prompt "Please Enter ScaleIO MDM username"
$SecurePassword = Read-Host -Prompt "Enter ScaleIO Password for user $user" -AsSecureString
$Credentials = New-Object System.Management.Automation.PSCredential ($user,$Securepassword)
$Token = Invoke-RestMethod -Uri "https://100.98.22.59:443/api/login" -Method Get -Credential $Credentials
$token

#creating header
$auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(':'+$Token))
$global:ScaleIOAuthHeaders = @{'Authorization' = "Basic $auth" 
'Content-Type' = "application/json" }

#system overall capacity info collection
$param1 = @'
{
    "properties":["maxCapacityInKb", "capacityInUseInKb", "spareCapacityInKb", "failedCapacityInKb", "degradedFailedCapacityInKb", "numOfSds", "numOfSdc", "numOfProtectionDomains", "numOfStoragePools", "numOfVolumes","numOfFaultSets", "numOfSnapshots" ]

}
'@
$system_overall_stats = (Invoke-RestMethod -uri "https://100.98.22.59:443/api/types/System/instances/action/querySelectedStatistics " -Body $param1 -ContentType "application/json" -Headers $ScaleIOAuthHeaders -Method Post)

#MDM cluster info collection
$param2 = @'
{
    "properties":["id", "name", "clusterMode", "master", "slaves", "tieBreakers", "standbyMDMs", "clusterState", "virtualIps"]

}
'@
$MDM_cluster_stats = (Invoke-RestMethod -Uri "https://100.98.22.59:443/api/instances/System/queryMdmCluster " -Body $param2 -ContentType "application/json" -Headers $ScaleIOAuthHeaders -Method Post)

#####queries#####
#query all protection domains in system
$query_all_PDs = (Invoke-RestMethod -Uri "https://100.98.22.59:443/api/types/ProtectionDomain/instances " -Method Get -Headers $ScaleIOAuthHeaders)

#query PD object
#$PD_stat = (Invoke-RestMethod -Uri "https://100.98.22.59:443/api/instances/ProtectionDomain::3ce4af5f00000000 " -Method Get -Headers $ScaleIOAuthHeaders)

#query all storage pools in a PD
#$storagepools_in_PD = (invoke-RestMethod -Uri "https://100.98.22.59:443/api/instances/ProtectionDomain::3ce4af5f00000000/relationships/StoragePool " -Method Get -Headers $ScaleIOAuthHeaders)

#query selected Storage Pool statistics

#query all volumes in a storage pool
#$volumes_in_SP = (invoke-RestMethod -Uri "https://100.98.22.59:443/api/instances/StoragePool::5cc7c4f600000001/relationships/Volume " -Method Get -Headers $ScaleIOAuthHeaders)

#query specified volume
#$query_volume = (invoke-RestMethod -Uri "https://100.98.22.59:443/api/instances/Volume::e04a78cb00000001 " -Method Get -Headers $ScaleIOAuthHeaders)

#query selected Volume Statistics 
#$volume_stat = (Invoke-RestMethod -Uri "https://100.98.22.59:443/api/types/Volume/instances/action/querySelectedStatistics " -Body $param** -Method Post -Headers $ScaleIOAuthHeaders)
$query_all_volumes = (Invoke-RestMethod -Uri "https://100.98.22.59:443/api/types/Volume/instances " -Method Get -Headers $ScaleIOAuthHeaders)

[String[]]$PD_names = @()
[String[]]$SP_names = @()
[String[]]$Volume_names = @()
[String[]]$Relation = @()
$h =@{}
$h1 =@{}

for ($i=0; $i -lt $query_all_PDs.Count; $i++){
    
    
    $PD_names += $query_all_PDs[$i].name
    Write-Output ($query_all_PDs[$i].name)
    Write-Output "====="
    $q1 = "https://100.98.22.59:443/api/instances/ProtectionDomain::$($query_all_PDs[$i].id)/relationships/StoragePool "
    #Write-Output $q1
    New-Variable -Name "total_SP_in00_PD$i" -Value (invoke-RestMethod -Uri "$q1" -Method Get -Headers $ScaleIOAuthHeaders)
    #Get-Variable -Name $total_SP_in_PD$i = invoke-RestMethod -Uri "$q1" -Method Get -Headers $ScaleIOAuthHeaders
         
    $temp1 = Get-Variable -Name "total_SP_in00_PD$i" -ValueOnly
    #Write-Output $temp1.Name
    
    for ($j=0; $j -lt $temp1.Count; $j++){

        $SP_names += $temp1[$j].Name
        Write-Host "SP-->"$temp1[$j].Name
        $q2 = "https://100.98.22.59:443/api/instances/StoragePool::$($temp1[$j].id)/relationships/Volume " 
        New-Variable -Name "total_vol_in00_SP$j" -Value (Invoke-RestMethod -Uri "$q2" -Method Get -Headers $ScaleIOAuthHeaders)
        
        $temp2 = Get-Variable -Name "total_vol_in00_SP$j" -ValueOnly
        
        for ($k=0; $k -lt $temp2.Count; $k++){
            
            $Volume_names += $temp2[$k].Name
            Write-Host "   Vol---->"$temp2[$k].Name

            $h."Volume: $($temp2[$k].Name)" = "SP: $($temp1[$j].Name)"
            $h1."SP: $($temp1[$j].Name)" = "PD: $($query_all_PDs[$i].name)"
        }
        
        
        
        Write-Output "-----"
        Remove-Variable -Name "total_vol_in00_SP$j"
    }
    Remove-Variable -Name "total_SP_in00_PD$i"
    
}

$t = $h.GetEnumerator() | sort -Property Value | % {$_.Key}

for ($p=0; $p -lt $t.Count; $p++){

    #write-host $t[$p] "->" $h."$($t[$p])" "->" $h1."$($h."$($t[$p])")"
    #$a = $t[$p]
    #$b = $h."$($t[$p])"
    #$c = $h1."$($h."$($t[$p])")"
     
    
    $Relation += "$($t[$p]) > $($h."$($t[$p])") > $($h1."$($h."$($t[$p])")")"
}

Write-Output $Relation


$all_alerts = (Invoke-RestMethod -Uri "https://100.98.22.59:443/api/types/Alert/instances/" -Method Get -Headers $ScaleIOAuthHeaders) | select severity, alertType, startTime, lastObserved | sort severity
$all_sdc = (Invoke-RestMethod -Uri "https://100.98.22.59:443/api/types/Sdc/instances " -Method Get -Headers $ScaleIOAuthHeaders)
$all_SPs = (Invoke-RestMethod -Uri "https://100.98.22.59:443/api/types/StoragePool/instances " -Method Get -Headers $ScaleIOAuthHeaders)
$all_sds = (Invoke-RestMethod -Uri "https://100.98.22.59:443/api/types/Sds/instances " -Method Get -Headers $ScaleIOAuthHeaders)
$all_devices = (Invoke-RestMethod -Uri "https://100.98.22.59:443/api/types/Device/instances " -Method Get -Headers $ScaleIOAuthHeaders) | select sdsId, storagePoolId, name, deviceCurrentPathName, errorState, deviceState, ssdEndOfLifeState, temperatureState, aggregatedState  | sort sdsId | ft -AutoSize
$all_devices1 = (Invoke-RestMethod -Uri "https://100.98.22.59:443/api/types/Device/instances "  -Method Get -Headers $ScaleIOAuthHeaders)
#$SP_stats = $all_SPs.id | ForEach-Object { (Invoke-RestMethod -Uri "https://100.98.22.59:443/api/instancesStoragePool::$_/relationships/Statistics " -Method Get -Headers $ScaleIOAuthHeaders) }

#####final report contents section#####

#MDM cluster details
$mdm_props =[ordered] @{

    'Cluster name'      = ($MDM_cluster_stats).name
    'Mode'              = ($MDM_cluster_stats).clusterMode
    'Cluster state'     = ($MDM_cluster_stats).clusterState
    'Master MDM IP'     = ($MDM_cluster_stats.master).managementIPs[0]
    'Cluster VIP01'     = ($MDM_cluster_stats).virtualIps[0]
    'Cluster VIP02'     = ($MDM_cluster_stats).virtualIps[1]
}

#system overall capacity details
$system_capacity_props = [ordered]@{

    "System max capacity (TB)" = (($system_overall_stats.maxCapacityInKb)/1024/1024/1024)
    "System capacity in use (TB)" = (($system_overall_stats.capacityInUseInKb)/1024/1024/1024)
    "System spare capacity (TB)" = (($system_overall_stats.spareCapacityInKb)/1024/1024/1024)
    "System failed capacity (TB)" = (($system_overall_stats.failedCapacityInKb)/1024/1024/1024)
    "System degraded failed capacity (TB)" = (($system_overall_stats.degradedFailedCapacityInKb)/1024/1024/1024)
}

#PD, SDS, SDC, storage pools, volumes, fault sets and snapshots details in a system
$sio_components_props = [ordered]@{

    "PDs" = $system_overall_stats.numOfProtectionDomains
    "Storage Pools" = $system_overall_stats.numOfStoragePools
    "Volumes" = $system_overall_stats.numOfVolumes
    "Fault Sets" = $system_overall_stats.numOfFaultSets
    "Snapshots" = $system_overall_stats.numOfSnapshots
    "SDSs" = $system_overall_stats.numOfSds
    "SDCs" = $system_overall_stats.numOfSdc
}

$hierarchy = [ordered]@{}
for ($x=1; $x -le $system_overall_stats.numOfVolumes; $x++) {

    $hierarchy."$x" = "$($Relation[$x-1])"
}

Write-Output $hierarchy

$mdm_obj = New-Object -TypeName psobject -Property $mdm_props
$frag1 = $mdm_obj | ConvertTo-Html -As List -Fragment -PreContent '<h2>MDM cluster</h2>' | Out-String

$system_capacity_obj = New-Object -TypeName psobject -Property $system_capacity_props
$frag2 = $system_capacity_obj | ConvertTo-Html -As List -Fragment -PreContent '<h2>System overall capacity</h2>' | Out-String

$total_num_obj = New-Object -TypeName psobject -Property $sio_components_props
$frag3 = $total_num_obj | ConvertTo-Html -As List -Fragment -PreContent '<h2>System objects</h2>' | Out-String

$storage_hierarchy = New-Object -TypeName psobject -Property $hierarchy
#$frag4 = $Relation | ForEach{[PSCustomObject]@{'My Column Name'=$_}} | ConvertTo-Html -As List -Fragment -PreContent '<h2>Hierarchy [Volume > SP > PD]</h2>' | Out-String
$frag4 = $storage_hierarchy | ConvertTo-Html -As List -Fragment -PreContent '<h2>Hierarchy [Volume > SP > PD]</h2>' | Out-String

#$alerts = New-Object -TypeName psobject -Property $all_alerts
$frag5 = $all_alerts | ConvertTo-Html -Fragment -PreContent '<h2>Alerts</h2>' | Out-String

# html region
$head = @"
<style>
body { background-color:#bdddcc;
font-family:Tahoma;
font-size:12pt; }

td, th { border:1px solid black;
border-collapse:collapse; }

th { color:white;
background-color:black; }

table, tr, td, th { padding: 2px; margin: 0px }
table { margin-left:50px; }
</style>
"@

Write-Output $all_devices
ConvertTo-HTML -head $head -PostContent $frag1, $frag2, $frag3, $frag4, $frag5 -PreContent “<h1>ScaleIO_cluster_Report</h1>” | out-file D:\sioreport.html

#Write-Output $PD_names, $SP_names, $Volume_names

#Write-Output $h
#Write-Output $h1