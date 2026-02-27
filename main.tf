# 1. Generate SSH key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. Create Resource Group
resource "azurerm_resource_group" "rg_demo" {
  name     = "rg-mod-lab-vm"
  location = "eastus"
}

# 3. Create VNet, Subnet, Public IP, NSG, NIC
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-mod-lab"
  location            = azurerm_resource_group.rg_demo.location
  resource_group_name = azurerm_resource_group.rg_demo.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-mod-lab"
  resource_group_name  = azurerm_resource_group.rg_demo.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-mod-lab"
  location            = azurerm_resource_group.rg_demo.location
  resource_group_name = azurerm_resource_group.rg_demo.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-mod-lab"
  location            = azurerm_resource_group.rg_demo.location
  resource_group_name = azurerm_resource_group.rg_demo.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-mod-lab"
  location            = azurerm_resource_group.rg_demo.location
  resource_group_name = azurerm_resource_group.rg_demo.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# 4. Call the module to deploy the Linux VM
module "linux_vm" {
  source               = "./modules/linux_vm"
  vm_name              = "vm-lab-module"
  location             = azurerm_resource_group.rg_demo.location
  rg_name              = azurerm_resource_group.rg_demo.name
  vm_size              = "Standard_B1s"
  admin_username       = "azureuser"
  admin_ssh_public_key = tls_private_key.ssh.public_key_openssh
  nic_id               = azurerm_network_interface.nic.id
}

# 5. Output the SSH private key from TLS
output "ssh_private_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}

# 6. Output the public IP address
output "public_ip" {
  value = azurerm_public_ip.pip.ip_address
}

# 7. Write the private key to a local file with 0600 permissions
resource "local_file" "ssh_private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/ssh_private_key.pem"
  file_permission = "0600"
}
