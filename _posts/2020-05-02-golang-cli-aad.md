---
layout: post
title: Authenticate GO CLI with Azure AD 
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
your application registration or you can set the environment variable
APPREG_DISPLAY_NAME that will set the display name of your application registration.

```terminal
>> export APPREG_DISPLAY_NAME==your-app-reg-name
>> ./aad.sh
```

This will create an application registration and service principal with the same
id with the following permissions:

* Azure Service Management
  * user_impersonation
* Azure Storage
  * user_impersonation
* Microsoft Graph
  * openid
  * profile
  * User.Read

__NOTE:__ This will require an Azure Admin's approval before the application registration can be
used.  It really depends on what level of permission the user using the
application registration has.  If they are an admin they can provide admin
consent when they use the application registration for the first time or they
can visit the Azure portal or use the az cli.  However, Admin consent
will be necessary.

Using the stdout from the ./aad.sh script at the end you can now run the
goazuresample program you compiled using "go build".

Assuming you have the ability to provide Admin consent to an application
registration your workflow would look something like this:

```terminal
>> export APPREG_DISPLAY_NAME==your-app-reg-name
>> ./aad.sh
...
...
APPID:                a6fa0XXX-ZZZZ-4f96-0000-63bbcc1f1aa8
TENANTID:             4c52aXXX-ZZZZ-4730-1111-c041dd761629
SUBSCRIPTIONID:       97addXXX-ZZZZ-4e7f-2222-0daaeec2f720
APPREG_DISPLAY NAME:  brentmcconnellapp

>> az ad app permission admin-consent --id a6fa0XXX-ZZZZ-4f96-0000-63bbcc1f1aa8
>>
>>
>> ./goazuresample \
>>   --subid 97addXXX-ZZZZ-4e7f-2222-0daaeec2f720 \
>>   --tenantid 4c52aXXX-ZZZZ-4730-1111-c041dd761629 \
>>   --appid a6fa0XXX-ZZZZ-4f96-0000-63bbcc1f1aa8

11:22:48: To sign in, use a web browser via https://microsoft.com/devicelogin and enter BXX25QWKT to authenticate.
11:23:17: Created group: Quickstart-RG
11:23:17: Creating storageAcct1: acct033865

11:23:36: Completed storage creation acct033865: Succeeded
11:23:36: Getting access key1 for acct033865
11:23:37: Completed storage container creation cont033865 
11:23:37: Uploading file with blob name: file-033865

Do you want to delete the Resource Group Quickstart-RG [y/n]:n
11:24:06: Leaving Resource Group: Quickstart-RG
11:24:06: All Done!  Thanks for playing.
```

And that's it you've created a command line application in Golang that uses
Azure AD for authentication!


