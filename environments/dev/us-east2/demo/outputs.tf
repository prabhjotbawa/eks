output "eks_id" {
  description = "ID of the EC2 instance"
  value       = module.eks_cluster.eks_id
}
output "eks_url" {
  description = "Connection details"
  value       = module.eks_cluster.eks_url
}

output "eks_zone" {
  description = "Connection details"
  value       = module.eks_cluster.eks_zone
}
