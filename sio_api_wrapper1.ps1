[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [String]$gateway
)

Begin {
    $LibFolder = "$PSScriptRoot\Lib"
    $LogFolder = "$PSScriptRoot\logs"
    $api_calls_folder = "$PSScriptRoot\api_calls"

    try{
        Import-Module $LibFolder\helpers\helpers.psm1 -Force  -ErrorAction Stop
        Show-Message -Message "[Region] Prerequisite - helpers loaded."
    }
    catch {
        Show-Message -Severity high -Message "[EndRegion] Failed - Prerequisite of loading modules"
        Write-VerboseLog -ErrorInfo $PSItem
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
    
    #region generate the transcript log
    #Modifying the VerbosePreference in the Function Scope
    $Start = Get-Date
    $VerbosePreference = 'Continue'
    $TranscriptName = '{0}_{1}.log' -f $(($MyInvocation.MyCommand.Name.split('.'))[0]),$(Get-Date -Format ddMMyyyyhhmmss)
    Start-Transcript -Path "$LogFolder\$TranscriptName"
    #endregion generate the transcript log

    #region log the current Script version in use
    Write-VerboseLog -Message "[Region] log the current script version in use"
    $ParseError = $null
    $Tokens = $null
    $null = [System.Management.Automation.Language.Parser]::ParseInput($($MyInvocation.MyCommand.ScriptContents),[ref]$Tokens,[ref]$ParseError)
    $VersionComment = $Tokens | Where-Object -filterScript { ($PSitem.Kind -eq "Comment") -and ($PSitem.Text -like '*version*')}
    # Put the version in the verbose messages for the log to cpature it.
    Write-VerboseLog -Message "Script -> $($MyInvocation.MyCommand.Name) ; Version -> $(($VersionComment -split ':')[1])"
    # Remove the variables used above
    Remove-Variable	-Name ParseError,Tokens,VersionComment
    Write-VerboseLog -Verbose -Message "[EndRegion] log the current script version in use"
    #endregion log the current script version in use
    
    #to fix the connection issues to scaleio rest api
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
    #collecting ams creds
    try {
        Show-Message -Message "Collecting ScaleIO Gateway Creds"
        $Credentials = Get-Credential -Message "Enter ScaleIO G/W Creds"
    }
    catch {
        Show-Message -Severity high -Message "[EndRegion] Failed collecting gateway creds. Exiting!"
        Write-VerboseLog -ErrorInfo $PSItem
        Stop-Transcript
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
    
    #token generation
    try { 
        Show-Message -Message "Prerequisite - creating token"
        Show-Message -Message "Connecting to ScaleIO Gateway: $gateway"
        $Token = Invoke-RestMethod -Uri "https://$($gateway):443/api/login" -Method Get -Credential $Credentials 
    }
    catch {
        Show-Message -Severity high -Message "Failed to create token. Quiting!"
        Write-VerboseLog -ErrorInfo $PSItem
        Stop-Transcript
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }

    #creating header
    try {
        $auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(':'+$Token))
        $global:ScaleIOAuthHeaders = @{'Authorization' = "Basic $auth" 
        'Content-Type' = "application/json" }
        }
    catch {
        Show-Message -Severity high -Message "Failed creating auth header. Quiting!"
        Write-VerboseLog -ErrorInfo $PSItem
        Stop-Transcript
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}

Process {
    #MDM cluster info
    try {
        Show-Message -Message "Collecting MDM cluster details"
        $mdm_props = .\\api_calls\MDM_Cluster_Stats.ps1 -gateway $gateway -ScaleIOAuthHeaders $ScaleIOAuthHeaders
    }
    catch {
        Show-Message -Severity high -Message "Failed getting MDM cluster details. Quiting!"
        Write-VerboseLog -ErrorInfo $PSItem
        Stop-Transcript
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }

    #System overall capacity and objects
    try {
        Show-Message -Message "Collecting overall system capacity and object details"
        $system_capacity_objects = .\\api_calls\System_Capacity_Objects.ps1 -gateway $gateway -ScaleIOAuthHeaders $ScaleIOAuthHeaders
    }
    catch {
        Show-Message -Severity high -Message "Failed getting system capacity and object details. Quiting!"
        Write-VerboseLog -ErrorInfo $PSItem
        Stop-Transcript
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }

    #System alerts
    try {
        Show-Message -Message "Collecting system alerts"
        $all_alerts = .\\api_calls\System_Alerts.ps1 -gateway $gateway -ScaleIOAuthHeaders $ScaleIOAuthHeaders
    }   
    catch {
        Show-Message -Severity high -Message "Failed collecting system alerts. Quiting!"
        Write-VerboseLog -ErrorInfo $PSItem
        Stop-Transcript
        $PSCmdlet.ThrowTerminatingError($PSItem)
    } 

    #Health status of all disks in the cluster
    try {
        Show-Message -Message "Collecting health info of disks in the cluster"
        $all_disk_health = .\\api_calls\Disk_Health.ps1 -gateway $gateway -ScaleIOAuthHeaders $ScaleIOAuthHeaders
    }
    Catch {
        Show-Message -Severity high -Message "Failed collecting disk health info. Quiting!"
        Write-VerboseLog -ErrorInfo $PSItem
        Stop-Transcript
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }

    #Creating HTML fragments for output region
    Show-Message -Message "Converting to HTML fragments"
    $mdm_obj = New-Object -TypeName psobject -Property $mdm_props
    $frag1 = $mdm_obj | ConvertTo-Html -As List -Fragment -PreContent '<h2>MDM cluster</h2>' | Out-String

    $system_capacity_obj = New-Object -TypeName psobject -Property $system_capacity_objects
    $frag2 = $system_capacity_obj | ConvertTo-Html -As List -Fragment -PreContent '<h2>System overall capacity and objects</h2>' | Out-String

    $frag3 = $all_alerts | ConvertTo-Html -Fragment -PreContent '<h2>Alerts</h2>' | Out-String

    $frag4 = $all_disk_health | ConvertTo-Html -Fragment -PreContent '<h2>Disk health</h2>' | Out-String
    Show-Message -Message "Converting to HTML fragments - completed"

    # HTML region
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
    Show-Message -Message "Generating final HTML report file"
    ConvertTo-HTML -head $head -PostContent $frag1,$frag2,$frag3,$frag4 -PreContent “<h1>ScaleIO_Cluster_Report</h1>`n<h5>Generated_on:$((Get-Date).DateTime)</h5>” | out-file C:\sio_daily_report.html
    Show-Message -Message "Generating final HTML report file - completed"
    Show-Message -Message "Report saved at C:\sio_daily_report.html"
}