[CmdletBinding()]
param(
    $gateway,
    $ScaleIOAuthHeaders
)
Process { 
    #System alerts
    $all_alerts = (Invoke-RestMethod -Uri "https://$($gateway):443/api/types/Alert/instances/" -Method Get -Headers $ScaleIOAuthHeaders) | select severity, alertType, startTime, lastObserved | sort severity
    Return $all_alerts;
}