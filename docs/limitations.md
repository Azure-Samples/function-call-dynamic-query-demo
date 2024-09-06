# Known Limitations and possible workarounds

## Github Actions

You may deploy this repo via Github Actions, but due to limitations with identity management in the current state, it will fail when it reaches the post provision step of the pipeline. The post provision step of the pipeline grants the user assigned managed identity the roles necessary to execute select commands on the Azure SQL Database.

The reason this fails is due to how azd will authenticate to Azure SQL. `azd` will attempt to authenticate using the credentials for the service principal of the Github Action runner. As this service principal does not have the appropriate permissions to execute any commands on the database, the pipeline will fail.

Here is how you can resolve this problem:

1) Remove the postprovision hook in the azure.yaml file and manually add the user-assigned-managed-identity `principalname` and `princiapalid` in the main.bicep file located in `infra/main.bicep` explicitly mentioning aad_admin_name & aad_admin_objectid parameters as: `managedIdentity.outputs.managedIdentityName` and `managedIdentity.outputs.managedIdentityPrincipalId` respectively.

> [!NOTE]
> In practical situations, it is *not* recommended to give a UAMI exclusive admin rights to your database.
