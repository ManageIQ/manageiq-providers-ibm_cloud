data "ibm_pi_network" "power_network" {
    pi_network_name      = "${var.power_network_name}"
    pi_cloud_instance_id = "${var.power_instance_id}"
}

data "ibm_pi_network" "public_network" {
    pi_network_name      = "${var.public_network_name}"
    pi_cloud_instance_id = "${var.power_instance_id}"
}

data "ibm_pi_image" "power_images" {
    pi_image_name        = "${var.image_name}"
    pi_cloud_instance_id = "${var.power_instance_id}"
}

resource "ibm_pi_volume" "power_volume" {
    pi_volume_size       = 20
    pi_volume_name       = "${var.volume_name}"
    pi_volume_type       = "tier3"
    pi_volume_shareable  = true
    pi_cloud_instance_id = "${var.power_instance_id}"
}

resource "ibm_pi_instance" "pvminstance" {
    depends_on = [ibm_pi_volume.power_volume]
    pi_memory             = "${var.memory}"
    pi_processors         = "${var.processors}"
    pi_instance_name      = "${var.vm_name}"
    pi_proc_type          = "${var.proc_type}"
    pi_sys_type           = "${var.sys_type}"
    pi_cloud_instance_id  = "${var.power_instance_id}"
    pi_image_id           = "${data.ibm_pi_image.power_images.id}"
    pi_pin_policy         = "${var.pin_policy}"
    pi_key_pair_name      = "${var.key_pair_name}"
    pi_storage_type       = "tier3"
    pi_volume_ids         = ibm_pi_volume.power_volume.*.volume_id
    pi_health_status      = "WARNING"
    pi_network {
        network_id        = "${data.ibm_pi_network.power_network.id}"
   }
    pi_network {
        network_id        = "${data.ibm_pi_network.public_network.id}"
   }
}
