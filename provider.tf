terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~>2.1"
    }
  }
  required_version = ">=1.1.0"
}

provider "azurerm" {
  features {}
  # Replace with your subscription if needed.
  subscription_id = "74cb74a6-bbfa-4178-8359-6fb0dd84d8c5"
}
