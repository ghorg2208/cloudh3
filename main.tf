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
  name     = "eval-stan-victor"
  location = "West Europe"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "evalVirtualNetwork" {
  name                = "eval-virtual-network"
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

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "evalNetworkNetwork" {
  name                = "eval-terraform-network"
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
  name                = "eval-terraform-ssh"
  resource_group_name = azurerm_resource_group.evalRessourceGroup.name
  location            = azurerm_resource_group.evalRessourceGroup.location
  public_key          = file("ssh/ssh_eval.pub")
}

resource "azurerm_linux_virtual_machine" "evalVM" {
  name                = "eval-vm"
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

resource "azurerm_storage_account" "evalStorageAccount" {
  name                     = "evalstorageaccount"
  resource_group_name      = azurerm_resource_group.evalRessourceGroup.name
  location                 = azurerm_resource_group.evalRessourceGroup.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_mssql_server" "stanTerraformMssql" {
  name                         = "eval-mssql"
  resource_group_name          = azurerm_resource_group.evalRessourceGroup.name
  location                     = azurerm_resource_group.evalRessourceGroup.location
  version                      = "12.0"
  administrator_login          = "eval"
  administrator_login_password = "jdqghkj&y287989zdj"
}

resource "azurerm_mssql_database" "stanTerraformDB" {
  name           = "evaldb"
  server_id      = azurerm_mssql_server.stanTerraformMssql.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 10
  read_scale     = false
  sku_name       = "S0"
  zone_redundant = false

  tags = {
    foo = "bar"
  }

  # prevent the possibility of accidental data loss
  lifecycle {
    prevent_destroy = true
  }
}