terraform {
  required_providers {
    ibm = {
      source = "ibm-cloud/ibm"
      version = "1.38.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 2.3"
    }
  }
}
