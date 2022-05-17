variable "ibmcloud_api_key" {
    description = "Denotes the IBM Cloud API key to use"
    type = string
}

variable "ibmcloud_region" {
    description = "Denotes which IBM Cloud region to connect to"
    default     = "syd"
}

variable "vm_name" {
    description = "Name of the VM"
    type = string
}

variable "power_instance_id" {
    description = "Power Virtual Server instance ID associated with your IBM Cloud account (note that this is NOT the API key)"
    default =  "888f9bf2-ab12-48c4-9dc5-8da65de951a8"
}

variable "memory" {
    description = "Amount of memory (GB) to be allocated to the VM"
    default     = "4"
}

variable "processors" {
    description = "Number of virtual processors to allocate to the VM"
    default     = "1"
}

variable "proc_type" {
    description = "Processor type for the LPAR - shared/dedicated"
    default     = "shared"
}

variable "pin_policy" {
    description = "Supported values are soft, hard, and none"
    default     = "none"
}

variable "key_pair_name" {
    description = "SSH key name in IBM Cloud to be used for SSH logins"
    default = "miq-pvs"
}

variable "shareable" {
    description = "Should the data volume be shared or not - true/false"
    default     = "true"
}

variable "power_network_name" {
    description = "networks that should be attached to the VM"
    default     = "ocp-net"
}

variable "public_network_name" {
    description = "networks that should be attached to the VM"
    default     = "cm-test-syd-526e-syd04-pub-net"
}

variable "sys_type" {
    description = "Type of system on which the VM should be created - s922/e880"
    default     = "s922"
}

variable "image_name" {
    description = "Name of the image from which the VM should be deployed"
    default    = "rhel-84-07122021"
}

variable "volume_name" {
    description = "Name of the storage volume"
    type = string
}

variable "placement_group_name" {
    description = "placement group name"
    default = "miq-placement-group"
    type = string
}

variable "placement_group_policy" {
    description = "placement group policy"
    default = "affinity"
    type = string
}
