variable "name_prefix" {
  description = "Short prefix for AVD Hybrid resource names."
  type        = string
}

variable "location" {
  description = "Azure region for the Arc host resource group and AVD control-plane objects."
  type        = string
}

variable "hypervisor" {
  description = "On-premises platform hosting the Arc-enabled session hosts: nutanix_ahv (Nerdio Manager 8.2+ documented), vmware_vsphere, hyper_v, or physical."
  type        = string
  default     = "nutanix_ahv"

  validation {
    condition     = contains(["nutanix_ahv", "vmware_vsphere", "hyper_v", "physical"], var.hypervisor)
    error_message = "hypervisor must be one of: nutanix_ahv, vmware_vsphere, hyper_v, physical."
  }
}

variable "arc_resource_group_name" {
  description = "Name of the Azure resource group that holds Arc-enabled hybrid session hosts (defaults to rg-<name_prefix>-avd-hybrid-arc)."
  type        = string
  default     = null
}

variable "existing_arc_resource_group_id" {
  description = "Optional ARM resource ID of an existing resource group for Arc-enabled hybrid session hosts. When set, the module skips creating a new resource group."
  type        = string
  default     = null
}

variable "host_pool_name" {
  description = "Name of the AVD Hybrid host pool (defaults to vdpool-<name_prefix>-hybrid)."
  type        = string
  default     = null
}

variable "host_pool_type" {
  description = "AVD host pool type: Pooled or Personal."
  type        = string
  default     = "Pooled"

  validation {
    condition     = contains(["Pooled", "Personal"], var.host_pool_type)
    error_message = "host_pool_type must be Pooled or Personal."
  }
}

variable "load_balancer_type" {
  description = "Load balancer type for the AVD Hybrid host pool: BreadthFirst, DepthFirst, or Persistent (use Persistent for Personal pools)."
  type        = string
  default     = "BreadthFirst"

  validation {
    condition     = contains(["BreadthFirst", "DepthFirst", "Persistent"], var.load_balancer_type)
    error_message = "load_balancer_type must be BreadthFirst, DepthFirst, or Persistent."
  }
}

variable "maximum_sessions_allowed" {
  description = "Maximum concurrent sessions per host for Pooled Windows Server hybrid host pools (ignored when host_pool_type is Personal)."
  type        = number
  default     = 10
}

variable "personal_desktop_assignment_type" {
  description = "Assignment type when host_pool_type is Personal: Automatic or Direct."
  type        = string
  default     = "Automatic"

  validation {
    condition     = contains(["Automatic", "Direct"], var.personal_desktop_assignment_type)
    error_message = "personal_desktop_assignment_type must be Automatic or Direct."
  }
}

variable "custom_rdp_properties" {
  description = "Custom RDP properties for the AVD Hybrid host pool (for example, targetisaadjoined:i:1; for Entra-joined Windows 11 single-session hosts)."
  type        = string
  default     = null
}

variable "nerdio_service_principal_object_id" {
  description = "Object ID of Nerdio Manager's service principal to grant Azure Connected Machine Resource Administrator on the Arc host resource group."
  type        = string
}

variable "onboarding_principal_id" {
  description = "Optional Entra object ID of the service principal or managed identity used to onboard on-premises VMs to Azure Arc (granted Azure Connected Machine Onboarding on the Arc resource group)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all AVD Hybrid Azure resources."
  type        = map(string)
  default     = {}
}
