variable "rgname" {
  description = "Resource Group to deploy VM into"
}
variable "location" {
  description = "Resource Group location to deploy to"
}
variable "vmname" {
  description = "Name of the VM"
}
variable "vmsize" {
  description = "size of VM"
  default     = "Standard_DS2_v2"
}
variable "vmpassword" {
  description = "Password for the VM"
  default     = "s3cure$secr3t!!"
}
variable "vmusername" {
  description = "Username for the VM"
  default     = "secureadmin"
}
variable "nicID" {
  description = "ID of nic to attach to VM"
}