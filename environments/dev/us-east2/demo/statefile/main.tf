module "state_bucket" {
  source = "../../../../../modules/s3-storage-tf-state"

  provision_env         = "dev"
  provision_name        = "mydemocluster"
  provision_region      = "us-east-2"

}