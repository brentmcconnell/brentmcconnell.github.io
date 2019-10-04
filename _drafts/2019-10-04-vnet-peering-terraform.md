---
layout: post
title:  Azure VNet Peering with Linux using Terraform
date: 2019-10-04
summary: |
 This post takes a look at setting up a Hub and Spoke network topology in Azure
 using VNet Peering and Terraform
tags: azure terraform vnet networking
---
In this post we'll take a look at using Terraform to setup an Azure environment
that implements a Hub and Spoke network topology using Linux as a Virtual
Network Appliance (ie router). This script will setup the custom route tables
that allow the individual spoke networks to communicate through the Hub VNet.

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
your fingertips you will need ARM.  There is no getting around that.  Any new
feature that is released in Azure will have ARM support on day #1.  If you use
Terraform as your IaC tool you probably won't get new features for a few months
in HCL.

Having said that everything I needed for this project was fully supported in HCL
via the Azure Provider.  I used azurerm version 1.34 in my scripts with
Terraform 0.12.9.  If you are looking for a treasure trove of Terraform scripts
look no further than
[Github terraform-provider-azurerm](https://github.com/terraform-providers/terraform-provider-azurerm/tree/master/examples).
This repo is full of great examples for using Terraform with Azure, however what
I wanted wasn't available in this repo :unamused:.

Let's look at what I was trying to do.  This diagram depicts a basic hub and
spoke network connected with vnet peering so that resources can communicate with
one another via the Hub vnet.  
![Hub-Spoke
VNet](/images/2019-10-04-vnet-peering-terraform/hub-spoke-no-gateway-routing.svg){:
.align-left .shadow .outline}
