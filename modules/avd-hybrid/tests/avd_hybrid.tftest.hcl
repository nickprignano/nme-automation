mock_provider "azurerm" {}
mock_provider "azapi" {}

variables {
  name_prefix                        = "contoso"
  location                           = "eastus2"
  nerdio_service_principal_object_id = "11111111-1111-1111-1111-111111111111"
}

run "pooled_nutanix_ahv_creates_rg_and_pool" {
  command = plan

  assert {
    condition     = length(azurerm_resource_group.arc) == 1 && azurerm_resource_group.arc[0].name == "rg-contoso-avd-hybrid-arc"
    error_message = "Should create the default Arc host resource group when existing_arc_resource_group_id is null."
  }

  assert {
    condition     = azapi_resource.host_pool.name == "vdpool-contoso-hybrid" && azapi_resource.host_pool.body.properties.hostPoolType == "Pooled" && azapi_resource.host_pool.body.properties.loadBalancerType == "BreadthFirst" && azapi_resource.host_pool.identity[0].type == "SystemAssigned"
    error_message = "Should create a Pooled BreadthFirst host pool with SystemAssigned managed identity."
  }

  assert {
    condition     = azurerm_role_assignment.host_pool_arc_reader.role_definition_name == "Reader" && azurerm_role_assignment.nerdio_arc_machine_admin.role_definition_name == "Azure Connected Machine Resource Administrator" && length(azurerm_role_assignment.arc_onboarding) == 0
    error_message = "Should assign Reader to the host pool identity and Arc Machine Admin to Nerdio, skipping onboarding RBAC when onboarding_principal_id is null."
  }
}

run "personal_vmware_vsphere_uses_persistent_and_existing_rg" {
  command = plan

  variables {
    hypervisor                     = "vmware_vsphere"
    host_pool_type                 = "Personal"
    existing_arc_resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing-arc"
    onboarding_principal_id        = "22222222-2222-2222-2222-222222222222"
  }

  assert {
    condition     = length(azurerm_resource_group.arc) == 0 && azapi_resource.host_pool.parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing-arc"
    error_message = "Should reuse existing_arc_resource_group_id instead of creating a new resource group."
  }

  assert {
    condition     = azapi_resource.host_pool.body.properties.hostPoolType == "Personal" && azapi_resource.host_pool.body.properties.loadBalancerType == "Persistent" && azapi_resource.host_pool.tags["avd-hybrid-hypervisor"] == "vmware_vsphere"
    error_message = "Personal pool should force Persistent load balancer and tag vmware_vsphere."
  }

  assert {
    condition     = length(azurerm_role_assignment.arc_onboarding) == 1 && azurerm_role_assignment.arc_onboarding[0].role_definition_name == "Azure Connected Machine Onboarding"
    error_message = "Should grant Azure Connected Machine Onboarding when onboarding_principal_id is set."
  }
}

run "rejects_invalid_hypervisor" {
  command = plan

  variables {
    hypervisor = "proxmox"
  }

  expect_failures = [
    var.hypervisor,
  ]
}
