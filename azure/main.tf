terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "el_rg" {
  name     = "EL-RG"
  location = var.az_location
}

data "azurerm_subscription" "current" {
}