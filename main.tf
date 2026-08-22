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
  client_id                       = "913bb14e-de4e-4741-9b48-3159123f87a3"
  client_secret                   = "NBz8Q~wivUoeH2uY5oEGjqQ_mKUDbl5guJBAWdkl"
  resource_provider_registrations = "none"
}

variable "rg-name" {
  type    = string
  default = "kml_rg_main-8917760fe90c4301"
}
