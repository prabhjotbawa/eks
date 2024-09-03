resource "aws_eks_addon" "pod_identity" { # To grant access to the autoscaler to be able to scale the nodes, gets installed on all the nodes
   cluster_name  = aws_eks_cluster.eks.name
   addon_name    = "eks-pod-identity-agent"
   addon_version = "v1.2.0-eksbuild.1"
 }