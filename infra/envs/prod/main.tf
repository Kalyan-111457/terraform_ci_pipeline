module "resource_group" {
  source                  = "../../modules/common"
  resource_group_name     = var.resource_group_name
  resource_group_location = var.resource_group_location
}

module "virtual_network" {
  source              = "../../modules/vnet"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  vnet_name           = var.vnet_name
  address_space       = var.address_space
  vnet_subnet_count   = var.vnet_subnet_count
}
