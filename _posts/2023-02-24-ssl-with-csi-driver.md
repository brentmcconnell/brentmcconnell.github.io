---
layout: post
title: Setting up SSL with the CSI Driver on AKS 
date: 2023-02-24
summary: |
  In this post we'll look a bit closer at the CSI Driver for Kubernetes and how it can be 
  configured to use certificates in KeyVault for SSL in AKS.
tags: azure devops techtips
categories:
  - Tech Tips
  - Azure
  - DevOps
---
## Introduction
I'll bet you're here because you started trying to setup SSL on AKS and wanted to use the CSI driver with Azure KeyVault and realized it wasn't as easy as everyone led you to believe ;).  In this post we'll walk through the steps necessary to set it correctly using KeyVault.  There is also a companion [GitHub repo](http://github.com/brentmcconnell/ssl-with-csi-on-aks).

## Solution

Deploying an application that uses SSL (Secure Sockets Layer) on Azure Kubernetes Service (AKS) can be a daunting task, but with the Container Storage Interface (CSI) driver for AKS, it's made a lot easier. In this blog post, we will cover how to use the CSI driver for AKS to deploy an application that uses SSL.

First, let's discuss what the CSI driver is and why it's important. The Container Storage Interface (CSI) is a standardized interface for Kubernetes storage vendors to integrate with Kubernetes. It allows for more flexible and dynamic volume management in Kubernetes. The CSI driver for AKS enables AKS clusters to use a variety of storage solutions that implement the CSI standard including Azure KeyVault.

### SSL Certificate

The first step is to create an SSL certificate for the application. You can either create a self-signed certificate or obtain a certificate from a trusted certificate authority. For the purposes of this tutorial, we use a certificate that I previously provisioned with Let's Encrypt.  If you want to provision one yourself you can refer to the post [Generating a Let's Encrypt Certificate]({% post_url 2019-06-12-lets-encrypt %})

Let's tuck our SSL certificate away in a KeyVault so that it's secure.  This KeyVault will be what the CSI Driver uses as it's backend to serve the certicates.

```terminal
az keyvault certificate import --vault-name NAME_OF_KEYVAULT -n NAME_OF_CERT_IN_KV -f CERTIFICATE.PFX
```

### AKS Cluster with Secrets Store Addon Enabled

At this point you'll want an AKS cluster with the Secret's Store CSI Driver enabled.  You can use the companion repo for Terraform scripts that will provision AKS for you or you can use the following command to enable the addon:

```terminal
>> az aks enable-addons \
    --addons azure-keyvault-secrets-provider \
    --name myAKSCluster \
    --resource-group myResourceGroup
```

After a bit you should be able to execute "kubectl get pods" and see the following similar pods in your AKS cluster:
```terminal
kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver,secrets-store-provider-azure)'

NAME                                     READY   STATUS    RESTARTS   AGE
aks-secrets-store-csi-driver-4vpkj       3/3     Running   2          4m25s
aks-secrets-store-csi-driver-ctjq6       3/3     Running   2          4m21s
aks-secrets-store-csi-driver-tlvlq       3/3     Running   2          4m24s
aks-secrets-store-provider-azure-5p4nb   1/1     Running   0          4m21s
aks-secrets-store-provider-azure-6pqmv   1/1     Running   0          4m24s
aks-secrets-store-provider-azure-f5qlm   1/1     Running   0          4m25s

```

### Ingress

Next, let's install NGINX ingress controller so we have HTTP access into our cluster and something to provide access to our application.  For this we'll need an external IP address.  If you are using the companion GitHub repo there will be a public IP in the resource group already.  If not you'll need to provision one for the following command.  Be sure to replace RG_NAME and IP_ADDRESS in this command before executing it.

```terminal
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-basic —create-namespace\
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-resource-group"="RG-NAME” \
  --set controller.service.loadBalancerIP=“IP_ADDRESS”
```

### SecretsProviderClass
Whew, we're almost there.  The next bit of magic we'll need is a yaml file that defines our SecretProviderClass.  You can either use the companion repo or the following, replacing objectName with the name of your SSL certificate in Keyvault, userAssignedIdentity, keyvaultName and tenantID with your own.  userAssignedIdentity can be queried with the az CLI using:

```terminal
az aks show -g RG-NAME \
  -n AKS_CLUSTER_NAME \
  —query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv
```

Here is the yaml you'll need for the SecretProviderClass:

```terminal
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-tls
spec:
  provider: azure
  secretObjects:
  - secretName: ingress-tls-csi
    type: kubernetes.io/tls
    data: 
    - objectName: helloworld
      key: tls.key
    - objectName: helloworld
      key: tls.crt
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: "XXXXX-xxxx-XXXX-xxxx-XXXXXXXX"
    keyvaultName: akspublic-deve-kv
    objects: |
      array:
        - |
          objectName: helloworld
          objectType: secret
    tenantId: "XXXXX-xxxx-XXXX-xxxx-XXXXXXXX"
```

If you used the provided yaml to create the secret store you should now have a secret store named “azure-tls”. You can verify this by executing “kubectl apply -f busybox.yaml” using the busybox.yaml file from the GitHub repo. Once the pod is running you can execute “kubectl exec busybox-secrets-store-inline -- ls /mnt/secrets-store/“. You should see the object you created in the KeyVault with the name you provided earlier.

### Application Deployment With SSL
You should also be able to see a secret named “ingress-tls-csi” if you execute “kubectl get secrets -A”
At this point you can create your application deployment and service in AKS. For this example I’ve used a simple publicly available container. Execute “kubectl apply -f aks-helloworld-one.yaml”. This only works if you did not change the secret store name from earlier since it relies on a secretproviderclass names “azure-tls”

At this point you should have a running container but no ingress yet. Verify the container is running using “kubectl get pods -A”. You should see a pod called “aks-helloworld-one-xxxxx-xxxxx”.

Next setup ingress for this service by running “kubectl apply -f aks-helloworld-one-ingress.yaml”.
At this point you should be able to hit your address from DNS in a browser to see a basic webpage that says “Welcome to Azure Kubernetes Service”

If you made it this far... WELL DONE!!