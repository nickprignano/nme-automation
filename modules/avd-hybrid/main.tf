# Azure-side landing zone for Azure Virtual Desktop Hybrid (Arc-enabled on-premises session hosts
# on Nutanix AHV, VMware vSphere, Hyper-V, or physical Windows Server).

locals {
  arc_rg_name = coalesce(var.arc_resource_group_name, "rg-${var.name_prefix}-avd-hybrid-arc")
  arc_rg_id   = var.existing_arc_resource_group_id != null ? var.existing_arc_resource_group_id : azurerm_resource_group.arc[0].id
  arc_rg_ref  = var.existing_arc_resource_group_id != null ? split("/", var.existing_arc_resource_group_id)[4] : azurerm_resource_group.arc[0].name

  pool_name = coalesce(var.host_pool_name, "vdpool-${var.name_prefix}-hybrid")
  lb_type   = var.host_pool_type == "Personal" ? "Persistent" : var.load_balancer_type

  tags = merge(var.tags, {
    "avd-hybrid-hypervisor" = var.hypervisor
  })
}

resource "azurerm_resource_group" "arc" {
  count    = var.existing_arc_resource_group_id == null ? 1 : 0
  name     = local.arc_rg_name
  location = var.location
  tags     = local.tags
}

# azurerm_virtual_desktop_host_pool does not yet expose the ARM identity block required by AVD Hybrid.
resource "azapi_resource" "host_pool" {
  type      = "Microsoft.DesktopVirtualization/hostPools@2024-04-03"
  name      = local.pool_name
  location  = var.location
  parent_id = local.arc_rg_id
  tags      = local.tags

  # AVD Hybrid requires a managed identity on the host pool with Reader on the Arc resource group.
  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      hostPoolType                  = var.host_pool_type
      loadBalancerType              = local.lb_type
      preferredAppGroupType         = "Desktop"
      maxSessionLimit               = var.host_pool_type == "Pooled" ? var.maximum_sessions_allowed : null
      personalDesktopAssignmentType = var.host_pool_type == "Personal" ? var.personal_desktop_assignment_type : null
      customRdpProperty             = var.custom_rdp_properties
      validationEnvironment         = false
      startVMOnConnect              = false
    }
  }
}

resource "azurerm_role_assignment" "host_pool_arc_reader" {
  scope                = local.arc_rg_id
  role_definition_name = "Reader"
  principal_id         = azapi_resource.host_pool.identity[0].principal_id
}

resource "azurerm_role_assignment" "nerdio_arc_machine_admin" {
  scope                = local.arc_rg_id
  role_definition_name = "Azure Connected Machine Resource Administrator"
  principal_id         = var.nerdio_service_principal_object_id
}

resource "azurerm_role_assignment" "arc_onboarding" {
  count                = var.onboarding_principal_id != null ? 1 : 0
  scope                = local.arc_rg_id
  role_definition_name = "Azure Connected Machine Onboarding"
  principal_id         = var.onboarding_principal_id
}

resource "azurerm_virtual_desktop_application_group" "this" {
  name                = "vdag-${var.name_prefix}-hybrid"
  location            = var.location
  resource_group_name = local.arc_rg_ref
  type                = "Desktop"
  host_pool_id        = azapi_resource.host_pool.id
  friendly_name       = "Hybrid Desktop (${var.hypervisor})"
  tags                = local.tags
}

resource "azurerm_virtual_desktop_workspace" "this" {
  name                = "vdws-${var.name_prefix}-hybrid"
  location            = var.location
  resource_group_name = local.arc_rg_ref
  friendly_name       = "AVD Hybrid Workspace"
  tags                = local.tags
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "this" {
  workspace_id         = azurerm_virtual_desktop_workspace.this.id
  application_group_id = azurerm_virtual_desktop_application_group.this.id
}
