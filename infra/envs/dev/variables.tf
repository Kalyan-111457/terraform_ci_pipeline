variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "resource_group_location" {
  description = "The location of the resource groupw"
  type        = string
}

variable "address_space" {
  description = "The address space that is used by the virtual network."
  type        = list(string)
}

variable "vnet_name" {
  description = "The name of the virtual networka."
  type        = string
}

variable "vnet_subnet_count" {
  description = "The number of subnets to create in the virtual network."
  type        = number
}

variable "app_version" {
  description = "The application version for deployment"
  type        = string
}

# Added for pipeline test
variable "pipeline_test_flag" {
  description = "Flag to test1 pipeline PR trigger."
  type        = bool
  default     = true
}
