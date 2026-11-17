variable "name_prefix" {
  description = "Short prefix for AVD Hybrid resource names."
  type        = string
}

variable "location" {
  description = "Azure region for the Arc host resource group and AVD control-plane objects."
  type        = string
  default     = "centralus"
}

variable "hypervisor" {
  description = "On-premises platform hosting the Arc-enabled session hosts."
  type        = string
  default     = "nutanix_ahv"
}

variable "nerdio_service_principal_object_id" {
  description = "Object ID of the service principal granted Azure Connected Machine Resource Administrator on the Arc host resource group."
  type        = string
}
