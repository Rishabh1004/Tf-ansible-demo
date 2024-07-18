variable "subscription_id" {
    description = "Azure Subscription ID"
}

variable "client_id" {
    description = "Service principal ID"
}

variable "client_secret" {
    description = "Service Principal secret"
}

variable "tenant_id" {
    description = "Azure Service principal tenant_id"
}

variable "resource_group_location" {
    type = string
    description = "Location of resource group"
}

variable "resource_group_name" {
    type = string
    description = "default resource group name"
}

variable "username" {
    type = string
    description = "username for virtual machine"
}

variable "private_ip_address" {
    description = "private_ip_address"
}

variable "size" {
    description = "size of vm"
}

variable "ssh_key_name" {
    description = "ssh_key_name"
}

variable "ansible_password" {
    description = "ansible password"
  
}

variable "ansible_host" {
    description = "ansible host  ip"
}
