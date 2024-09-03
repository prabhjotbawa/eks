data "aws_iam_policy_document" "aws_lbc" { # We can also use data resource to define policies
   statement {
     effect = "Allow"

     principals {
       type        = "Service"
       identifiers = ["pods.eks.amazonaws.com"]
     }

     actions = [
       "sts:AssumeRole",
       "sts:TagSession"
     ]
   }
 }

 resource "aws_iam_role" "aws_lbc" { # Cluster load balancer is an additional service so we need a role to assume and work on our behalf
   name               = "${aws_eks_cluster.eks.name}-aws-lbc"
   assume_role_policy = data.aws_iam_policy_document.aws_lbc.json
 }

# Can be found at: https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
 resource "aws_iam_policy" "aws_lbc" {
   policy = file("./iam/AWSLoadBalancerController.json")
   name   = "AWSLoadBalancerController"
 }

 resource "aws_iam_role_policy_attachment" "aws_lbc" {
   policy_arn = aws_iam_policy.aws_lbc.arn
   role       = aws_iam_role.aws_lbc.name
 }

 resource "aws_eks_pod_identity_association" "aws_lbc" { # K8s side changes to associate lb to an account
   cluster_name    = aws_eks_cluster.eks.name
   namespace       = "kube-system"
   service_account = "aws-load-balancer-controller"
   role_arn        = aws_iam_role.aws_lbc.arn
 }

 resource "helm_release" "aws_lbc" { # install lb from helm chart
   name = "aws-load-balancer-controller"

   repository = "https://aws.github.io/eks-charts"
   chart      = "aws-load-balancer-controller"
   namespace  = "kube-system"
   version    = "1.8.2"

   set {
     name  = "clusterName"
     value = aws_eks_cluster.eks.name
   }

   set {
     name  = "serviceAccount.name"
     value = "aws-load-balancer-controller"
   }

   depends_on = [helm_release.cluster_autoscaler]
 }

module "eks_pod_identity_checker_lbc"{
  count = local.pod_identity ? 1:0

  source = "./modules/eks-pod-identity-check"
  cluster_name = aws_eks_cluster.eks.name
}