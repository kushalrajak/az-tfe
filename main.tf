terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.6.0"
    }
  }
}

provider "azurerm" {
  features {

  }
  subscription_id                 = "a2b28c85-1948-4263-90ca-bade2bac4df4"
  tenant_id                       = "30fe8ff1-adc6-444d-ba94-1238894df42c"
  client_id                       = "394ba235-a73b-45e7-87d6-fd1481bc73e6"
  client_secret                   = "65w8Q~AWLid4532QbBldDuje5_.iMFvf1JVLUaVB"
  resource_provider_registrations = "none"
}

variable "rg-name" {
  type    = string
  default = "kml_rg_main-397925e0759649f7"
}
