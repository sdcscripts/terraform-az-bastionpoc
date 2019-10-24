Azure Bastion Simple Deployment
===============================

This code will quickly (usually within 5-6 mins) build a simple deployment of Azure Bastion with a linux and windows VM for demo purposes. 

The code will deploy two resource groups, one for the bastion service and another for all other resources. This is due to Terraform not being able to natively build Azure Bastion service, so utilising a seperate resource group for this resource allows for deletion and manual dependency mapping. 

## Requirements

* terraform core 0.12.n
* tested with terraform AzureRM provider `1.35.0`
* an authenticated connection to an azure subscription (or add service principal info to the azurerm provider block)

> Deploying this module will incur cost in your subscription!


The key points and features are:

- **Easy Run**: You can simply run Terraform init, Terraform Apply without changing any of the variables and it will deploy into West Europe. Terraform Destroy will remove all resources created including the Azure Bastion resource that is created with inline ARM template. If you wish to customise the deployment you can populate the variables in the root module and the linuxvm\windowsvm modules to suit your requirements. 

- **Nearly all Terraform code**: As mentioned above, the only resource that is not supported is the Azure Bastion resource itself, this is created using an inline-ARM template. All other resources such as vNet, NSG, VMs are all built using the AzureRM Terraform provider.

- **Network Security Group Rules**: This template attaches NSGs to the AzureBastionSubnet and the Target VM workload subnet. If you are using NSGs with Azure Bastion there are a number of mandatory NSG rules that must be present on the "AzureBastionSubnet" subnet to support the Azure Bastion service, these are all automatically created. There is also a requirement for the "AzureBastionSubnet" to have unrestricted access on 22 and 3389 to the VirtualNetwork it is deployed in.

- **Mitigation for subnet association bug**: There is an open bug https://github.com/terraform-providers/terraform-provider-azurerm/issues/2489 which is due to be resolved in AzureRM provider 2.0. To mitigate around this I have had to add Depends_on tags on the subnet associations and also for the NIC creation of the VMs. Additionally, at the moment you will see "[DEPRECATED] Use the `azurerm_subnet_network_security_group_association` resource instead" warnings during Terraform apply and these are expected, currently you need to use both an entry in the subnet resource block and a seperate azurerm_subnet_network_security_group_association resource for NSG-->Subnet association. This requirement will be removed in Azure provider v2.0 when subnet association is done differently. You can ignore these warnings.


Terraform Getting Started & Documentation
-----------------------------------------

If you're new to Terraform and want to get started creating infrastructure, please checkout our [Getting Started](https://www.terraform.io/intro/getting-started/install.html) guide, available on the [Terraform website](http://www.terraform.io).

All documentation is available on the [Terraform website](http://www.terraform.io):

  - [Intro](https://www.terraform.io/intro/index.html)
  - [Docs](https://www.terraform.io/docs/index.html)