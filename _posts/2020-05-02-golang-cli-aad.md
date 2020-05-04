---
layout: post
title: Authenticate Golang CLI with Azure AD 
date: 2020-05-02
summary: |
 Let's build a basic Golang CLI that uses Azure Active Directory Device Token
 authentication.
tags: golang azure
categories:
  - Tech Tips
  - Azure
---
Ever wonder how to integrate a command line application with Azure Active
Directory?  I happened to be working with a client recently who
wanted to do just that and I took the opportunity to dive in a figure it out and
in the process write it up for the website.  In this post we'll look at the
Azure Golang SDK and how to use it for Azure AD authentication and we'll also
create an application registration in AAD and assign permissions to our CLI.

## Problem
Authenticate a Golang CLI application with Azure Active Directory using Device
Token.  In this post we'll write a super basic Golang application that runs from
the command line and prompts the user to use https://microsoft.com/devicelogin
to enter a device token to authenticate with AAD.  You can even use this method
to require multi-factor authentication (MFA) for a user if their AAD profile
requires it.

## Solution

You can find the sample application in my [GitHub
account](https://github.com/brentmcconnell/goazuresample).  In this simple
application.  I use device token authentication to authenticate the Golang
application and then once authenticated the app will create a resource group and
storage account.  It then retrieves the access keys from the storage account and
uses a key to upload a blob to a container.  It will then prompt the user to
either delete the resource group.

The important bits for authenticating are in the init() method of main.go.  I'll
leave it as an exercise to the user to get a Golang environment setup and
understand how to use the go cli to compile the application.

```golang
dfc := auth.NewDeviceFlowConfig(*appId, *tenant)
spToken, err := dfc.ServicePrincipalToken()
authorizer = autorest.NewBearerAuthorizer(spToken)
if err != nil {
    log.Fatal(err)
}
```

For more information about authentication options in Golang using AAD you can
check out this
[page](https://docs.microsoft.com/en-us/azure/developer/go/azure-sdk-authentication). :w
This bit of code will prompt the user to use  microsoft.com/devicelogin to enter
a device token and login to Azure AD.  It will then generate an OAuth token that
can be used to create an Authorizer that is used in many of the Azure SDK
REST clients like so...

```golang
// Create a resource group for the deployment.
func createGroup() (group resources.Group, err error) {
	groupsClient := resources.NewGroupsClient(*subId)
	groupsClient.Authorizer = authorizer
	group, err = groupsClient.CreateOrUpdate(
		ctx,
		resourceGroupName,
		resources.Group{
			Location: to.StringPtr(location)})
	if err != nil {
		log.Fatal(err)
	}
	return group, nil
}
```

The above is a pretty common pattern used to authenticate a client and access
Azure services.

### Application Registration
In order for our little golang application to work it requires a few bits of data that
can be entered on the command line as arguments.
* Subscription ID
* Tenant ID
* Application Registration ID

You should be able to get your subscription id and tenant id using the Azure
CLI.

```terminal
>> az account list -o json
```

That will get you two of the things you need but you'll also need an application
registration with the correct permissions.  You can do that via the Azure portal
but you can also use the aad.sh script in the GitHub repository to generate an application
registration.  This script can run without any parameters and it will output
your application registration or you can set an environment variable that will
set the display name of your application registration.


