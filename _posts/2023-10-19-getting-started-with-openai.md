---
layout: post
title: Getting Started with Azure OpenAI 
date: 2023-10-19
summary: |
  Artificial intelligence (AI) has become an integral part of modern software developmen.  In this post will take a peak at some of the new exciting features in Azure related to AI and help you get started. 
tags: azure techtips
categories:
  - Tech Tips
  - Azure
---

Artificial intelligence (AI) has become an essential part of modern software
development, and cloud providers like Microsoft Azure offer AI services to help
developers build intelligent applications.  In this blog post, we will explore how
to use Azure to deploy OpenAI models and take a few small steps to exploring its
potential.

## Solution
With Azure OpenAI leading the way many of my customers are looking to better
understand the power of Large Language Models (LLM) and Artifical Intelligence
(AI).  In this post we'll deploy an Azure OpenAI account and create a GPT
model that we can start testing in the Azure OpenAI Studio.

## Azure OpenAI Studio
Azure OpenAI Studio provides two different playgrounds for developers and data
scientists to experiment with OpenAI's language models: Chat playground and
Completions playground.

The Chat playground allows users to interact with OpenAI's GPT-3 (Generative
Pre-trained Transformer 3) model through a chat interface. Users can input a
prompt or question, and the GPT-3 model will generate a response based on its
understanding of the prompt and its vast knowledge of language and context. The
Chat playground is designed to showcase the conversational capabilities of GPT-3
and to help users understand how to use the model for chatbot and conversational
applications.

On the other hand, the Completions playground allows users to generate text
completions based on a given prompt. Users can input a sentence or phrase, and
the GPT-3 model will generate a completion based on its understanding of the
language and context. The Completions playground is designed to help users
experiment with GPT-3's text generation capabilities and to explore potential
use cases for the model in content creation, text summarization, and more.

In summary, the Chat playground and Completions playground in Azure OpenAI
Studio are two different tools for experimenting with OpenAI's GPT-3 language
model. The Chat playground is designed for conversational applications, while
the Completions playground is designed for text generation and completion. Both
playgrounds provide a user-friendly interface for developers and data scientists
to experiment with GPT-3 and explore its capabilities.
## Getting Started
### Apply for access to the Azure OpenAI Account

The first thing you'll need is access to the Azure OpenAI service.  Your
organizaiton may have already made this available to you but it can be also
be done via an application process that is usually is reviewed and approved
in a few days.  

If you try to create an Azure OpenAI service and see the following message you
can click on the link to complete and submit your application for access.
![Overview](/images/2023-10-19-getting-started-with-openai/openai-service-unavailable.png){:.shadow .outline}

Once your access has been approved you can come back and complete the
installation.

## Deploy Resources
### main.tf
In this example we'll use Terraform to deploy the model and for brevity I'll
assume the reader knows how to use Terraform to provision resources in Azure.

```terminal
provider "azurerm" {  
  features {}  
}  
  
resource "azurerm_resource_group" "openai" {  
  name     = "terraform-openai-rg"  
  location = "eastus"  
}  
  
resource "azurerm_cognitive_account" "ca" {  
  name                = "cognitive-account"  
  location            = azurerm_resource_group.openai.location  
  resource_group_name = azurerm_resource_group.openai.name  
  kind                = "OpenAI"  
  sku_name            = "S0"  
}  
  
resource "azurerm_cognitive_deployment" "example" {  
  name                  = "gpt-35-turbo"  
  cognitive_account_id  = azurerm_cognitive_account.ca.id  
  model {  
    format              = "OpenAI"  
    name                = "gpt-35-turbo"  
    version             = "0613"  
  }  
  
  scale {  
    type = "Standard"  
  }  
}  

```

### Terraform Explanation
1. Create a resource group to hold our OpenAI instance.
1. We then create an Azure Cognitive Account resource and specify the name, resource group, location, kind, and SKU (S0).
1. Finally, we create an Azure Cognitive Deployment resource and specify the name, cognitive account ID, model format, name, version, and scale type.

That's it! With this Terraform code, you can easily deploy a GPT-35-Turbo model
using your OpenAI account. By using Terraform, you can automate the deployment
process and easily manage your OpenAI resources.

## Using Azure OpenAI Studio

With Azure OpenAI Studio, users can easily create, train, and deploy AI models
using a drag-and-drop interface or code. The platform provides access to
state-of-the-art AI models from OpenAI, as well as tools for data preparation,
model training, and deployment.

### Getting Started With Azure OpenAI Studio
You now have everything you need to start experimenting with the powerful
features of Azure OpenAI.  When you open Azure OpenAI Studio you will already
have a model deployment created by Terraform.  You you browse "Deployments" in the left menu you will
see your model and information about it's capacity and limits.

![Overview](/images/2023-10-19-getting-started-with-openai/openai-deployments.png){:.shadow .outline}

### Chat Playground
Visit the Chat Playground by navigating to the "Chat" menu option in Azure
OpenAI Studio. You can also view the Completions Playground as well but be aware
the GPT 35 Turbo model doesn't support Completions so we'll focus on the Chat
Playground in this post.

Notice there are 3 sections for interacting with the model.

#### Assistant Setup
The Assistant Setup section provides users with a variety of tools to customize
their assistant, such as setting up intents, entities, and dialogues. Intents
are the user's intention or purpose in a conversation, while entities are the
specific pieces of information that the assistant needs to understand to fulfill
the user's request. Dialogues are the specific responses and actions that the
assistant takes based on the user's intent and entities.
   
#### Configuration
The Configuration Panel allows you to customize the way that Azure OpenAI
interacts with your session.  For instance Temperature and Top P are very important
setting to understand when dealing with Azure OpenAI.  Higher Temperature
settings will effectively make the model more creative but may introduce errors
into the responses (ie hallucinations).  Lower Temperatures will produce less
creative answers but should lower the chances of errors.  Each use case will
have it's place in business.  

For further information see [Learn How to Generate or Manipulate
Text](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/completions)

#### Chat session
This panel is where you can interact with the OpenAI model via chat.  You will
ask you questions in the lower text area and submit them to the model and then
based off the "prompt" and parameters applied to the model receive a response as
if you were interacting with someone on your team.

## Example
For a simple example we'll give the OpenAI model a System message (ie prompt) of
"You are a friendly pirate who likes to answer questions in a pirate accent".
Then press the "Save Changes" option near the top of the Assistant Setup
configuration panel.

Now in the Chat session you can ask someting like "Where is Boston?".  You
should see a response that seems like a friendly pirate might have answered :).

Let's try something else.  How about setting the System Message to something
like "You are a baseball player who can't stop talking about baseball" and then
ask the model "Where is Boston?".  At this you'll probably hear something about
Boston and baseball :).

## Conclusion
In conclusion, AI technology has the potential to revolutionize the way we live
and work. As we continue to develop and improve upon AI algorithms and systems,
we can expect to see further advancements in fields such as healthcare, finance,
and transportation. While there are certainly challenges to be addressed, such
as ethical concerns surrounding the use of AI, there is no denying that this
technology represents a tremendous opportunity for progress and innovation. As
we move forward, it is up to all of us to ensure that AI is developed and used
in a responsible, ethical manner that benefits society as a whole.

If you haven't already guessed parts of this blog was even done using a Chat
session... but I'll never tell which parts ;)

## Additional Resources
* [Azure OpenAI Service Documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/)
* [Quickstart for Azure OpenAI
Studio](https://learn.microsoft.com/en-us/azure/ai-services/openai/quickstart)
[Azure OpenAI Blogs](https://azure.microsoft.com/en-us/blog/tag/ai/)

