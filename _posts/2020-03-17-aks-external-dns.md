---
layout: post
title: Automate DNS Records with ExternalDNS on AKS
date: 2020-03-17
summary: |
 Let's look at what it takes to install and configure a external-dns on AKS and
 set it up to manage records for our custome domain.
tags: aks azure
categories:
  - Tech Tips
  - Azure
  - Kubernetes
---

In a recent project I was asked to configure an ingress controller so that
host names specified in ingress objects would automatically create DNS records.
This is exactly what the ExternalDNS for Kubernetes project does.  Unfortuately,
even though there is a section for configuring it on Azure it still was not as
straightforward as the docs made it seem, especially in Azure Government.  This
post walks through getting it up and running and then demonstrates in Azure
Government and demostrates its functionality. 

## Problem

How can we modify DNS records for hosts defined in Ingress objects?
For intance if we have the following
Ingress defined, we want to have Kubernetes add a DNS record for
__nginx.designingdevops.com__. We also want certificates for these new domains
to be issued so that web browsers can connect without exception.

{% gist a8769f1e3a4010c71e1cd764887e6325 nginx-ingress.yaml %}

## Solution

We'll use a number of different Kubernetes projects to implement a solution to
this problem.  I decided to break the solution up into several different
sections with scripts for each section so that it is a little easier to digest.
In order to implement this solution we use the following projects:

* NGINX Ingress: Manages incoming requests to Kubernetes
* ExternalDNS:  Manages DNS entries in our Azure DNS Zone
* Cert-Manager:  Manages Let's Encrypt certificates for our hosts

## Kubernetes Setup

At this point we'll need the Azure CLI installed and a Kubernetes cluster.  I have created a public gist
that contains all the files I used in this post
to create Kubernetes and install ExternalDNS but I leave
installing the Azure CLI up to the reader. The gist for my files is available
[here](https://gist.github.com/brentmcconnell/a8769f1e3a4010c71e1cd764887e6325).
To create a Kubernetes cluster you can use the instructions
[here](https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster) or the script below. 

{% gist a8769f1e3a4010c71e1cd764887e6325 k8s.sh %}

You will notice in the script above that all the variables are configured with
defaults but can be overridden by setting environment variables before running
the script.  For instance if you are in Azure Commercial the above script will
fail since usgovvirginia is the default.  If you execute:

```terminal

>> export LOCATION=eastus
>> ./k8s.sh

```
This will create the Kubernetes cluster in __eastus__ instead of __usgovvirginia__.

Once we have our cluster we can start installing the components we'll need in
order to manage DNS from Kubernetes:

* NGINX ingress controller
* Azure DNS Zone
* Service Principal with permission to manage DNS Zone
* Azure Public IP we can bind to an ingress controller 
* external-dns installed and running 
* cert-manager installed and running

## Ingress Controller and Public IP

At this point we'll create an Azure Public IP and assign that IP to a newly
installed NGINX ingress controller.  I used a static Public IP rather than allow
Azure to generate one just so if I decide to rebuild my cluster in the future I can
just reassign the same Public IP to the LoadBalancer and not have to worry about
DNS record updates.

{% gist a8769f1e3a4010c71e1cd764887e6325 nginx.sh %}

A careful reader of the script might notice that we use:
* __--set controller.publishService.enabled=true__ and 
* __--set controller.publishService.pathOverride=ingress/nginx-ingress-controller__

These options are used by external-dns so that the correct IP address is
assigned to the DNS records. _These options are required for external-dns to
work correctly._

## ExternalDNS

Now that we have our Ingress controller setup we'll turn out attention to
getting external-dns deployed and configured.  You will need to generate a
Service Principal and provide it to helm during the installation process.  This
script will create/return the ids of a resource group and DNS zone.  It also
provisions a service principal assigns 'Reader' permission on the RG and
'Contributor' permission on the DNS Zone for the service principal.  It then
deploys external-dns using the newly create service principal and DNS
information.  

If you haven't done so already you should also make sure that your domain has
the correct Azure nameservers assigned as your domain's authoritative
nameservers.  This is done outside of Azure at your domain registrar.   

{% gist a8769f1e3a4010c71e1cd764887e6325 external-dns.sh %}

## Cert-Manager

Last but not least we'll install and configure cert-manager to manage Let's
Encrypt certificates for us on the hostnames we create in our domain.

{% gist a8769f1e3a4010c71e1cd764887e6325 cert-manager.sh %}

## Test It Out

If everything has gone according to plan you should now have a Kubernetes
cluster that will generate DNS records based on hosts you define in Ingress
objects.  It will also create SSL certificates for those hosts so that https
works correctly and doesn't generate any host errors.

To test our out new cool deploy you can should create a new file called
__nginx.yaml__ that contains the following yaml modified with your own domain name
in the Ingress object:

{% gist a8769f1e3a4010c71e1cd764887e6325 nginx.yaml %}

Once you've created the __nginx.yaml__ file you can apply it to your Kubernetes
cluster.  The following command will install the NGINX web service into your
current namespace.

```terminal

>> kubectl apply -f nginx.yaml
deployment.apps/nginx created
service/nginx-svc created
ingress.networking.k8s.io/nginx created

```

This doesn't happen right away because it takes time to propogate DNS records
but in my experience you should have this resolve correctly within about 30
minutes.  Open a web browser and navigate to nginx.yourdomainname.com. You
should see the NGINX welcome page als In the meantime you can run the following command to ensure that DNS
records have been created for your hostname.  


```terminal

>> az network dns record-set a list -g $DNS_RG -z $DOMAIN_NAME 

Name    ResourceGroup    Ttl    Type    Metadata
------  ---------------  -----  ------  ----------
nginx   azuredns         300    A

```

NOTE: Make sure you set the environment variables DNS_RG and DOMAIN_NAME before
executing the command above.
