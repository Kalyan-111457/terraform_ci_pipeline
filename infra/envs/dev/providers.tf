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
  subscription_id = "93590cca-bced-4380-8577-63234a070e93"
  client_id       = "84c9238d-90b4-43a2-abe9-55d13bc29a31"
  tenant_id       = "c1cc912e-a245-46cc-a8cd-406ddf930a19"
}
