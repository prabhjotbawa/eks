output "eks_id" {
  description = "ID of the EC2 instance"
  value       = aws_eks_cluster.eks.cluster_id
}
output "eks_url" {
  description = "Connection details"
  value       = aws_eks_cluster.eks.identity
}

output "eks_zone" {
  description = "Connection details"
  value       = aws_eks_cluster.eks.arn
}