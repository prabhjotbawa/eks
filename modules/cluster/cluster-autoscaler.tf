resource "aws_iam_role" "cluster_autoscaler" {
   name = "${aws_eks_cluster.eks.name}-cluster-autoscaler"

   assume_role_policy = jsonencode({
     Version = "2012-10-17"
     Statement = [
       {
         Effect = "Allow"
         Action = [
           "sts:AssumeRole",
           "sts:TagSession"
         ]
         Principal = {
           Service = "pods.eks.amazonaws.com" # To associate with the pod identity service for scaling
         }
       }
     ]
   })
 }

 resource "aws_iam_policy" "cluster_autoscaler" {
   name = "${aws_eks_cluster.eks.name}-cluster-autoscaler"

   policy = jsonencode({
     Version = "2012-10-17"
     Statement = [
       {
         Effect = "Allow"
         Action = [
           "autoscaling:DescribeAutoScalingGroups",
           "autoscaling:DescribeAutoScalingInstances",
           "autoscaling:DescribeLaunchConfigurations",
           "autoscaling:DescribeScalingActivities",
           "autoscaling:DescribeTags",
           "ec2:DescribeImages",
           "ec2:DescribeInstanceTypes",
           "ec2:DescribeLaunchTemplateVersions",
           "ec2:GetInstanceTypesFromInstanceRequirements",
           "eks:DescribeNodegroup"
         ]
         Resource = "*"
       },
       {
         Effect = "Allow"
         Action = [
           "autoscaling:SetDesiredCapacity",
           "autoscaling:TerminateInstanceInAutoScalingGroup"
         ]
         Resource = "*"
       },
     ]
   })
 }

 resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
   policy_arn = aws_iam_policy.cluster_autoscaler.arn
   role       = aws_iam_role.cluster_autoscaler.name
 }

 resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
   cluster_name    = aws_eks_cluster.eks.name
   namespace       = "kube-system"
   service_account = "cluster-autoscaler"
   role_arn        = aws_iam_role.cluster_autoscaler.arn

   lifecycle {
     postcondition {
       condition = self.association_id != "" # aws_eks_pod_identity_association.cluster_autoscaler.association_id
       error_message = "A pod association id ${self.association_id} is needed to proceed, Check if pod identiy agent was installed"
     }
   }
 }

 resource "helm_release" "cluster_autoscaler" {
   name = "autoscaler"

   repository = "https://kubernetes.github.io/autoscaler"
   chart      = "cluster-autoscaler"
   namespace  = "kube-system"
   version    = "9.37.0"

   set {
     name  = "rbac.serviceAccount.name"
     value = "cluster-autoscaler"
   }

   set {
     name  = "autoDiscovery.clusterName"
     value = aws_eks_cluster.eks.name
   }

   # MUST be updated to match your region
   set {
     name  = "awsRegion"
     value = var.region
   }

   depends_on = [helm_release.metrics_server]
 }

module "eks_pod_identity_checker_scaler"{
  count = var.pod_id_chk ? 1:0

  source = "../eks-pod-identity-check"
  cluster_name = aws_eks_cluster.eks.name
}