output "ssh_key_name" {
  value = var.ssh_key_name
}

output "ssh_public_key" {
  value = tls_private_key.ssh_key.public_key_openssh
}

output "ssh_private_key" {
  sensitive = true  
  value = tls_private_key.ssh_key.private_key_pem
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.my_tf_VM.public_ip_address
}
