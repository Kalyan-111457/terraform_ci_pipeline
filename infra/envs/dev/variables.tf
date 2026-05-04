variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "resource_group_location" {
  description = "The location of the resource group"
  type        = string
}

variable "address_space" {
  description = "The address space that is used by the virtual network."
  type        = list(string)
}

variable "vnet_name" {
  description = "The name of the virtual network."
  type        = string
}

variable "vnet_subnet_count" {
  description = "The number of subnets to create in the virtual network."
  type        = number
}


variable "network_security_group_rules" {
    type = list(object({
      priority =number
      destination_port_range = string 
    }))
    description = "this defines the network security rules"
}



variable "virtual_machine_count" {
    description = "The number of virtual machines."
    type        = number
}

variable "virtual_machine_size" {
    description = "The Azure VM size."
    type        = string
}


variable "Virual_machine_scale_set_name" {
    description = "The name of the virtual machine scale set."
    type        = string
}



