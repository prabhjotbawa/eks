variable provision_env {
    type = string
    description = "Purpose of the cluster"
    default = "test"
}

variable provision_name {
  type = string
  description = "Name of the cluster"
  default = "mydemocluster"
}

variable provision_region {
  type = string
  description = "Region of the cluster"
  default = "us-east-2"
}
