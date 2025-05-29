provider "azurerm" {
  features {}
}

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }
  }

  backend "azurerm" {
    resource_group_name   = "bharath-terraform-dontdelete"
    storage_account_name  = "stoterraformstatefile"
    container_name        = "terraformstatefile"
    key                   = "terraform.tfstate"
  }
}
