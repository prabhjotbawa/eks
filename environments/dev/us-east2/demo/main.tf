module "eks_cluster" {
  source = "../../../../modules/cluster"

  env         = "dev"
  region      = "us-east-2"
  zone1       = "us-east-2a"
  zone2       = "us-east-2b"
  eks_name    = "mydemocluster"
  eks_version = "1.29"
  pod_id_chk  = false
  enable_storage = false
}