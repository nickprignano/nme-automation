output "arc_resource_group_id" {
  description = "ARM resource ID of the resource group holding Arc-enabled AVD Hybrid session hosts."
  value       = local.arc_rg_id
}

output "arc_resource_group_name" {
  description = "Name of the resource group holding Arc-enabled AVD Hybrid session hosts."
  value       = local.arc_rg_ref
}

output "host_pool_id" {
  description = "ARM resource ID of the AVD Hybrid host pool."
  value       = azapi_resource.host_pool.id
}

output "host_pool_name" {
  description = "Name of the AVD Hybrid host pool."
  value       = azapi_resource.host_pool.name
}

output "host_pool_principal_id" {
  description = "Principal ID of the AVD Hybrid host pool's system-assigned managed identity (granted Reader on the Arc resource group)."
  value       = azapi_resource.host_pool.identity[0].principal_id
}

output "application_group_id" {
  description = "ARM resource ID of the AVD Hybrid Desktop application group."
  value       = azurerm_virtual_desktop_application_group.this.id
}

output "workspace_id" {
  description = "ARM resource ID of the AVD Hybrid workspace."
  value       = azurerm_virtual_desktop_workspace.this.id
}
