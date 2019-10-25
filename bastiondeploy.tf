resource "azurerm_resource_group" "BastionRG" {
  name     = "${var.bastionrgname}"
  location = "${var.rglocation}"
  // # cycling issue when creating nic+subnet assoc's (- https://github.com/terraform-providers/terraform-provider-azurerm/issues/2489)
  // so during creation allow subnet associations to finish before starting bastion template deployment (which has a nic). 
  // also bastionpublicIP dependency so during destroy bastion is destroyed before public IP destroy (as bastion resource not supported natively in terraform need to add explicit dependency).  
  depends_on = ["azurerm_subnet_network_security_group_association.NSGassoc2","azurerm_public_ip.bastionpublicIP"]
}
resource "azurerm_template_deployment" "ARMDeployBastion" {
  name                = "ARMDeployBastion"
  resource_group_name = "${azurerm_resource_group.BastionRG.name}"

  template_body = <<DEPLOY
{
  "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "location": {
            "type": "String"
        },
        "resourceGroup": {
            "type": "String"
        },
        "bastionHostName": {
            "type": "String"
        },
        "subnetId": {
            "type": "String"
        },
        "publicIpAddressId": {
            "type": "String"
        }
    },
    "resources": [
        {
            "type": "Microsoft.Network/bastionHosts",
            "apiVersion": "2018-10-01",
            "name": "[parameters('bastionHostName')]",
            "location": "[parameters('location')]",
            "dependsOn": [],
            "tags": {},
            "properties": {
                "ipConfigurations": [
                    {
                        "name": "IpConf",
                        "properties": {
                            "subnet": {
                                "id": "[parameters('subnetId')]"
                            },
                            "publicIPAddress": {
                                "id": "[parameters('publicIpAddressId')]"
                            }
                        }
                    }
                ]
            }
        }
    ]
}
DEPLOY

  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters = {
    "location"          = "${azurerm_resource_group.BastionRG.location}"
    "resourcegroup"     = "${azurerm_resource_group.BastionRG.name}"
    "bastionhostname"   = "${var.bastionhostname}"
    "subnetId"          = "${azurerm_subnet.azurebastionsubnet.id}"
    "publicIpAddressId" = "${azurerm_public_ip.bastionpublicIP.id}"

  }

  deployment_mode = "Incremental"
  depends_on = ["azurerm_subnet_network_security_group_association.NSGassoc2"] // # cycling issue when creating nic+subnet assoc's -  https://github.com/terraform-providers/terraform-provider-azurerm/issues/2489 mitigation as bastionm requires nic add to subnet
}