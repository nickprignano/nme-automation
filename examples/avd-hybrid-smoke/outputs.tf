output "arc_resource_group_name" {
  description = "Name of the resource group holding Arc-enabled AVD Hybrid session hosts."
  value       = module.avd_hybrid.arc_resource_group_name
}

output "host_pool_id" {
  description = "ARM resource ID of the AVD Hybrid host pool."
  value       = module.avd_hybrid.host_pool_id
}

output "host_pool_principal_id" {
  description = "Principal ID of the AVD Hybrid host pool's system-assigned managed identity."
  value       = module.avd_hybrid.host_pool_principal_id
}
