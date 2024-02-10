# Configure the Terraform runtime requirements.
terraform {
  required_version = ">= 1.1.0"

  required_providers {
    # Azure Resource Manager provider and version
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.3"
    }
  }
}

# Define providers and their config params
provider "azurerm" {
  # Leave the features block empty to accept all defaults
  features {}
}

provider "cloudinit" {
  # Configuration options
}

variable "labelPrefix" {
  description = "Resource label prefix"
  type        = string
  default     = "sant0232"
}

variable "region" {
  description = "Region where resource is deployed to"
  type        = string
  default     = "canadacentral"
}

variable "admin_username" {
  description = "VM Admin username"
  type        = string
  default     = "joesanthosh"
}
