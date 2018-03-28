# Overview
This project will generate a brief HTML report of your ScaleIO Ready Node SDS infrastructure (with AMS - Automated Management Services) by making use of ScaleIO Ready Node AMS REST APIs and PowerShell. The report provides information about MDM cluster state, overall cluster capacity, system objects, alerts, and health state of all disks in the cluster. Here the API is available as part of ScaleIO Ready Node AMS. These AMS REST API allows you to query information and perform actions related to ScaleIO software and ScaleIO Ready Node hardware components. To access the API you need to provide AMS username and password. Responses returned by AMS server are formatted in JSON format. 
# How to use?
PS> .\invoke_sio_report.ps1 -gateway [ScaleIO REST gateway IP]
