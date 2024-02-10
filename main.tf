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
  default     = "Canada Central"
}

variable "admin_username" {
  description = "VM Admin username"
  type        = string
  default     = "joesanthosh"
}

resource "azurerm_resource_group" "cst8918lab5" {
  name     = "${var.labelPrefix}-A05-RG"
  location = var.region
}

resource "azurerm_public_ip" "publicipjoe" {
  name                = "${var.labelPrefix}-A05-PublicIP"
  location            = azurerm_resource_group.cst8918lab5.location
  resource_group_name = azurerm_resource_group.cst8918lab5.name
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network" "vnetjoe" {
  name                = "${var.labelPrefix}-A05-VirtualNetwork"
  location            = azurerm_resource_group.cst8918lab5.location
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.cst8918lab5.name
}

resource "azurerm_subnet" "subnetjoe" {
  name                 = "${var.labelPrefix}-A05-Subnet"
  resource_group_name  = azurerm_resource_group.cst8918lab5.name
  virtual_network_name = azurerm_virtual_network.vnetjoe.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "securitygrpjoe" {
  name                = "${var.labelPrefix}-A05-SecurityGroup"
  resource_group_name = azurerm_resource_group.cst8918lab5.name
  location            = azurerm_resource_group.cst8918lab5.location

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "vmnic" {
  name                = "${var.labelPrefix}-A05-NIC"
  location            = azurerm_resource_group.cst8918lab5.location
  resource_group_name = azurerm_resource_group.cst8918lab5.name

  ip_configuration {
    name                          = "${var.labelPrefix}-A05-NICconfig"
    subnet_id                     = azurerm_subnet.subnetjoe.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicipjoe.id
  }
}

resource "azurerm_network_interface_security_group_association" "nisgassociation" {
  network_interface_id      = azurerm_network_interface.vmnic.id
  network_security_group_id = azurerm_network_security_group.securitygrpjoe.id
}

data "cloudinit_config" "init" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/init.sh")
  }
}

resource "azurerm_linux_virtual_machine" "myvmjoe" {
  name                            = "${var.labelPrefix}-A05-VM"
  resource_group_name             = azurerm_resource_group.cst8918lab5.name
  location                        = azurerm_resource_group.cst8918lab5.location
  size                            = "Standard_B1s"
  admin_username                  = var.admin_username
  network_interface_ids           = [azurerm_network_interface.vmnic.id]
  disable_password_authentication = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  custom_data = base64encode(data.cloudinit_config.init.rendered)
}

output "resource_group_name" {
  value = azurerm_resource_group.cst8918lab5.name
}

output "public_ip" {
  value = azurerm_linux_virtual_machine.myvmjoe.public_ip_address
}
