# CloudRadial CSA Automations


## Introduction ##

[CloudRadial CSA](https://www.cloudradial.com/csa) provides a Unified Client Portal(tm) to MSP and IT end users. One feature of this portal is a service catalog that allows the creation of custom forms to obtain the required information for a service ticket. Automations takes this concept to the next level by connecting these forms directly to automated tasks so that tickets can be processed without or with minimal human effort.

Azure Function apps provide an ideal way to automate tasks. They allow using PowerShell or other languages to interact with systems that provide an API. Fortunately, Microsoft 365, most ticketing systems, and even most IT tools allow API access.  

This repo is an open-source project to create and manage an Azure Function app with functions that can easily be connected to CloudRadial CSA automations. These automations can be invoked through CloudRadial CSA's service catalog directly by end-users or restricted to your technical team.

The repo is designed so it can forked and then connected directly to your Azure Function through its Deployment Center. This allows you to update the code in your repository, automatically republish the changes to Azure, and force an application restart with the updates. You can edit your code directly in Github or with tools like Visual Studio Code that can interact with Github repositories. The biggest benefit to VS Code is the ability to connect to GitHub Copilot, which can greatly improve productivity.

Sample functions in this repo include:

1. Creating a new 365 group
2. Adding a 365 user to a group
3. Removing a 365 user from a group
4. Creating a 365 user with licensing and group membership similar to another existing user
5. Adding a note to a ConnectWise ticket
6. Setting the status of a ConnectWise ticket
7. Generating a password and creating a PwPush password link
8. Updating CloudRadial tokens from 365 to create custom dropdowns for clients in Service Catalog forms
9. Generating a custom-formatted HTML email from the results of a previous function

These functions are designed to work together in sequence, such as:

1. Add a user to a 365 group
2. Add a note to a ticket with the result of adding a user
3. Set the ticket status to closed if the user was added successfully
4. Format an email to send to a user with the result

CloudRadial CSA automations allow you to to take the output of one step and feed it into the input of the next to make it easier to break apart functions to keep functions more concise. Of course, you can run anything you want in your own functions. These are just samples to get you started.


## PowerShell and Microsoft Authentication ##

One of the key benefits of these functions is the use of the PowerShell Core scripting language to perform all tasks. Except for user interactions, anything you can do in PowerShell can be replicated in an Azure Function and connected to a CloudRadial CSA Automation.

Even if you are unfamiliar with PowerShell or Microsoft Graph, Microsoft CoPilot is an expert. Starting a prompt with "Write a PowerShell script using the Microsoft Graph module to..." gets you started quickly.

These PowerShell scripts rely on an Azure App Registration in your tenant for access rights. Only the people you authorize in your tenant have access to your application, and you can grant or limit rights as your situation requires. App IDs and Secrets are managed as function environment variables that are inaccessible outside your Azure Function app unless you allow them.

Of course, there is no requirement that your Azure Function app be written in PowerShell. CloudRadial CSA automations can be connected to any Azure Function regardless of how it is scripted.


## Getting Started ##

![CloudRadialCsaAutomations](https://github.com/cloudradial/CloudRadialCsaAutomations/assets/53623810/0ea0a237-1191-40e3-a966-33ce0f26f8f3)

Using this repository, it should take less than an hour to get things set up and working in your CloudRadial CSA service catalog. Follow the steps below:

1. Create a new App Registration in Azure Entra ID and enable the necessary permissions following these steps: 
   
   [Creating a Microsoft Entra ID App Registration](https://support.cloudradial.com/hc/en-us/articles/24672319005460-Creating-a-Microsoft-Entra-ID-App-Registration-for-Azure-Function-Authentication). 
   
   For the functions in this repository, the App should have the following rights:

   1. User.Read.All
   2. Domain.Read.All
   3. Group.ReadWrite.All
   4. GroupMember.ReadWrite.All

2. Create a new Azure Function app and load the necessary PowerShell module following these steps:
   
   [Creating a PowerShell Azure Function App for Accessing Microsoft Graph](https://support.cloudradial.com/hc/en-us/articles/23679141297428-Creating-a-PowerShell-Azure-Function-App-for-Accessing-Microsoft-Graph).

3. Fork this repository into your own repository on GitHub
4. In your Azure Function app, connect your new repo to the Azure Function using the Deployment Center option using these steps:

   [Linking a GitHub Repository to an Azure Function App](https://support.cloudradial.com/hc/en-us/articles/24672817200916-Linking-a-GitHub-Repository-to-an-Azure-Function-App).

1. Use these functions in your CloudRadial CSA automations following these steps:

   [Triggering Azure Functions from Automations](https://support.cloudradial.com/hc/en-us/articles/23874657151764-Triggering-Azure-Functions-from-Automations)


## Developer Information ##

More information about the Microsoft.Graph module can be found at:

[https://learn.microsoft.com/en-us/powershell/microsoftgraph/?view=graph-powershell-1.0](https://learn.microsoft.com/en-us/powershell/microsoftgraph/?view=graph-powershell-1.0)

More information about the CloudRadial API can be found at: 

[https://developers.cloudradial.com](https://developers.cloudradial.com)
