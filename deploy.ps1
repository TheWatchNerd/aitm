<#!
.SYNOPSIS
	Unified deployment helper for the AI Threat Monitoring sample (anonymized).

.DESCRIPTION
	Provides an interactive menu to:
	  1. Create or update the infrastructure resource group (RG template)
	  2. Deploy / update the Log Analytics custom table (separate workspace RG)
	  3. Deploy / update the main automation stack (Logic App, DCR, Identity, Storage, Connection)

	Script intentionally avoids embedding environment‑specific names so it can be published publicly.
	Adjust defaults below or pass parameters explicitly / via prompts.

.REQUIREMENTS
	- Az PowerShell modules (Az.Accounts, Az.Resources, Az.OperationalInsights) installed
	- Sufficient RBAC permissions (Owner/Contributor + Log Analytics Data Collection Rule Data Sender role assignment logic handled in Bicep)
	- Bicep files present in current directory structure

.PARAMETER SubscriptionId
	(Optional) Subscription to target. If omitted, current context subscription is used after login.

.PARAMETER Location
	Azure region short name (matches bicep defaults; used when creating RG at subscription scope).

.PARAMETER InfraRgName
	Name of infrastructure resource group (where main stack will be deployed).

.PARAMETER WorkspaceRgName
	Resource group that holds the existing Log Analytics workspace + custom table.

.PARAMETER WorkspaceCustomTableTemplate
	Path to custom table bicep file.

.PARAMETER MainTemplate
	Path to main orchestration bicep file.

.PARAMETER MainParametersFile
	Path to parameters file for main template.

.PARAMETER RgTemplate
	Subscription-scope Bicep template used to create resource groups (if you keep rg.bicep). Optional.

.NOTES
	Publish-safe: no hard-coded tenant, subscription, or RG names. Replace defaults as needed.
	For CI automation, you can bypass the menu by calling the functions directly.
#>
param(
	[string] $SubscriptionId,
	[string] $Location = 'westeurope',
	[string] $InfraRgName = 'rg-sample-infra',
	[string] $WorkspaceRgName = 'rg-sample-security',
	[string] $RgTemplate = '.\\rg.bicep',
	[string] $WorkspaceCustomTableTemplate = '.\\resources\\custom-table.bicep',
	[string] $MainTemplate = '.\\main.bicep',
	[string] $MainParametersFile = '.\\main.parameters.json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Section {
	param([string] $Text)
	Write-Host "`n==== $Text ====\n" -ForegroundColor Cyan
}

function Ensure-AzContext {
	if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
		throw 'Az PowerShell modules not installed. Install-Module Az -Scope CurrentUser'
	}
	$ctx = Get-AzContext -ErrorAction SilentlyContinue
	if (-not $ctx) {
		Write-Host 'Logging in...' -ForegroundColor Yellow
		Connect-AzAccount -UseDeviceAuthentication | Out-Null
	}
	if ($SubscriptionId) {
		Write-Host "Setting subscription context: $SubscriptionId" -ForegroundColor Yellow
		Set-AzContext -Subscription $SubscriptionId | Out-Null
	}
}

function Invoke-CreateResourceGroupInfra {
	Write-Section 'Create / Update Resource Group(s)'
	if (-not (Test-Path $RgTemplate)) {
		Write-Warning "RG template '$RgTemplate' not found. Skipping."
		return
	}
	Write-Host "Deploying subscription-scope template to create RG(s) in $Location" -ForegroundColor Green
	New-AzSubscriptionDeployment -Location $Location -TemplateFile $RgTemplate -Verbose
	Write-Host 'Subscription-scope deployment completed.' -ForegroundColor Green
}

function Invoke-DeployCustomTable {
	Write-Section 'Deploy Custom Table'
	if (-not (Test-Path $WorkspaceCustomTableTemplate)) {
		throw "Custom table template not found at $WorkspaceCustomTableTemplate"
	}
	Write-Host "Deploying custom table to workspace RG: $WorkspaceRgName" -ForegroundColor Green
	New-AzResourceGroupDeployment -ResourceGroupName $WorkspaceRgName -TemplateFile $WorkspaceCustomTableTemplate -Verbose
	Write-Host 'Custom table deployment complete.' -ForegroundColor Green
}

function Invoke-DeployAutomationLogic {
	Write-Section 'Deploy Main Automation Stack'
	if (-not (Test-Path $MainTemplate)) { throw "Main template not found at $MainTemplate" }
	if (-not (Test-Path $MainParametersFile)) { throw "Parameters file not found at $MainParametersFile" }
	Write-Host "Deploying main stack to RG: $InfraRgName" -ForegroundColor Green
	New-AzResourceGroupDeployment -ResourceGroupName $InfraRgName -TemplateFile $MainTemplate -TemplateParameterFile $MainParametersFile -Verbose
	Write-Host 'Main stack deployment complete.' -ForegroundColor Green
}

function Show-Menu {
	Write-Host "Select an action:" -ForegroundColor Cyan
	Write-Host "  1) Create Resource Group(s)" -ForegroundColor Gray
	Write-Host "  2) Deploy Custom Table" -ForegroundColor Gray
	Write-Host "  3) Deploy Automation Logic" -ForegroundColor Gray
	Write-Host "  4) Exit" -ForegroundColor Gray
	$choice = Read-Host 'Enter choice (1-4)'
	switch ($choice) {
		'1' { Invoke-CreateResourceGroupInfra }
		'2' { Invoke-DeployCustomTable }
		'3' { Invoke-DeployAutomationLogic }
		'4' { Write-Host 'Exiting.' -ForegroundColor Yellow; return $false }
		default { Write-Warning 'Invalid selection'; return $true }
	}
	return $true
}

Ensure-AzContext

while (Show-Menu) { }

Write-Host "Done." -ForegroundColor Cyan