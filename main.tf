terraform {
  required_version = "~> 0.12.0"
}

provider "azurerm" {
  version = "~> 1.35.0"
}

resource "azurerm_resource_group" "MyRG" {
   name     = "${var.rgname}"
   location = "${var.rglocation}"
}
  module "linuxvm" {
  source   = "./modules/linuxvm"
  rgname   = "${azurerm_resource_group.MyRG.name}"
  location = "${azurerm_resource_group.MyRG.location}"
  nicID    = "${azurerm_network_interface.myterraformniclinux.id}"
  vmname   = "${var.linuxvmname}"
 } 

 module "windowsvm" {
  source   = "./modules/windowsvm"
  rgname   = "${azurerm_resource_group.MyRG.name}"
  location = "${azurerm_resource_group.MyRG.location}"
  nicID    = "${azurerm_network_interface.myterraformnicwindows.id}"
  vmname   = "${var.windowsvmname}"
 } 