# Network Interface for Web VM

resource "azurerm_network_interface" "web_nic" {

  name = "web-vm-nic"

  location = azurerm_resource_group.main.location

  resource_group_name = azurerm_resource_group.main.name


  ip_configuration {

    name = "internal"

    subnet_id = azurerm_subnet.web_subnet.id

    private_ip_address_allocation = "Dynamic"

  }

}


# Web Tier Virtual Machine

resource "azurerm_linux_virtual_machine" "web_vm" {

  name = "web-tier-vm"

  resource_group_name = azurerm_resource_group.main.name

  location = azurerm_resource_group.main.location

  size = "Standard_B1s"

  admin_username = "azureuser"


  network_interface_ids = [

    azurerm_network_interface.web_nic.id

  ]


  disable_password_authentication = true


  admin_ssh_key {

    username = "azureuser"

    public_key = "ssh-rsa YOUR_PUBLIC_KEY"

  }


  os_disk {

    caching = "ReadWrite"

    storage_account_type = "Standard_LRS"

  }


  source_image_reference {

    publisher = "Canonical"

    offer = "0001-com-ubuntu-server-jammy"

    sku = "22_04-lts"

    version = "latest"

  }

}
