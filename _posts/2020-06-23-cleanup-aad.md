---
layout: post
title: Purge Azure AD Deleted Objects
date: 2020-06-23
summary: |
 When you delete objects in Azure AD they go into a "Deleted" state but are not
 actually deleted.  In this short post we will look at how to permanently delete
 objects from Azure AD.
tags: azure techtips
categories:
  - Tech Tips
  - Azure
---

Ever get the dreaded message: __"The directory object quota limit for the Principal has been exceeded. 
Please ask your administrator to increase the quota limit or delete objects to
reduce the used quota."__  But when you go and look you only have a handfull of
objects listed... certainly nowhere near the 250 allowed.
In this post we'll see one potential way to alleviate this issue.  We'll discover
that what appears to be the case on the surface is not really the case with
Azure AD.  Azure AD actually doesn't delete objects right away it marks them as
"Deleted".  So if you really want to remove objects from Azure AD read on...


## Problem
Azure AD service principal objects have been deleted via the CLI or UI... but have
they?  If we take a closer look we'll find that these objects are in a "Deleted"
state but have not been removed from Azure AD.  They are eventually removed but
in the meantime they take up space as an AAD object and count towards your
account limit.


## Solution
I write a lot of automation scripts and one of the things I normally do is
create a service principal that has limited access to Azure resources,
typically just enough to get the job done.  This is a principal called [Least
Privilege](https://docs.microsoft.com/en-us/azure/role-based-access-control/best-practices).
Recently, I had been testing a few automation scripts and not doing my due
diligence to clean up all the service principal objects that were created when I
got this from the az cli...

> 
> The directory object quota limit for the Principal has been exceeded. 
> Please ask your administrator to increase the quota limit or delete objects to
> reduce the used quota.
> 

After a little investigation I found that a user can only create 250 Azure AD
objects before hitting an Azure limit and needing to request a quota increase.
This is from the [Azure AD service limits and
restrictions](https://docs.microsoft.com/en-us/azure/active-directory/users-groups-roles/directory-service-limits-restrictions#:~:text=A%20maximum%20of%2050%2C000%20Azure,to%20300%2C000%20Azure%20AD%20resources) page.

> A non-admin user can create no more than 250 Azure AD resources. Both active resources and deleted resources that are available to restore count toward this quota. Only deleted Azure AD resources that were deleted fewer than 30 days ago are available to restore. Deleted Azure AD resources that are no longer available to restore count toward this quota at a value of one-quarter for 30 days. If you have developers who are likely to repeatedly exceed this quota in the course of their regular duties, you can create and assign a custom role with permission to create a limitless number of app registrations.

I thought "no problem" and wrote a quick script to go through and delete a bunch
of unused service principals but when I hit the same issue not long after I knew
there was something I was missing.  I soon realized that the deleted objects were still being
counted against my total because they hadn't really been completely deleted. Not
only are the deleted objects not being fully deleted but something else I
discovered that was interesting is that each object in Azure AD actually has 2
objects associated with it. So everytime I would go and delete service principals
I was essentially only deleting one of the 2 objects. That was why I kept
hitting this limit after shorter and shorter periods of time... Enter Powershell

I'm not a big Powershell user but in this case I couldn't
find a suitable az cli option to remove the deleted objects in AAD.  There may be one
(there usually is) but I just couldn't find it.  A quick search found the
Powershell module that I could use which is
[AzureAD](https://www.powershellgallery.com/packages/AzureAD/2.0.2.76) but
unfortuately it hasn't been offically released for .Net core yet so I couldn't install it on
my Mac.  Fortunately though it has been added to the Powershell terminal in
Azure Cloud Shell so I was able to spin up a terminal there.

The first thing I did after using __Connect-AzureAD__ to login to Azure is to get my Principal's ObjectID based on my email address.

```terminal
Get-AzureADUser -ObjectId "aliasname@microsoft.com"

ObjectId                             DisplayName     UserPrincipalName        UserType
--------                             -----------     -----------------        --------
xxxxxxxx-yyyy-zzzz-aaaa-bbbbbbbbbbbb Brent McConnell aliasname@microsoft.com  Member

```

Once I had my ObjectId I was able to use the
[Get-AzureADUserCreatedObject](https://docs.microsoft.com/en-us/powershell/module/azuread/get-azureadusercreatedobject?view=azureadps-2.0) 
to list __all__ the AzureAD object belonging to my ObjectId.  


```terminal
Get-AzureADUserCreatedObject -All $true -ObjectId cxxxxxxxx-yyyy-zzzz-aaaa-bbbbbbbbbbb

ObjectId                             AppId                                DisplayName
--------                             -----                                -----------
11111111-zzzz-aaaa-b426-999999999999 88888888-e2db-cccc-eeee-gggggggggggg test-sp-20
22222222-zzzz-aaaa-a45c-000000000000 77777777-101e-dddd-ffff-hhhhhhhhhhhh test-sp-19
...
```

I'm not going to pretend I'm an Azure AD expert but I did notice that
there were 2 objects associated with each of the DisplayName entries for a
service principal and they had different ObjectIds. After deleting a particular service
principal one of those entries would be removed and the other would remain for
30 days.

Some more digging through docs led me to
[Remove-AzureADMSDeletedDirectoryObject](https://docs.microsoft.com/en-us/powershell/module/azuread/get-azureadmsdeleteddirectoryobject?view=azureadps-2.0-preview). 
This cmdlet is used to purge a soft deleted directory object.  Now I had a
solution to these pesky semi-deleted objects.

```terminal
(Get-AzureADUserCreatedObject -All $true -ObjectId xxxxxxxx-yyyy-zzzz-aaaa-bbbbbbbbbbb) | 
  ForEach-Object {Remove-AzureADMSDeletedDirectoryObject -Id $_.ObjectId}

```

The above command will try to delete every object associated with your account
but most importantly will __FAIL__ on objects that still exist.  So you'll see
several error message about ResourceNotFound but it will delete all the soft
deleted objects.

If the above command is a little too aggressive for you and you don't feel like
taking any chances you can also delete by name or Id.  The following will delete
by a particular name using a wildcard (*).

```terminal
(Get-AzureADUserCreatedObject -All $true -ObjectId xxxxxxxx-yyyy-zzzz-aaaa-bbbbbbbbbb) `
  .where{($_.DisplayName -like 'terraform-sp-*')} | 
  ForEach-Object {Remove-AzureADMSDeletedDirectoryObject -Id $_.ObjectId}
```

Most people probably aren't creating as many service principals as I did but if you are
one of the few who do hopefully you'll find this article helpful.
