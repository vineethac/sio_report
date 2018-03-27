# Overview
This project will generate a brief HTML report of your ScaleIO SDS infrastructure by making use of ScaleIO REST APIs and PowerShell. The report provides information about MDM cluster state, overall cluster capacity, system objects, alerts, and health state of all disks in the cluster.
# How to use?
PS> .\invoke_sio_report.ps1 -gateway [ScaleIO gateway IP]
