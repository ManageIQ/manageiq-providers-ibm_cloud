variable "ibmcloud_api_key" {
    description = "Denotes the IBM Cloud API key to use"
    type = string
}

variable "ibmcloud_region" {
    description = "Denotes which IBM Cloud region to connect to"
    type = string
}

variable "power_instance_id" {
    description = "Power Virtual Server instance ID associated with your IBM Cloud account (note that this is NOT the API key)"
    type = string
}

variable "vm_name" {
    description = "VM name to take a snapshot for"
    type = string
}