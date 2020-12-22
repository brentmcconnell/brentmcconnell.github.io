---
layout: post
title: Enable JIT Access on Azure VMs 
date: 2020-12-21
summary: |
 Did you ever wish you could control when and who could get access to your Azure 
 VMs?  Well now you can using Azure Security Center's Just-In-Time access
 feature.
tags: azure techtips
categories:
  - Tech Tips
  - Azure
---

In this post we'll take a look at a feature of Azure Security Center called
Just-In-Time VM access.  This feature will allow you to timebox when and who has
access to your Azure VMs.  Black Hats will invariably look for open management
ports on your VMs.  RDP and SSH are often used by hackers as a possible entry
point for access to your environment.  Using JIT Access you can block access to
these ports and require users to submit a request in order to gain access during
a specific timeframe.  

## Problem
The problem is simple enough... how do you limit access to your VMs so that only
users you permit have access to your VMs and only during a time that you allow?
This is accomplished by configuring some rules on the NSG and/or Azure Firewall that
protect your VM's access until a request and a timeframe for access are approved.
The great thing about this is that Azure has wrapped this functionality up into
a service called [Just-In-Time
Access](https://docs.microsoft.com/en-us/azure/security-center/just-in-time-explained) and you can activate it today.


## Solution

[Azure Security Center Just-In-Time
Access](https://docs.microsoft.com/en-us/azure/security-center/security-center-just-in-time?tabs=jit-config-asc%2Cjit-request-asc) is a great solution to solve this
problem with only one downside... It's currently ___not___ supported in the Azure CLI
or by Terraform.  As of late December 2020 there is work underway in the
Terraform project to support JIT but not yet available.  I haven't seen any
timeline of when it will be added to the CLI but I suspect it will come sometime
in 2021.  In the meantime I've written a script that uses the Azure REST API to
activate JIT for Azure VMs.  Of course you can also use the Azure Portal or
Powershell to the same effect but I typically like to do as much as possible
from Bash

{% gist b14035fd71516354f15490c343431b01 JIT-Access %}

This script takes -n (name of VM) and -g (resource group VM lives in) as it's
only parameters.  It will then suss out that subscription you are running in and
use the location that the VM lives in to complete it's necessary input.  It also
relies on have the az cli available for the REST call it makes.  You'll also
notice from the script that it only includes rules for 22 and 3389.  If there
are other ports you need to provide access to you'll need to modify the script
to support those ports.

```terminal

>>az-jit-access -n lin-30400 -g RG-32698 

Check program requirements...
 * Found az

RG:               RG-32698
VM_NAME:          lin-30400

Are you sure you want to Proceed and enable JIT Access [y/N]?y

{
  "id": "/subscriptions/XXXXXXXXX/resourceGroups/RG-32698/providers/Microsoft.Security/locations/eastus/jitNetworkAccessPolicies/default",
  "kind": "Basic",
  "location": "eastus2",
  "name": "default",
  "properties": {
    "appendMode": false,
    "provisioningState": "Updating",
    "requests": [],
    "virtualMachines": [
      {
        "id": "/subscriptions/XXXXXXXX/resourceGroups/RG-32698/providers/Microsoft.Compute/virtualMachines/lin-30400",
        "ports": [
          {
            "allowedSourceAddressPrefix": "*",
            "maxRequestAccessDuration": "PT3H",
            "number": 22,
            "protocol": "*"
          },
          {
            "allowedSourceAddressPrefix": "*",
            "maxRequestAccessDuration": "PT3H",
            "number": 3389,
            "protocol": "*"
          }
        ],
        "resourceGroup": "RG-32698"
      }
    ]
  },
  "resourceGroup": "RG-32698",
  "type": "Microsoft.Security/locations/jitNetworkAccessPolicies"
}
```
