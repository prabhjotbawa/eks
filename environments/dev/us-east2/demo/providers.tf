terraform {
  backend "s3" {
#     bucket         = "terraform-state-${local.region}-${local.eks_name}"
#     key            = "terraform-${local.region}-${local.eks_name}.tfstate"
#     region         = "us-east-2"
    encrypt        = true
#     dynamodb_table = "terraform-state-lock-${local.region}-${local.eks_name}"
  }
}