provider "ibm" {
    ibmcloud_api_key = "${var.ibmcloud_api_key}"
    region           = "${var.ibmcloud_region}"
}

resource "ibm_pi_snapshot" "snapshot" {
    pi_instance_name     = var.vm_name
    pi_snap_shot_name    = "test-snapshot-1"
    pi_cloud_instance_id = "${var.power_instance_id}"
}
