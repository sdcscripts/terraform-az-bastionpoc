resource "random_id" "randomIdVM" {
    
        byte_length = 8
}
resource "azurerm_virtual_network" "DefaultvNet" {
  name                = "${var.vNetName}"
  location            = "${azurerm_resource_group.MyRG.location}"
  resource_group_name = "${azurerm_resource_group.MyRG.name}"
  address_space       = ["${var.vNetAddressSpace}"]

  tags = {
    environment = "Lab"
  }
}
resource "azurerm_public_ip" "bastionpublicIP" {
    name                = "BastionPublicIP"
    location            = "${azurerm_resource_group.MyRG.location}"
    resource_group_name = "${azurerm_resource_group.MyRG.name}"
    allocation_method   = "Static"
    sku                 = "Standard"
    tags                = {
        environment = "Terraform Demo"
    }
}
# cycling issue when creating nic+subnet assoc's -  https://github.com/terraform-providers/terraform-provider-azurerm/issues/2489
# for that reason, moved all vnet and VM nic creation to root module so I can use Depends_On tags on nic and association resources. 
resource "azurerm_subnet" "vmsubnet" {
    name                      = "vmsubnet"
    address_prefix            = "${var.vmsubnetRange}"
    virtual_network_name      = "${azurerm_virtual_network.DefaultvNet.name}"
    resource_group_name       = "${azurerm_resource_group.MyRG.name}"
    network_security_group_id = "${azurerm_network_security_group.TargetSubnetNSG.id}"
}

resource "azurerm_subnet" "azurebastionsubnet" {
    name                      = "azurebastionsubnet"
    address_prefix            = "${var.BastionSubnetRange}"
    virtual_network_name      = "${azurerm_virtual_network.DefaultvNet.name}"
    resource_group_name       = "${azurerm_resource_group.MyRG.name}"
    network_security_group_id = "${azurerm_network_security_group.bastionnsg.id}"
}

resource "azurerm_subnet_network_security_group_association" "NSGassoc1" {
  subnet_id                 = "${azurerm_subnet.vmsubnet.id}"
  network_security_group_id = "${azurerm_network_security_group.TargetSubnetNSG.id}"
} 

resource "azurerm_subnet_network_security_group_association" "NSGassoc2" {
  subnet_id                 = "${azurerm_subnet.azurebastionsubnet.id}"
  network_security_group_id = "${azurerm_network_security_group.bastionnsg.id}"
  depends_on                = ["azurerm_subnet_network_security_group_association.NSGassoc1"]
  }

resource "azurerm_network_security_group" "bastionnsg" {
  name                = "bastionnsg"
  location            = "${azurerm_resource_group.MyRG.location}"
  resource_group_name = "${azurerm_resource_group.MyRG.name}"

  security_rule {
        name                       = "GatewayManager"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "GatewayManager"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "Internet-Bastion-PublicIP"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "OutboundVirtualNetwork"
        priority                   = 1001
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["22","3389"]
        source_address_prefix      = "*"
        destination_address_prefix = "VirtualNetwork"
    }

     security_rule {
        name                       = "OutboundToAzureCloud"
        priority                   = 1002
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "AzureCloud"
    }
}
resource "azurerm_network_security_group" "TargetSubnetNSG" {
  name                = "TargetSubnetNSG"
  location            = "${azurerm_resource_group.MyRG.location}"
  resource_group_name = "${azurerm_resource_group.MyRG.name}"

  security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["22","3389"]
        source_address_prefix      = "${var.BastionSubnetRange}"
        destination_address_prefix = "*"
    }
}
resource "azurerm_network_interface" "myterraformniclinux" {
    name                      = "${var.linuxvmname}-myNIC-${random_id.randomIdVM.hex}"
    location                  = "${azurerm_resource_group.MyRG.location}"
    resource_group_name       = "${azurerm_resource_group.MyRG.name}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.vmsubnet.id}"
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
        environment = "Terraform Demo"
    }
    depends_on = ["azurerm_subnet_network_security_group_association.NSGassoc2"] // to avoid association bug
}

resource "azurerm_network_interface" "myterraformnicwindows" {
    name                      = "${var.windowsvmname}-myNIC-${random_id.randomIdVM.hex}"
    location                  = "${azurerm_resource_group.MyRG.location}"
    resource_group_name       = "${azurerm_resource_group.MyRG.name}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.vmsubnet.id}"
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
        environment = "Terraform Demo"
    }

    depends_on = ["azurerm_subnet_network_security_group_association.NSGassoc2"] // to avoid association bug
}