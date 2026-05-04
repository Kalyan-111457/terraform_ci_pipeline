variable "resource_group_name" {
  description = "The name of the resource group in which to create the virtual network."
  type        = string
}

variable "location" {
  description = "The Azure region where the virtual network will be created."
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