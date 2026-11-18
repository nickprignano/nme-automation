provider "azurerm" {
  features {}
}

provider "azapi" {}

module "avd_hybrid" {
  source = "../../modules/avd-hybrid"

  name_prefix                        = var.name_prefix
  location                           = var.location
  hypervisor                         = var.hypervisor
  nerdio_service_principal_object_id = var.nerdio_service_principal_object_id
}
