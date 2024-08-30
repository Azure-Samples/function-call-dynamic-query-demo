# Known Limitations and possible workarounds

## GithuB Actions

You may deploy this repo via Github Actions, but due to limitations with identity management in the current state, it will fail when it reaches the post provision step of the pipeline. The post provision step of the pipeline grants the user assigned managed identity the roles necessary to execute select commands on the Azure SQL Database.

The reason this fails is due to how azd will authenticate to Azure SQL. `azd` will attempt to authenticate using the credentials for the service principal of the Github Action runner. As this service principal does not have the appropriate permissions to execute any commands on the database, the pipeline will fail.

There are two ways you can solve this problem:

1) Remove the postprovision hook in the azure.yaml file and manually add the user-assigned-managed-identity name and the permissiosn on the database after the resources have been provisioned.

2) Remove the postprovision hook in the azure.yaml file and adjust the main.bicep file to assign the external administrator by passing the name an the PrincipalID of the user-assigned managed identity.

> [!NOTE]
> In practical situations, it is *not* recommended to give a UAMI exclusive admin rights to your database.W
