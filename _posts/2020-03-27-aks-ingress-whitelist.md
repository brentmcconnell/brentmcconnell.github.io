---
layout: post
title: Whitelist Ingress Access into AKS Clusters
date: 2020-03-27
summary: |
 This post will look at limiting ingress access to an Azure Kubernetes Cluster (AKS)
 using NGINX Ingress controller.  
tags: aks azure ingress
categories:
  - Tech Tips
  - Azure
  - Kubernetes
---

If you read my [last
post](https://www.azurepatterns.com/2020/03/17/aks-external-dns) on setting up
ExternalDNS and CertManager on AKS you may have noticed that ingress to the
exposed services you delpoy be is open to the Internet.  Anyone who
wants to try to access those services will have the ability to try.
In this post I'll look at a simple way to lock those services down so that
only specific addresses have access. And we'll also look at what changes
we'll need to make to cert-manager once ingress is locked down.

## Problem

In my last post I setup cert-manager and external-dns services on AKS so that
DNS records and SSL certificates were managed automatically for services
deployed to AKS. However, in that configuration one of the things you may
have noticed is that ingress was open to the Internet. Anyone who stumbles
onto your service would have access to attempt logins or, in some cases if
you don't have authentication, use it! What we'd like to do is limit access
to our services based on network CIDR.

## Solution

### Agent Pool Subnet NSG

The first thing to note about limiting access to your cluster is that AKS
creates an NSG for the agent pool subnet when the cluster is created. When
you install NGINX this NSG is modified to include inbound port rules. By
default these are ports 80 and 443. If you manually modify the NSG rules
everytime the security group is modified by NGINX your changes will be overwritten.
However, we can use the LoadBalancerSourceRanges option of the Kubernetes
service that manages the LoadBalancer. This will implement Source rules on the
NSG managed by NGINX. This way when NGINX modifies any inbound rules the
source range will be maintained and managed.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  ports:
  - port: 8765
    targetPort: 9376
  selector:
    app: example
  type: LoadBalancer
  loadBalancerSourceRanges:
  - 130.211.204.1/32
  - 130.211.204.2/32
```

Helm also has a option for implementing this feature on the Service.

```terminal

>> CIDRS=130.211.204.1/32,130.211.204.2/32
>> helm upgrade nginx-ingress stable/nginx-ingress \
      --wait --namespace ingress --reuse-values \
      --set controller.service.loadBalancerSourceRanges={$CIDRS}

```

At this point if you view the inbound rules on the NSG attached to the agent pool subnet you'll see that the Source is now set to the CIDRS you provided. 

### NGINX Ingress Options

Using the Agent Pool NSG is a great way to manage inbound ingress access but it has the limitation of being inflexible.  You are locking down ingress except to what is specified in the provided CIDRs so if you want some services to be exposed to certain IP ranges while other services have different IP ranges you don't have that kind of flexibility.  Enter NGINX.

NGINX has lots of [configuation options
available](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/). 
The __whitelist-source-range__ option sets the IPs for a particular Ingress.  This can be done globally at the Service level, only at the Ingress level or you can use both.  The global option will be the default and the individual Ingress objects can override the global option.  

The global option can be set using a ConfigMap that overrides the default vaules for the NGINX service.  If we use Helm again to configure this option you'd have something like the following:

```terminal

>> CIDRS=130.211.204.1/32,130.211.204.2/32
>> helm upgrade --install nginx-ingress stable/nginx-ingress \
  --wait --namespace ingress --reuse-values \
  --set controller.config.whitelist-source-range=$CIDRS \
  --set controller.service.externalTrafficPolicy=Local 

```

In order to use __whitelist-source-range__ NGINX will need access to the
external IP of incoming requests.  Typically NGINX would see the NAT'd
Kubernetes address but because we want to limit which external IPs have access
we'll need NGINX to have access to the requests source IP.  This can be done by
setting __controller.service.externalTrafficPolicy=Local__ on the NGINX
controller.

Again, this sets the __global configuration__ of NGINX so every Ingress option will inherit this whitelist unless overridden at the Ingress level.  This can be done by setting an annonation on each Ingress object that you want to expose to a different set of IPs.  For instance if we have a service we want to open to all traffic we can use an Ingress object similar to the following to override the global whitelist.

```yaml
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: nginx
  annotations:
    nginx.ingress.kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/whitelist-source-range: "130.211.204.1" 
    cert-manager.io/cluster-issuer: letsencrypt
spec:
  tls:
  - hosts:
    - nginx.example.com
    secretName: tls-secret
  rules:
  - host: nginx.example.com
    http:
      paths:
      - backend:
          serviceName: nginx-svc
          servicePort: 80
        path: /

```

### Let's Encrypt Changes
__NOTE__:  If you used the scripts in the [last post]({% post_url 2020-03-17-aks-external-dns %}) to setup cert-manager and external-dns you'll have to make some changes to external-dns before locking down your services.  This is because the last post used the http resolver for Let's Encrypt to verify domain ownership.  If you limit ingress to your cluster Let's Encrypt won't be able to verify your domains any longer using _http_.  

Let's Encrypt has different types of verification for domain ownership and one supported option on Azure is DNS.  When you use DNS to verify domain ownership Let's Encrypt will request certain __txt__ records be created that it can verify before issuing SSL certificates.  Since we used Azure DNS Zones for our DNS entries in the last post we'll make a few modifications so that cert-manager can modify DNS records.

To enable this feature we'll need to do two things.  First, we'll need to create a Kubernetes secret that contains the password of a service principal that external-dns can use to modify DNS records.  Secondly, we'll also need to change the ClusterIssuer from http to dns.  The following script fragments can be used with the information from a service principal.  The service principal created will need Contributor access to the DNS Zone to allow cert-manager to make the appropriate changes.  If you use the same service principal we created [last time]({% post_url 2020-03-17-aks-external-dns %}) that should work just fine.

```terminal
SP_APPID={Service Principal AppID}
SP_PASSWORD={Service Principal Password}
SP_TENANTID={Service Principal Tenant}
SUBSCRIPTION_ID={Subscription Id}
AZURE_CLOUD={Which Azure Cloud You are Using}
DOMAIN_NAME={Domain that will be managed}
DNS_RG={Resource Group for DNS Zone}
EMAIL={Let's Encrypt Email Address}

>> helm install cert-manager \
    --wait --namespace cert-manager \
    --version v0.13.0 \
    jetstack/cert-manager

>> kubectl create secret generic azuredns-config \
    --from-literal=client-secret=$SP_PASSWORD \
    -n cert-manager 

# Create Prod LetsEncrypt ClusterIssuer
>> cat <<-EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: $EMAIL 
    privateKeySecretRef:
      name: letsencrypt
    solvers:
    - dns01:
        azuredns:
          clientID: $SP_APPID 
          clientSecretSecretRef:
            name: azuredns-config
            key: client-secret
          subscriptionID: $SUBSCRIPTION_ID 
          tenantID: $SP_TENANTID 
          resourceGroupName: $DNS_RG 
          hostedZoneName: $DOMAIN_NAME
          environment: $AZURE_CLOUD 
EOF

```

So at this point you should have cert-manager configured to create the necessary DNS records so that Let's Encrypt can verify domain ownership.  Once this is completed and working you can lock down ingress into your Kubernetes cluster.
