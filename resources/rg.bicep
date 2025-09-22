// Parameters for resource group deployment
param resourceGroupName string
param location string
param tags object = {}

// Target scope for resource group deployment
targetScope = 'subscription'

// Resource group definition
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Outputs
output resourceGroupId string = resourceGroup.id
output resourceGroupName string = resourceGroup.name
output location string = resourceGroup.location
