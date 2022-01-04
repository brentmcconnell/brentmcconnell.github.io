---
layout: post
title: Azure DevOps Bootstrap Script
date: 2022-01-03
summary: |
  In this post we'll look at scripting a boostrap project in Azure for use with
  Azure DevOps or GitHub Actions.
tags: azure techtips github
categories:
  - Tech Tips
  - Azure
---
Have you ever wanted to test out configuration of resources setup quickly in Azure using devops
pipelines and been frustrated by how long it takes to get your project
bootstrapped with a service principal, keystore, storage account and other
goodies that are often required?  If so, this is the post for you.

## Problem
The problem is really just lack of time.  As a Solution Architect it falls on me
to demo different Azure configurations quickly and consistently.
Sometimes this is easy to do with my AAD account but often I need
to demostrate some aspect of a "least privilege" role with Azure DevOps or
GitHub Actions.  To do this quickly I rely on this script.

## Solution
The following is the script I use when I want to quickly get something going in
ADO or GitHub.  It sets up the necessary components for being able to setup a
service principal that has permissions on a particular resource group.  The
service principal is stored in an Azure Keyvault and a storage account is
created for good measure in case you are using something like Terraform that
needs someplace to put a state file.  The nice thing about this script is that
it will either create everything for you or will configure the resources you
pass into it.

Let's look at what this script does:
1. Create or configure a resource group for your project resources
1. Creates a service principal that has the Owner role assigned for the resource
   group above
1. Creates or configures a KeyVault in the resource group and stores the important bits of the
   service principal in it
1. Configures permissions on the service principal so that it can read Secrets
   from the KeyVault.
1. Creates a storage account in the resource group and adds the access key to
   the KeyVault

> The account that runs this script requires subscription level permissions

{% gist 109a8e7819ddb8b14a5db651ce36a2f4 az-basic-project.sh %}



