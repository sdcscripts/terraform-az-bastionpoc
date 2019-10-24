# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    byte_length = 8
}
resource "random_id" "randomIdVM" {
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${var.rgname}"
    location                    = "${var.location}"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                             = "${var.vmname}"
    location                         = "${var.location}"
    resource_group_name              = "${var.rgname}"
    network_interface_ids            = ["${var.nicID}"]
    vm_size                          = "${var.vmsize}"
    delete_os_disk_on_termination    = true
    delete_data_disks_on_termination = true

    storage_os_disk {
        name              = "${var.vmname}-myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "RedHat"
        offer     = "RHEL"
        sku       = "7.5"
        version   = "latest"
    }

    os_profile {
        computer_name  = "${var.vmname}"
        admin_username = "${var.vmusername}"
        admin_password = "${var.vmpassword}"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags = {
        environment = "Terraform Demo"
    }
}