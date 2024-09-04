data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_addon" "pod_identity_agent" {
  cluster_name = data.aws_eks_cluster.this.name
  addon_name   = "eks-pod-identity-agent"
}

# We are not going to use the below since above check if sufficient however it is a good example of how to use null_resource
# in certain cases.
# locals {
#   is_pod_identity_agent_installed = data.aws_eks_addon.pod_identity_agent.addon_name == "eks-pod-identity-agent"
# }

# A null_resource is used with a count parameter. It will only be created if the pod identity agent is not installed.
# This resource uses a local-exec provisioner to echo an error message and exit with a non-zero status,
# which will cause the Terraform apply to fail if the agent is not installed.
# resource "null_resource" "pod_identity_check" {
#   count = local.is_pod_identity_agent_installed ? 0 : 1
#
#   provisioner local-exec {
#     command = "echo 'Pod Identity Agent is not installed on the cluster ${var.cluster_name}' && exit 1"
#   }
# }