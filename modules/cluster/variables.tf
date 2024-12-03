variable env {
    type = string
    description = "Purpose of the cluster"
    default = "test"
}

variable region {
  type = string
  description = "AWS region of the cluster"
  default = "us-east-2"
}

variable zone1 {
    type = string
    description = "Primary zone of the cluster"
    default = "us-east-2a"
}

variable zone2 {
    type = string
    description = "Secondary zone of the cluster"
    default = "us-east-2b"
}

variable eks_name {
    type = string
    description = "Name of the eks cluster"
    default = "mydemocluster"
}

variable eks_version {
    type = string
    description = "Version of the eks cluster"
    default = "1.29"
}

variable enable_storage {
    type = bool
    description = "Use custom storage"
    default = false
}

variable pod_id_chk {
    type = bool
    description = "Check if pod agent is installed."
    default = false
}
