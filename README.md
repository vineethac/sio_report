# Overview
This project will generate a brief HTML report of your ScaleIO SDS infrastructure by making use of REST APIs and PowerShell. The report provides information about MDM cluster state, overall cluster capacity, system objects, alerts, and health state of all disks in the cluster. Here the API is available as part of ScaleIO Gateway. These REST API allows you to query information and perform actions on ScaleIO cluster. To access the API you need to provide the ScaleIO Gateway username and password. Responses returned are formatted in JSON format. 
# How to use?
PS> .\invoke_sio_report.ps1 -gateway [ScaleIO REST gateway IP]
# Screenshot of HTML report
![image](https://user-images.githubusercontent.com/30316226/38018752-726b7462-3293-11e8-95c6-dcbffa8182ae.png)
