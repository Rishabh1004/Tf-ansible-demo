resource "azurerm_resource_group" "rg" {
    location = var.resource_group_location
    name = var.resource_group_name
}

resource "azurerm_virtual_network" "my_tf_network" {
    name = "MyVnet"
    address_space = [ "10.0.0.0/16" ]
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "my_tf_subnet" {
    name = "MySubnet"
    resource_group_name = azurerm_resource_group.rg.name
    address_prefixes = [ "10.0.1.0/24" ]
    virtual_network_name = azurerm_virtual_network.my_tf_network.name
}

resource "azurerm_public_ip" "my_tf_public_ip" {
    name = "MyPublicIP"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    allocation_method = "Static"
  
}

resource "azurerm_network_security_group" "my_tf_nsg" {
    name = "MyNetworkSecurityGroup"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    security_rule {
        name = "SSH"
        priority = 150
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name = "HTTP"
        priority = 160
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "80"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name = "HTTPS"
        priority = 170
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "443"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name = "Testing"
        priority = 100
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "8888"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }

}

resource "azurerm_network_interface" "my_tf_nic" {
    name = "MyNIC"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
      name = "My_NIC_Configuration"
      subnet_id = azurerm_subnet.my_tf_subnet.id
      private_ip_address_allocation = "Static"
      private_ip_address = var.private_ip_address
      public_ip_address_id = azurerm_public_ip.my_tf_public_ip.id
    }
}

resource "azurerm_network_interface_security_group_association" "nisga" {
    network_interface_id = azurerm_network_interface.my_tf_nic.id
    network_security_group_id = azurerm_network_security_group.my_tf_nsg.id 
}

resource "random_id" "random_id" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.rg.name
    }
    byte_length = 8
}

resource "azurerm_storage_account" "my_tf_storage_account" {
    name = "rutwik${random_id.random_id.hex}"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    account_tier = "Standard"
    account_replication_type = "LRS"
}

# data "azurerm_client_config" "current" {}

# resource "azurerm_key_vault" "existing_key_vault" {
#     name = "keyvaulrutwiktf"
#     location = var.resource_group_location
#     resource_group_name = var.resource_group_name
#     enabled_for_deployment = true
#     tenant_id = var.tenant_id
#     sku_name = "standard"

#     access_policy {
#     tenant_id = data.azurerm_client_config.current.tenant_id
#     object_id = data.azurerm_client_config.current.object_id

#     key_permissions = [
#       "Get",
#     ]

#     secret_permissions = [
#       "Get",
#     ]

#     storage_permissions = [
#       "Get",
#     ]
#   }
# }

# resource "azurerm_key_vault_secret" "ssh_private_key_secret" {
#     name = "ssh-private-key"
#     value = tls_private_key.ssh_key.private_key_pem
#     key_vault_id = azurerm_key_vault.existing_key_vault.id
  
# }

resource "azurerm_linux_virtual_machine" "my_tf_VM" {
    name                  = "MyVM"
    resource_group_name   = azurerm_resource_group.rg.name
    location              = azurerm_resource_group.rg.location
    network_interface_ids = [azurerm_network_interface.my_tf_nic.id]
    size = var.size

    os_disk {
      name = "MyOSDisk"
      caching = "ReadWrite"
      storage_account_type = "Premium_LRS"
    }

    source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
    }

    computer_name = "hostname"
    admin_username = var.username

    admin_ssh_key {
      username = var.username
      public_key = tls_private_key.ssh_key.public_key_openssh
    }

    boot_diagnostics {
      storage_account_uri = azurerm_storage_account.my_tf_storage_account.primary_blob_endpoint
    }

    provisioner "remote-exec" {
        inline = [
            "sudo chmod 777 /etc/ansible",
            "echo '${tls_private_key.ssh_key.private_key_pem}' > /etc/ansible/terraform-ssh-key.pem",
            "sudo chmod 600 /etc/ansible/terraform-ssh-key.pem",
            "sudo chmod 777 /etc/ansible/hosts",
            "sudo sh -c 'echo \"[tf-server]\" > /etc/ansible/hosts'",
            "sudo sh -c 'echo ${azurerm_linux_virtual_machine.my_tf_VM.public_ip_address} >> /etc/ansible/hosts'"
        ]
        connection {
            type        = "ssh"
            user        = var.username
            password    = var.ansible_password
            host        = var.ansible_host
        }
    }

    provisioner "local-exec" {
        command = "echo 'Task completed successfully'"
    }

    provisioner "remote-exec" {
        when = destroy
        on_failure = continue
        inline = [
            // Commands to remove the VM's public IP address from Ansible hosts during destruction
            "sudo sed -i '/${self.public_ip_address}/d' /etc/ansible/hosts",
            "sudo sed -i '/\\[tf-server\\]/d' /etc/ansible/hosts",
            "sudo rm /etc/ansible/terraform-ssh-key.pem"
        ]
        
        connection {
            type     = "ssh"
            user     = "azureuser"
            password = "Rutwik@12345"
            host     = "20.198.9.34"
        }
    }
}

