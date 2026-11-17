# `modules/avd-hybrid`

Prepares the Azure control-plane resources for **Azure Virtual Desktop Hybrid** (on-premises
session hosts connected through Azure Arc on Nutanix AHV, VMware vSphere, Hyper-V, or physical
Windows Server):

- **Arc host resource group**: Creates (or reuses) the resource group that holds Arc-enabled
  on-premises session hosts.
- **AVD Hybrid host pool (`SystemAssigned` managed identity)**: Creates a standard AVD host pool
  with `start_vm_on_connect = false` and grants its managed identity **`Reader`** on the Arc
  resource group (required by Microsoft AVD Hybrid).
- **Arc & Nerdio RBAC**: Grants Nerdio Manager's service principal **`Azure Connected Machine
  Resource Administrator`** and optionally grants an Arc onboarding service principal **`Azure
  Connected Machine Onboarding`** on the Arc resource group.
- **Application group & workspace**: Creates the Desktop application group and workspace ready for
  user assignment.

## Platform support notes

- **Nutanix AHV**: Nerdio Manager for Enterprise (NME 8.2+) documents AVD Hybrid provisioning and
  image management against Prism Central (`pc.7.3`+, AOS `7.3`+, AHV `10.3`+, TCP `9440` over
  VPN or ExpressRoute, AD DS domain-joined hosts). Pair with `modules/network` using
  `connectivity_mode = "hub_peering"` + `use_remote_gateways = true` (or `connectivity_mode = "vwan"`)
  so Nerdio Manager's `app_integration` subnet can reach on-premises Prism Central (`9440`) or
  vCenter (`443`) over the hub VPN/ExpressRoute gateway.
- **VMware vSphere, Hyper-V, physical Windows Server**: Supported by Microsoft AVD Hybrid via the
  guest Azure Arc agent + AVD Hybrid extension. Nerdio's marketing page lists VMware vSphere,
  though NME help documentation covers Nutanix AHV only as of October 2026.
- **Manual Nerdio console step**: Linking Prism Central / vCenter and importing or managing hybrid
  host pools in NME happens in the Nerdio console until `nerdio/nme` exposes AVD Hybrid resources.
- **OS limits**: Windows Server 2016–2025 (AD DS or hybrid join) and Windows 10/11 Enterprise
  single-session are supported; Windows 10/11 multi-session and Azure autoscale are not supported
  on AVD Hybrid (use `modules/azure-local` for Azure Local / multi-session HCI).
