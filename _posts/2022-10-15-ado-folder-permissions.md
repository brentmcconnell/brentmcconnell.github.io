---
layout: post
title: Azure DevOps Folder Permissions 
date: 2022-10-15
summary: |
  Take a look at how to setup Role Based Access Control on Git repos
  using folders in Azure DevOps
tags: azure devops techtips
categories:
  - Tech Tips
  - Azure
  - DevOps
---
Have you ever wanted to setup granular folder permissions in your Azure DevOps repos
but couldn't figure it out?  I was working on a project where the customer
wanted to setup their version of [GitFlow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
 and was trying to setup permissions in Git so that only certain groups of users could control writes to Main, Release, Develop and
Feature branches at specific levels in the path of these
branches.  This post will walk you through how to do that in Azure
DevOps.

## Problem
I won't explain GitFlow here but rather link to Atalssian's GitFlow documents
for the [full
explanation](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow
-workflow). Needless to say there are several branch types in GitFlow including
Main, Release, Develop and Feature branches. Each of these type of branches
might require some form of access control so that users don't check in or merge
unapproved/reviewed changes into folders they aren't allowed to.  For instance
let's say you want to have a Release Team that can control access to all your
version releases whether that is v1.0 or v1.1 or v2.  This post will show you
how.

## Solution
What you may not have known is that if you create paths in your branch names
Azure Devops will allow you to apply RBAC to the folders if you so choose.
![Create
Branch](/images/2022-10-15-ado-folder-permissions/create-branch.png){:.shadow
.outline}
![Branch Policy](/images/2022-10-15-ado-folder-permissions/branch-policy.png){:.shadow .outline}
The default in ADO is an Inheritance model where permissions of the parent are
inherited by the child nodes, however with the click of the mouse you can break
this inheritance chain and apply custom permissions at the folder level in ADO
ensuring that only the right teams have access to those branches.
![Inheritance](/images/2022-10-15-ado-folder-permissions/inheritance.png){:shadow
.outline}
