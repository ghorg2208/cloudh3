# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "evalRessourceGroup" {
  name     = "eval-terraform-stan-victor"
  location = "West Europe"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "evalVirtualNetwork" {
  name                = "eval-terraform-virtual-network"
  resource_group_name = azurerm_resource_group.evalRessourceGroup.name
  location            = azurerm_resource_group.evalRessourceGroup.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "evalSubnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.evalRessourceGroup.name
  virtual_network_name = azurerm_virtual_network.evalVirtualNetwork.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "evalPublicIp" {
  name                = "evalIp"
  resource_group_name = azurerm_resource_group.evalRessourceGroup.name
  location            = azurerm_resource_group.evalRessourceGroup.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "evalNetworkNetwork" {
  name                = "eval-terraform-stan-victor-network"
  location            = azurerm_resource_group.evalRessourceGroup.location
  resource_group_name = azurerm_resource_group.evalRessourceGroup.name

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.evalSubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.evalPublicIp.id
  }
}

resource "azurerm_ssh_public_key" "evalSSH" {
  name                = "eval-terraform-stan-victor-ssh"
  resource_group_name = azurerm_resource_group.evalRessourceGroup.name
  location            = azurerm_resource_group.evalRessourceGroup.location
  public_key          = file("ssh/ssh_eval.pub")
}

resource "azurerm_linux_virtual_machine" "evalVM" {
  name                = "eval-stan-victor-vm"
  resource_group_name = azurerm_resource_group.evalRessourceGroup.name
  location            = azurerm_resource_group.evalRessourceGroup.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.evalNetworkNetwork.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = azurerm_ssh_public_key.evalSSH.public_key
  }

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
}

resource "azurerm_mysql_flexible_server" "stanTerraformMysql" {
  name                   = "eval-mysql-flexible-server"
  resource_group_name    = azurerm_resource_group.evalRessourceGroup.name
  location               = azurerm_resource_group.evalRessourceGroup.location
  administrator_login    = "stanvictor"
  administrator_password = "Azerty1234"
  sku_name               = "B_Standard_B1s"
}

resource "azurerm_mysql_flexible_database" "evalDB" {
  name                = "crud"
  resource_group_name = azurerm_resource_group.evalRessourceGroup.name
  server_name         = azurerm_mysql_flexible_server.stanTerraformMysql.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}