output "status" {
    value = "${ibm_pi_instance.pvminstance.status}"
}

output "progress" {
    value = "${ibm_pi_instance.pvminstance.pi_progress}"
}
