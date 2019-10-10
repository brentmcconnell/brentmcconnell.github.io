---
layout: post
title:  Azure Hub and Spoke Network with Terraform
date: 2019-10-04
summary: |
 This post takes a look at setting up a Hub and Spoke network topology in Azure
 using VNet Peering and Terraform
tags: azure terraform vnet networking
---
In this post we'll take a look at using Terraform to setup an Azure environment
that implements a Hub and Spoke network topology using Linux as a Virtual
Network Appliance (ie router). This post will setup the custom route tables
that allow the individual spoke networks to communicate through the Hub VNet as
well as provision an NVA in the Hub VNet.

## Problem
How do you create a Hub and Spoke network topology in Azure using Terraform and
implement with a Linux NVA so that traffic between Spoke vnets are routed via
the Hub vnet?  I recently had to do this and wasn't able to find an example that
used Linux as the NVA so I thought I'd provide a quick blog post to explain my
implementation.

## Solution 
Terraform is a great solution to the Infra as Code (IaC) problem and has great
support for creating Azure resources.  I tend to prefer it over ARM templates
because Hashicorp Configuration Language (HCL) is so much more readable than
long JSON files, however just note that if you want the __FULL__ power of Azure at
your fingertips you will need ARM, there is no getting around that.  Any new
feature that is released in Azure will have ARM support on Day #1.  If you use
Terraform as your IaC tool you probably won't get new features for a few months
in HCL.

Having said that everything I needed for this project was fully supported in HCL
via the Azure Provider.  I used azurerm version 1.34 in my scripts with
Terraform 0.12.9.  If you are looking for a treasure trove of Terraform scripts
look no further than
[Github terraform-provider-azurerm](https://github.com/terraform-providers/terraform-provider-azurerm/tree/master/examples).
This repo is full of great examples for using Terraform with Azure, however what
I wanted wasn't available in this repo :unamused:.

![Hub-Spoke
VNet](/images/2019-10-04-vnet-peering-terraform/hub-spoke-no-gateway-routing.svg){:
.align-left .shadow .outline} 

### Architecture
Let's look at what I wanted to do.  This diagram depicts a basic hub and
spoke network connected with vnet peering so that resources can communicate with
one another via the Hub vnet.  Why you ask?  The hub and spoke topology is 
arguably the most popular configuration for networks and is the one I see most
often.  It allows workloads to be isolated in the spoke vnets while sharing common
resources like shared services in the hub vnet.  This architecture is also well
suited for connecting cloud resources to on-prem networks via the hub and some
form of VPN gateway.

By default if you setup Vnet peering in a hub and spoke configuration you will
have network isolation between the spokes.  The spoke networks will be able to
communicate with the hub vnet but not their peers.  In my case though I wanted
the spoke networks to be able to communicate with one another.  To facilitate
the communication I provisioned a Linux VM in the hub vnet to act as an network
virtual appliance (NVA) and create user defined routes (UDRs) on the spoke vnets
so that communication flowed through the hub's NVA.  Basically, exactly what is
in the diagram.

All the Terraform scripts used to do this are located on Github at [msft-csu/azure-terraform-scripts](https://github.com/msft-csu/azure-terraform-scripts).
You'll need a service principal to execute Terraform but all the instructions to
create on and get up and running are in the
[README](https://github.com/msft-csu/azure-terraform-scripts/blob/master/README.md).

Enjoy :smiley:
