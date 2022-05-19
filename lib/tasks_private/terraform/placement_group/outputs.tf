output "status" {
    value = "${ibm_pi_instance.pvminstance.status}"
}

#output "ip_address" {
#    value = "${ibm_pi_instance.pvminstance.addresses}"
#}

output "progress" {
    value = "${ibm_pi_instance.pvminstance.pi_progress}"
}
