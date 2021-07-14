
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "tftest_rg" {
  name     = "tftest-resources"
  location = "East US"
}
resource "azurerm_virtual_network" "tftest_rg" {
  name                = "tftest-net"
  resource_group_name = azurerm_resource_group.tftest_rg.name
  location            = azurerm_resource_group.tftest_rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "tftest_rg" {
  name                 = "tftest-net-int"
  resource_group_name  = azurerm_resource_group.tftest_rg.name
  virtual_network_name = azurerm_virtual_network.tftest_rg.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "tftest_rg" {
  name                = "tftest-nic"
  location            = azurerm_resource_group.tftest_rg.location
  resource_group_name = azurerm_resource_group.tftest_rg.name

  ip_configuration {
    name                          = "tftest-nic"
    subnet_id                     = azurerm_subnet.tftest_rg.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "tftest_rg" {
  name                = "tftest-vm"
  resource_group_name = azurerm_resource_group.tftest_rg.name
  location            = azurerm_resource_group.tftest_rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.tftest_rg.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
