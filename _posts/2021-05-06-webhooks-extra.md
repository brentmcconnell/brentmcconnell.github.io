---
layout: post
title: Webhook and Alert Learnings
date: 2021-05-06
summary: |
 In this post I'll look at a few of the learnings from the last 2 posts that
 were not documented very well in Microsoft documentation and hopefully speed 
 your understanding of a few topics dealing with webhooks and alerts
tags: azure techtips
categories:
  - Tech Tips
  - Azure
---

In the last 2 posts we looked at building an Azure Automation that would shutdown
VMs that were underutilized using runbooks, alerts and webhooks.  There was
quite a lot of information packed into those posts and in this post I want
to unpack a few learnings I discovered along the way and explain them
a bit better than perhaps the Microsoft documentation does.

## Tip 1: Alerts Can Use Different Schemas in Azure
Some of you probably picked up on this when looking over the code from [Part
1]({% post_url 2021-03-18-autoshutdown %}) but there are several different
schemas at play across different alert systems in Azure.  In that post I used
the __AzureMonitorMetricAlert__ schema but there is also the
__AzureMonitorCommonAlertSchema__, __Microsoft.Insights/activityLogs__ and the
original __Metric Alert__ schema.  This can make parsing the HTTP RequestBody a bit of a
hassle if you don't know what system is calling your runbook.  You can learn a bit
more in the
[documentation](https://docs.microsoft.com/en-us/azure/automation/automation-cre
ate-alert-triggered-runbook#create-a-runbook-to-handle-alerts). Each of these
schemas are similar but different so if you are trying to grab the VM name or
resource group name you may have to use different logic depending on the schema
being used.

For those of you that may have setup action groups to call runbooks in the
Azure portal you may have noticed a note when configuring the runbook.

> info "The Info Header"
> If this action is a user runbook and you are changing the schema type then you
> may need to adjust the user runbook to handle the new schema type.  If this
> action is a built-in runbook then you can choose any schema type and the
> built-in runbook is already able to process it.

That note kind of sums up Tip 1 = __Know what schema is calling your runbook__

## Tip 2: Fired Alerts Don't Get Resolved Unless the System Resolves Them
This may make tons of sense to some of you but it didn't to me right away and
that was one of the reasons I stress that to get the signals and criteria
correctily set for automatic shutdown may take some trial and error.  Signals
like "Average CPU" are monitored against a criteria you set.  In the last
post we used __less than 5% average CPU usage over 15 minutes__ as our criteria.  If that criteria
is met the alert will fire and move into a "Fired" state, our webhook is called
and the VM shuts down.  All is good.  But when the VM is restarted the alert
stays in the __Fired__ state until Azure Monitor resolves the alert.  __This
happens when a least one of the conditions specified in your criteria is not
longer met for 3 consecutive periods__.  What does this mean?  It means just by
turning on your stopped VM the alert is __not__ going to be reset unless you have
tweaked your signal and alert criteria to somehow catch the activity a VM goes
through on startup.  Otherwise your VM will need to do some kind of work in
order for Azure Monitor to __Resolve__ the alert.  Once the alert is in a
__Resolved__ state it will then be ready to start monitoring your criteria again
for shutdown.

In most real world scenarios this probably would work very well but as I was
writing the last post and testing things out I would typically have to run a
bit of a workload on my test VM to get the alert to resolve.  There is no
programmatic way for the alert to be resolved.  Again, in the real
world this probably works as expected.  You bring the VM up do some work and
that work would normally resolve your fired alert but if you are testing alerts
for the first time you should be aware of the need to __resolve__ the alert
before it will fire again. 

## Tip 3: Runbooks are Executed Whenever an Alert is Fired or Resolved
This makes a lot of sense after you recognize it is happening but it caught me
off-guard.  You expect the runbook to be executed when an alert is moved into
the __Fired__ state but I didn't expect my runbook to be executed when it moved
to the __Resolved__ state. Again this makes loads of sense in retrospect but
didn't initially.  You need to add a bit of logic to your runbook that checks
the status of the incoming alert. The runbook we created in the last post
actually checks for a status of __Fired__ before calling the logic to shutdown
the VM.  If you didn't have that logic check in your runbook it would shutdown
your VM when the alert switched to __Resolved__ as well as when it moves to
__Fired__.  

This actually makes loads of sense since you may want to have actions that you
take when your alert resolves just like you would when it fires but again it
caught me off guard and was shutting down my VM when it alert moved from
__Fired__ to __Resolved__ so be aware.

## Tip 4: Webhooks Need Additional Security
If you were paying attention in the last post you can see that anyone could call
our webhook URL and if they passed the right bit of JSON to our webhook URL they
could shutdown our VM.  Probably not what you want.  The Webhook documentation
calls this out ...

> The security of a webhook relies on the privacy of its URL, which contains a
> security token that allows the webhook to be invoked.  Azure Automation does
> not perform any authentication on a request as long as it is made to the
> correct URL.  For this reason, your clients should not use webhooks that
> perform sensitive operations without using an alternate means of validating
> the request.

__Consider the following strategies: (From the MSFT docs)__

1. You can include logic within a runbook to determine if it is called by a
webhook. Have the runbook check the WebhookName property of the WebhookData
parameter. The runbook can perform further validation by looking for particular
information in the RequestHeader and RequestBody properties.

1. Have the runbook perform some validation of an external condition when it
receives a webhook request. For example, consider a runbook that is called by
GitHub any time there's a new commit to a GitHub repository. The runbook might
connect to GitHub to validate that a new commit has occurred before continuing.

1. Azure Automation supports Azure virtual network service tags, specifically
GuestAndHybridManagement. You can use service tags to define network access
controls on network security groups or Azure Firewall and trigger webhooks from
within your virtual network. Service tags can be used in place of specific IP
addresses when you create security rules. By specifying the service tag name
GuestAndHybridManagement in the appropriate source or destination field of a
rule, you can allow or deny the traffic for the Automation service. This service
tag does not support allowing more granular control by restricting IP ranges to
a specific region.

