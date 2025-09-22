# AI Threat Monitoring Sample (Infrastructure as Code)

This repository deploys a sample Azure environment that:

1. Serves a warning image via an Azure Logic App (Consumption) pulling from a Storage Account (Blob container).
2. Captures inbound HTTP request headers and forwards them via the Logs Ingestion (Direct) Data Collection Rule (DCR) pipeline into a custom Log Analytics table.
3. Uses a user-assigned managed identity for secure access to Azure Blob Storage and for authenticated ingestion to Azure Monitor (Sentinel workspace).

## Components

- `main.bicep` Orchestrates Logic App, DCR (Direct), user-assigned identity, storage account + container, and API connection.
- `resources/dcr.bicep` Defines a Direct DCR with custom stream and mapping to the Log Analytics workspace.
- `resources/custom-table.bicep` (deploy separately) Creates the custom table with the required schema (including `TimeGenerated`).
- `resources/mi.bicep` Creates user-assigned managed identity + role assignments (DCR Data Sender, Storage Blob Data Reader).
- `resources/sa.bicep` Deploys storage account and public blob container for images.
- `resources/connection.bicep` Creates a managed-identity based Azure Blob API connection for the Logic App.
- `resources/logicapp.bicep` Deploys Logic App from external JSON definition (`logicappcode.json`) and injects dynamic values (ingestion URI, identity, storage account, connection).
- `deploy.ps1` Interactive deployment helper (menu driven) for RG creation, custom table deployment, and main stack deployment.

## Prerequisites

- PowerShell 7+ (recommended) with Az modules (`Install-Module Az`).
- Permissions: Ability to deploy at subscription scope and assign RBAC roles (Contributor or Owner).
- Existing Log Analytics workspace (name + resource group) referenced in parameter file.

## Deployment Order

1. (Optional) Create resource groups (if using `rg.bicep`).
2. Deploy the custom table (separate RG of the Log Analytics workspace):
	```powershell
	New-AzResourceGroupDeployment -ResourceGroupName <workspaceRg> -TemplateFile .\resources\custom-table.bicep -Verbose
	```
3. Deploy main stack (Logic App, DCR, identity, storage, connection):
	```powershell
	New-AzResourceGroupDeployment -ResourceGroupName <infraRg> -TemplateFile .\main.bicep -TemplateParameterFile .\main.parameters.json -Verbose
	```
4. Upload `warn.png` (or your image) to the specified blob container (default path `/images/warn.png`).
5. Edit custom.css and upload to Company Branding

## Using deploy.ps1 (Interactive)

```powershell
./deploy.ps1          # Shows menu
```
Menu options:
1. Create Resource Group(s)
2. Deploy Custom Table
3. Deploy Automation Logic (main stack)

You can pass overrides:
```powershell
./deploy.ps1 -SubscriptionId <subId> -InfraRgName rg-xyz-infra -WorkspaceRgName rg-xyz-sec -Location westeurope
```

## Custom Table Schema
Columns align with HTTP headers collected by the Logic App. `TimeGenerated` and `RawIngestionTime_t` are populated at ingestion time via the workflow body.

## Direct Ingestion URI Pattern

The Logic App dynamically constructs and injects:
```
https://<random>-<region>.ingest.monitor.azure.com/dataCollectionRules/<immutableId>/streams/<CustomStream>?api-version=2023-01-01
```
No hard-coded subscription IDs remain in workflow definition; placeholders are replaced during deployment.

## Parameterization

- Storage account name and custom stream name are injected.
- Managed identity resource ID used for both blob connection auth and Monitor ingestion.
- Replace values in `main.parameters.json` for each environment.

## Verifying Ingestion

After invoking the Logic App, query the table (example):
```kusto
aitm_CL
| take 50
```

## Clean Up

```powershell
Remove-AzResourceGroup -Name <infraRg> -Force
Remove-AzResourceGroup -Name <workspaceRg> -Force   # If this was a test workspace RG
```

## Next Steps (Not Included Yet)

- Add ingestion script examples (PowerShell & curl) to push synthetic events directly.
- Add header normalization (coalesce variants) if needed.
