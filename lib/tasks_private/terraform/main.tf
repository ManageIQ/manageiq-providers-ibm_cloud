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

data "ibm_pi_catalog_images" "catalog_images" {
  pi_cloud_instance_id = var.power_instance_id
}

locals {
  catalog_bastion_image = [for x in data.ibm_pi_catalog_images.catalog_images.images : x if x.name == var.image_name]
  bastion_image_id      = local.catalog_bastion_image[0].image_id
  storage_pool          = local.catalog_bastion_image[0].storage_pool
}


resource "ibm_pi_volume" "power_volume" {
    pi_volume_size       = 20
    pi_volume_name       = "${var.volume_name}"
    pi_volume_type       = "tier3"
    pi_volume_shareable  = true
    pi_cloud_instance_id = "${var.power_instance_id}"
    pi_volume_pool       = local.storage_pool
}

#resource "ibm_is_instance_volume_attachment" "power_attachment" {
#    depends_on = [ibm_pi_instance.pvminstance]
#    instance = ibm_pi_instance.pvminstance.id
#    name = "powerattachment"
#    volume = ibm_pi_volume.power_volume.id
#    delete_volume_on_attachment_delete = true
#    delete_volume_on_instance_delete = true
#}

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
    pi_storage_pool       = local.storage_pool
    pi_volume_ids         = ibm_pi_volume.power_volume.*.volume_id
    pi_health_status      = "WARNING"
    pi_network {
        network_id        = "${data.ibm_pi_network.power_network.id}"
   }
    pi_network {
        network_id        = "${data.ibm_pi_network.public_network.id}"
   }
}
