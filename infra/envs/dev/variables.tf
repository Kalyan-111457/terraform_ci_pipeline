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

# Added for pipeline test
variable "pipeline_test_flag" {
  description = "Flag to test pipeline PR trigger."
  type        = bool
  default     = true
}
