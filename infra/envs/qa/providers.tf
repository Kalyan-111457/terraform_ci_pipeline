terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.69.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "9202fdd4-3473-44bd-bf2c-bea84beb99d9"
  client_id       = "b7998bce-a467-4e17-9150-87c9d08c82da"
  client_secret   = "gto8Q~WXgOf~iYiAjUG30ZDaA2jvdIRbudu1IbiV"
  tenant_id       = "2ed7f2e6-e8a9-4bc5-8cd6-cea790964ecc"
}
