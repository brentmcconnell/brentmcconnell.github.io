---
layout: post
title:  Migrating a non-HyperV VM (aka. VirtualBox) to Azure
date: 2019-10-09
summary: |
  In this post we take a look at what it takes to move a VM running in VirtualBox
  on MacOS to Azure.  I recently came across this situation and since it took a
  good bit of work to get everything working correctl, I thought I would write it
  up since I'm sure someone else out there will come across a similar issue.
tags: azure virtualbox oracle linux iaas
---

Let's have some fun in this post moving a virtual machine from VirtualBox on
MacOS to Azure. This can be a little tricky because not only do you have to
prep the VM as you normally would for Azure but you also have to package up the
HyperV modules so you can be used at boot time once moved. Personally, I would
recommend Infrastructre as Code (IaC) and configuration management software
typically for this kind of thing, however, sometimes that's not an option so in
this post we'll look at moving a VM from MacOS (no HyperV) to Azure (HyperV) and
what it takes to get there.

## Problem
Migrating an existing non-HyperV VM to Azure.  For this we need to prep the VM
and install the HyperV modules in the initrd.

## Solution 
Microsoft provides a good starting point for migrating VMs to Azure
in their documentation with [Create a Linux VM from a custom disk with the Azure
CLI](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/upload-vhd).
This document was my starting point but the really
important section of the page to review is the [Prepare the
VM](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/upload-vhd#pre
pare-the-vm) section. This lists the most popular distros and how
to go about preparing for a move to Azure. In my case I was moving
an Oracle 7.7 VM from VirtualBox so I will cover the basic steps
I used based on [Prepare an Oracle Linux virtual machine from
Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/oracle-crea
te-upload-vhd?toc=%2fazure%2fvirtual-machines%2flinux%2ftoc.json). This page
covers all the essential steps... mostly (we'll cover the gaps below)... but the
ordering of the steps is misleading and caused me a few hours so I thought I'd
rewrite the steps here for anyone who doesn't want to waste their time :smiley:.

__NOTE__: It should also be noted that Oracle Enterprise Linux also
has the HyperV modules in the distro which means I was able
to bundle them into my initrd as shown below. In some cases
you will need to download and install the [Linux Integration
Services](https://www.microsoft.com/en-us/download/details.aspx?id=55106)
package from Microsoft to get the modules you need for HyperV.

First, it should be noted that the page assumes you are currently using HyperV
__which in the VirtualBox case we are not__. This would also apply to VMWare VMs
as well (ie. no HyperV). This means that we are going to need to add some HyperV
modules to the boot process so that when we get to Azure the VM will have the
necessary modules to boot on a HyperV hypervisor.

Before we get started you should do a __yum update__. This is also important
because we are going to create a new initrd and if you rebuild the initrd before
you install the updates you have the potential to get a new kernel version which
would mean the initrd changes wouldn't be loaded with the new kernel. So in
summary unless you have a good reason not to run update just do it.

```terminal
>> sudo yum -y update
>> reboot
```

The first thing we'll do after than is rebuild the initrd filesystem and include
the HyperV modules we'll need in Azure. Modify __/etc/dracut.conf__ and under
the __add_drivers__ line we'll add the HyperV modules.

```terminal
>> echo "add_drivers+=\"hv_vmbus hv_netvsc hv_storvsc hv_balloon hv_utils hid_hyperv hyperv_keyboard hyperv_fb\"" >> /etc/dracut.conf
>> sudo dracut -f -v
``` 

At this point you'll have a new initrd that contains the HyperV modules. You can
check this with lsinitrd.

```terminal
>> lsinitrd | grep hv
drwxr-xr-x   2 root     root            0 Oct  9 19:49 usr/lib/modules/4.14.35-1902.5.2.2.el7uek.x86_64/kernel/drivers/hv
-rw-r--r--   1 root     root        10296 Sep 19 20:47 usr/lib/modules/4.14.35-1902.5.2.2.el7uek.x86_64/kernel/drivers/hv/hv_balloon.ko.xz
-rw-r--r--   1 root     root        12588 Sep 19 20:47 usr/lib/modules/4.14.35-1902.5.2.2.el7uek.x86_64/kernel/drivers/hv/hv_utils.ko.xz
-rw-r--r--   1 root     root        32936 Sep 19 20:47 usr/lib/modules/4.14.35-1902.5.2.2.el7uek.x86_64/kernel/drivers/hv/hv_vmbus.ko.xz
-rw-r--r--   1 root     root        31184 Sep 19 20:47 usr/lib/modules/4.14.35-1902.5.2.2.el7uek.x86_64/kernel/drivers/net/hyperv/hv_netvsc.ko.xz
-rw-r--r--   1 root     root         9604 Sep 19 20:47 usr/lib/modules/4.14.35-1902.5.2.2.el7uek.x86_64/kernel/drivers/scsi/hv_storvsc.ko.xz
```

At this point you can start following
[Prepare an Oracle Linux virtual machine for
Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/ora
cle-create-upload-vhd). In my case I was using the [Oracle Linux
7.0+](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/orac
le-create-upload-vhd#oracle-linux-70) instructions. There are 2 parts to
the instructions that weren't clear so I'll give my .02 there.

Step 9 calls for modifying __/etc/default/grub__. Just make sure your
__GRUB_CMDLINE_LINUX__ is what is documented. You can remove the other
settings in that particular line.

Here is mine __after__ the changes were made.
```terminal
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="rootdelay=300 console=ttyS0 earlyprintk=ttyS0 net.ifnames=0"
GRUB_DISABLE_RECOVERY="true"
```

These settings will ensure you can connect to the serial port from Azure (not
Azure Government but hopefully soon :wink:).

Step 12 instructs you to install the WALinuxAgent and enable it. This is not
strictly necessary but is definitely recommended. However, you have to enable
the __[ol7_addons]__ section in __/etc/yum.repos.d/oracle-linux-ol7.repo__ file
by adding __enabled=1__.

```terminal
[ol7_addons]
name=Oracle Linux $releasever Add ons ($basearch)
baseurl=https://yum$ociregion.oracle.com/repo/OracleLinux/OL7/addons/$basearch/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1
```

After the steps to prepare the VM have been completed you should __reboot__
the VM to ensure all your changes didn't accidentally break something,
otherwise you are now ready to upload to Azure and attach to a VM using
the instructions found at [Create a Linux VM from a custom disk with Azure
CLI](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/uploa
d-vhd#option-1-upload-a-vhd). These instructions worked out of the box so I
won't repeat them here.

At this point you should have a working VM in Azure that was migrated from your
non-HyperV environment.  Good Luck!!


