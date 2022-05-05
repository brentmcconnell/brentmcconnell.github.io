---
layout: post
title: Website Authentication for Blobs
date: 2022-05-03
summary: |
  Let's look at an easy way to serve your storage account contents as a website
  but with the twist that you can authenticate users that are a part of your
  Azure Active Directory tenant
tags: azure techtips
categories:
  - Tech Tips
  - Azure
---
I recently had a customer who wanted to authenticate user access to a basic website
that was hosted in Azure Storage Accounts. The basic [static website](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-static-website) functionality that
is bundled with Storage Accounts doesn't provide this.  There are a few ways we
might have approached this, for instance we could have potentially used [Static Web Apps](https://docs.microsoft.com/en-us/azure/static-web-apps/),
however what if we just used their existing App Service plan and the
built in authentication for [Web Apps](https://docs.microsoft.com/en-us/azure/app-service/).

## Problem
Customers will sometimes want a very basic and easy way to serve static websites
that uses AAD authentication.  We aren't talking about sophisticated role based
access control... just making sure that the folks viewing the website are
members of the correct AAD tenant.  The basic website functionality that is part
of Storage Accounts doesn't provide this functionality but what if we used a Web
App to serve the Storage Account's blob containers?  We could then use the App
Service's Authentication module to authenticate users.  

> This method is probably best for small websites that aren't intended to
scale to a large user base since we aren't using CDNs in this scenario.

## Solution
One simple solution to this problem is to use a container as a web server and
simply mount the storage account as a path mapping in your App Service
configuration.  Let's take a closer look at setting this up.

#### Azure Web App
The first thing we did was decide on a basic web service for hosting the
website, for this we chose NGINX on Alpine.  NGINX is a simple platform for web hosting
and doesn't get into all the idiosyncrasies of Apache as a web server and
Alpine is a trimmed down OS that's great as a container platform due to it's
small size.

Next, we needed to spin up a Web App that uses the NGINX container.
![Overview](/images/2022-05-03-blob-web-auth/web-app-setup.png){:.shadow .outline}

At this point we have a very simple version of a website running that uses NGINX
in our App Service plan.
![Overview](/images/2022-05-03-blob-web-auth/basic-web.png){:.shadow .outline}

However, we already have a website and don't need the homepage from the NGINX
container.  With a little sleuthing we find that the NGINX container is serving
/usr/share/nginx/html as the directory for the website.  We can now use the
Path Mapping feature of App Service to mount our Storage Account container into
our Docker container.
![Overview](/images/2022-05-03-blob-web-auth/storage-mount.png){:.shadow .outline}

Now when the Web App restarts we see that we now have our custom website that is
stored in a private Storage Account being served by the NGINX container in our
App Service.
![Overview](/images/2022-05-03-blob-web-auth/homepage.png){:.shadow .outline}

#### Azure Authentication
This gets us a working website but at this point it is still accessible to
anyone and everyone via the Web App URL.  The requirement we need to implement
now is to make it accessible only if you are a member of the company's AAD
tenant.  For this we'll use the built-in App Service Authentication module in
the left navigation pane of our App Service.
![Overview](/images/2022-05-03-blob-web-auth/authentication-provider.png){:.shadow .outline}

When we add the Microsoft Authentication Provider we can now configure it to
create a new application registration and use the "Current tenant" as the
authentication source for authentication to the App Service.  We can also
restrict access to "Require authentication" so that no unauthenticated access is
permitted.
![Overview](/images/2022-05-03-blob-web-auth/setup-provider.png){:.shadow .outline}

Now after a few minutes when anyone who is not logged into your AAD tenant tries
to access the website they will be prompted to login via AAD.  And that's it!
![Overview](/images/2022-05-03-blob-web-auth/signin.png){:.shadow .outline}







