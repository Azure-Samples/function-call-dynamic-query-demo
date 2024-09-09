# Text to Query for Azure SQL using OpenAI Function Call

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/Azure-Samples/rag-postgres-openai-python)
[![Open in Dev Containers](https://img.shields.io/static/v1?style=for-the-badge&label=Dev%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/azure-samples/rag-postgres-openai-python)

This project creates a backend that can use OpenAI chat models that support the [function calling](https://platform.openai.com/docs/guides/function-calling) ability to answer questions about your Azure SQL Database.
It does this by first identifying if the user query is asking about an internal data source (in this case, it is Azure SQL), if it does, then the application generates a SQL query from the users prompt, connects to the database via user assigned manage identity, executes that query, and relates it back to the user in JSON Format. The flow of this application can be seen using the below diagram.

* [Features](#features)
* [Getting started](#getting-started)
  * [GitHub Codespaces](#github-codespaces)
  * [VS Code Dev Containers](#vs-code-dev-containers)
  * [Local environment](#local-environment)
* [Deployment](#deployment)
  * [Github Actions](#github-actions)
* [Costs](#costs)
* [Security guidelines](#security-guidelines)

![Diagramn of application flow](docs/screenshot_chat.png)

## Features

This project is designed for deployment via the Azure Developer CLI, hosting the backend on Azure Web Apps, the database being Azure SQL, and the models that support function calling in Azure OpenAI. This demo leverges the ["AdventureWorks"](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver16&tabs=ssms) Sample Database.

* Conversion of user queries into Azure SQL that can be executed
* Generate results from your internal Azure SQL database based on user queries
* Enforce only read queries to the database
* Ask questions like "What are the top 3 products we have?", "What is the cost associated with product HL Road Frame - Black, 58?" , "How many red products do we have?" & more!

## Schema Detection & Understanding

This project leverages GPT-4o to generate the SQL query for the database. The model has contextual understanding of the `SalesLT.Customer` & `SalesLT.Product` tables. This is done by injecting the schema information of these tables as part of the prompt.

To have more understanding of the tables contents. Please login to your Azure SQL Database, and look through these tables.

> [!NOTE]
> Further developments of this repository will include automatic schema detections for accessible tables in the Azure SQL Database

## Getting Started

### GitHub Codespaces

You can run this template virtually by using GitHub Codespaces. The button will open a web-based VS Code instance in your browser:

1. Open the template (this may take several minutes):

    [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/Azure-Samples/rag-postgres-openai-python)

2. Open a terminal window
3. Continue with the [deployment steps](#deployment)

### VS Code Dev Containers

A related option is VS Code Dev Containers, which will open the project in your local VS Code using the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers):

1. Start Docker Desktop (install it if not already installed)
2. Open the project:

    [![Open in Dev Containers](https://img.shields.io/static/v1?style=for-the-badge&label=Dev%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/Azure-Samples/function-call-dynamic-query-demo)

3. In the VS Code window that opens, once the project files show up (this may take several minutes), open a terminal window.
4. Continue with the [deployment steps](#deployment)

### Local Environment

1. Make sure the following tools are installed:

    * [Azure Developer CLI (azd)](https://aka.ms/install-azd)
    * [Python 3.10+](https://www.python.org/downloads/)
    * [Git](https://git-scm.com/downloads)
    * [ODBC Driver 18](https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server?view=sql-server-ver16)

2. Clone the repository to your local machine

3. Open the project folder

4. Create a Python virtual environment and activate it.

5. Install required Python packages and backend application:

    ```shell
    pip install -r requirements-dev.txt
    pip install -e app
    ```

6. Continue with the [deployment steps](#deployment) below.

## Deployment

Once you've opened the project, you can deploy it to Azure.

1. Sign in to your Azure account:

    ```shell
    azd auth login
    ```

    If you have any issues with that command, you may also want to try `azd auth login --use-device-code`.

2. Create a new azd environment:

    ```shell
    azd env new
    ```

    This will create a folder under `.azure/` in your project to store the configuration for this deployment. You may have multiple azd environments if desired.

    You will be asked to select the location of which the resource will be provisioned. You will have the option between 3 options due to model availability.

3. Configure your environment variables that will be used for deployment:

    > [!IMPORTANT]
    > This project code uses passwordless authentication with the Azure SQL server, but it doesn't currently turn off SQL password auth entirely, due to an issue with Bicep-based deployments. The username is set to a unique string, and the password is set to an auto-generated value. Once deployed, you can disable SQL password auth via the Azure portal.

    For the passwordless authentication to be properly set up, you must set the principal name of the external administrator (UPN). If you need help finding this value, please login with the Azure CLI, add an .env file to the root directory and run the script: [./scripts/fetch-principal-info.sh](./scripts/fetch-principal-info.sh) or [./scripts/fetch-principal-info.ps1](scripts/fetch-principal-info.ps1). The values should appear in the terminal and in the `.env`file in the root directory.

    Once you know your principal name, set it as an azd environment variable:

    ```shell
    azd env set AZURE_PRINCIPAL_NAME yourprincipalname
    ```

4. Deploy the resources:

    ```shell
    azd up
    ```

> [!NOTE]
> If you are running this project via Github Codespaces. You may encounter an error during the post provisioning step.
> If this occurs, please run the following command `sudo apt --fix-broken install`

### Github Actions

If you wish to deploy this project via Github Actions, you will find a working azure-dev.yaml file in the [.github\workflows](./.github/workflows/azure-dev.yml).
More information on the limitations and workarounds for using this deployment method can be found in the [/docs](docs/limitations.md)

## Accessing the API documentation

After all the resources have been provisioned and the deployment is complete, head to the endpoint the App Service created.
You will be directed to a root entry point for the backend.

### Opening the API documentation

To test the APIs, please add `docs` to the end of the url.

> [!NOTE]
> For example, if your endpoint is: `https://testing-function-call-demo-example-webapp.azurewebsites.net`
> To test the endpoint, you must add `docs` at the end of this url, so the new url would be:
> `https://testing-function-call-demo-example-webapp.azurewebsites.net/docs`

### Testing the APIs

Use the Swagger UI to explore and test the available APIs.

You will have the ability to test 2 APIs:

1) `execute_query` API which will take as input, a SQL command to execute on the Azure SQL Database.
2) `ask` API which will take a user message, convert it to a SQL Command using OpenAI, and execute the query against the database which will return the result in JSON format.

## Costs

Pricing may vary per region and usage. Exact costs cannot be estimated.
You may try the [Azure pricing calculator](https://azure.microsoft.com/pricing/calculator/) for the resources below:

* Azure Web Apps: costs are based on the CPU, memory and storage resources you use. You can set the appServiceSkuName parameter in the main.parameters.json file to the sku of your choosing. Additional features like custom domains, SSL certificates and backups may incur additional charges.[Pricing](https://azure.microsoft.com/en-us/pricing/details/app-service/windows/)
* Azure OpenAI: Standard tier, GPT and Ada models. Pricing per 1K tokens used, and at least 1K tokens are used per question. [Pricing](https://azure.microsoft.com/pricing/details/cognitive-services/openai-service/)
* Azure SQL: This project leverage the “General Purpose - Serverless: Gen5, 1 vCore” sku with the adventureworks database. The cost depends on the compute costs and storage costs associated with the project. [Pricing](https://azure.microsoft.com/en-us/pricing/details/azure-sql-database/single/)
* Azure Monitor: Pay-as-you-go tier. Costs based on data ingested. [Pricing](https://azure.microsoft.com/pricing/details/monitor/)

## Security guidelines

This template uses [Managed Identity](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview) for authenticating to the Azure services used (Azure OpenAI, Azure SQL Server).

Additionally, we have added a [GitHub Action](https://github.com/microsoft/security-devops-action) that scans the infrastructure-as-code files and generates a report containing any detected issues. To ensure continued best practices in your own repository, we recommend that anyone creating solutions based on our templates ensure that the [Github secret scanning](https://docs.github.com/code-security/secret-scanning/about-secret-scanning) setting is enabled.
